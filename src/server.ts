import { serve } from "@hono/node-server";
import { Hono } from "hono";
import { z } from "zod";
import { getDb, closeDb } from "./db/connection.js";
import { initializeDatabase, seedDatabase, createTriggersAndViews } from "./db/init.js";

const app = new Hono();
const db = getDb();

const tables = (db.prepare("SELECT COUNT(*) as c FROM sqlite_master WHERE type='table'").get() as { c: number }).c;
if (tables <= 1) {
  initializeDatabase();
  seedDatabase();
  createTriggersAndViews();
}

// --- Schemas ---

const createStudentSchema = z.object({
  firstName: z.string().min(1),
  lastName: z.string().min(1),
  email: z.string().email(),
  matriculationNr: z.string().regex(/^MN-\d{4}-\d{3}$/),
  matriculationDate: z.string().date(),
  dateOfBirth: z.string().date().optional(),
  deptCode: z.string().min(2).max(5),
  phones: z.array(z.object({
    phone: z.string().min(1),
    type: z.enum(["mobile", "home", "work"]).default("mobile"),
  })).optional(),
});

const createEnrollmentSchema = z.object({
  studentId: z.number().int().positive(),
  offeringId: z.number().int().positive(),
});

const gradeSchema = z.object({
  grade: z.number().min(1.0).max(5.0),
});

// --- Helper ---

function validate<T>(schema: z.ZodSchema<T>, data: unknown): { data: T } | { error: string } {
  const result = schema.safeParse(data);
  if (!result.success) return { error: result.error.issues.map((i) => `${i.path.join(".")}: ${i.message}`).join(", ") };
  return { data: result.data };
}

// --- Students ---

app.get("/api/students", (c) => {
  const status = c.req.query("status");
  const dept = c.req.query("dept");
  let sql = `SELECT s.*, d.DeptName, d.DeptCode FROM Students s JOIN Departments d ON s.DeptID = d.DeptID`;
  const conds: string[] = [];
  const vals: unknown[] = [];
  if (status) { conds.push("s.Status = ?"); vals.push(status); }
  if (dept) { conds.push("d.DeptCode = ?"); vals.push(dept); }
  if (conds.length) sql += " WHERE " + conds.join(" AND ");
  return c.json(db.prepare(sql + " ORDER BY s.LastName").all(...vals));
});

app.get("/api/students/:id", (c) => {
  const id = c.req.param("id");
  const student = db.prepare(`SELECT s.*, d.DeptName, d.DeptCode FROM Students s JOIN Departments d ON s.DeptID = d.DeptID WHERE s.StudentID = ?`).get(id);
  if (!student) return c.json({ error: "Student not found" }, 404);
  const phones = db.prepare("SELECT Phone, PhoneType FROM StudentPhones WHERE StudentID = ?").all(id);
  return c.json({ ...(student as object), phones });
});

app.post("/api/students", async (c) => {
  const parsed = validate(createStudentSchema, await c.req.json());
  if ("error" in parsed) return c.json({ error: parsed.error }, 400);
  const body = parsed.data;

  const dept = db.prepare("SELECT DeptID FROM Departments WHERE DeptCode = ?").get(body.deptCode) as { DeptID: number } | undefined;
  if (!dept) return c.json({ error: "Department not found" }, 400);

  try {
    const studentId = db.transaction(() => {
      const r = db.prepare(
        `INSERT INTO Students (FirstName, LastName, Email, MatriculationNr, MatriculationDate, DateOfBirth, DeptID) VALUES (?, ?, ?, ?, ?, ?, ?)`
      ).run(body.firstName, body.lastName, body.email, body.matriculationNr, body.matriculationDate, body.dateOfBirth ?? null, dept.DeptID);
      for (const p of body.phones ?? [])
        db.prepare("INSERT INTO StudentPhones (StudentID, Phone, PhoneType) VALUES (?, ?, ?)").run(r.lastInsertRowid, p.phone, p.type);
      return r.lastInsertRowid;
    })();
    return c.json(db.prepare("SELECT * FROM Students WHERE StudentID = ?").get(studentId), 201);
  } catch (err) {
    return c.json({ error: err instanceof Error ? err.message : "Insert failed" }, 400);
  }
});

app.delete("/api/students/:id", (c) => {
  const result = db.prepare("DELETE FROM Students WHERE StudentID = ?").run(c.req.param("id"));
  return result.changes ? c.json({ ok: true }) : c.json({ error: "Not found" }, 404);
});

// --- Transcript ---

app.get("/api/students/:id/transcript", (c) => {
  const id = c.req.param("id");
  const transcript = db.prepare(
    `SELECT CourseID, CourseName, Credits, SemesterName, Grade, EnrollmentStatus, GradeLabel
     FROM v_student_transcript WHERE StudentID = ? ORDER BY SemesterID, CourseID`
  ).all(id);
  const summary = db.prepare(
    `SELECT COUNT(*) AS TotalCourses,
            SUM(CASE WHEN EnrollmentStatus = 'completed' THEN Credits ELSE 0 END) AS CreditsEarned,
            ROUND(AVG(CASE WHEN Grade IS NOT NULL THEN Grade END), 2) AS GPA
     FROM v_student_transcript WHERE StudentID = ?`
  ).get(id);
  return c.json({ transcript, summary });
});

// --- Courses ---

app.get("/api/courses", (c) => {
  return c.json(db.prepare(
    `SELECT c.CourseID, c.CourseName, c.Credits, c.CourseLevel, d.DeptName
     FROM Courses c JOIN Departments d ON c.DeptID = d.DeptID ORDER BY c.CourseID`
  ).all());
});

app.get("/api/courses/:id", (c) => {
  const id = c.req.param("id");
  const course = db.prepare("SELECT c.*, d.DeptName FROM Courses c JOIN Departments d ON c.DeptID = d.DeptID WHERE c.CourseID = ?").get(id);
  if (!course) return c.json({ error: "Course not found" }, 404);

  const prereqChain = db.prepare(
    `WITH RECURSIVE Chain AS (
       SELECT pr.PrereqCourseID, 1 AS Depth FROM Prerequisites pr WHERE pr.CourseID = ?
       UNION ALL
       SELECT pr.PrereqCourseID, ch.Depth + 1 FROM Chain ch JOIN Prerequisites pr ON ch.PrereqCourseID = pr.CourseID
     )
     SELECT DISTINCT c.CourseID, c.CourseName, ch.Depth
     FROM Chain ch JOIN Courses c ON ch.PrereqCourseID = c.CourseID ORDER BY ch.Depth DESC`
  ).all(id);

  return c.json({ ...(course as object), prereqChain });
});

// --- Enrollments ---

app.post("/api/enrollments", async (c) => {
  const parsed = validate(createEnrollmentSchema, await c.req.json());
  if ("error" in parsed) return c.json({ error: parsed.error }, 400);

  try {
    const enrollment = db.transaction(() => {
      const r = db.prepare(
        "INSERT INTO Enrollments (StudentID, OfferingID, EnrollDate, Status) VALUES (?, ?, date('now'), 'enrolled')"
      ).run(parsed.data.studentId, parsed.data.offeringId);
      return db.prepare("SELECT * FROM Enrollments WHERE EnrollmentID = ?").get(r.lastInsertRowid);
    })();
    return c.json(enrollment, 201);
  } catch (err) {
    return c.json({ error: err instanceof Error ? err.message : "Enrollment failed" }, 400);
  }
});

app.put("/api/enrollments/:id/grade", async (c) => {
  const parsed = validate(gradeSchema, await c.req.json());
  if ("error" in parsed) return c.json({ error: parsed.error }, 400);

  const id = c.req.param("id");
  const result = db.prepare("UPDATE Enrollments SET Grade = ? WHERE EnrollmentID = ?").run(parsed.data.grade, id);
  if (!result.changes) return c.json({ error: "Enrollment not found" }, 404);
  return c.json(db.prepare("SELECT * FROM Enrollments WHERE EnrollmentID = ?").get(id));
});

// --- Departments ---

app.get("/api/departments", (c) => {
  return c.json(db.prepare("SELECT * FROM v_department_stats ORDER BY DeptName").all());
});

// --- Stats ---

app.get("/api/stats/overview", (c) => {
  const overview = db.prepare(
    `SELECT
       (SELECT COUNT(*) FROM Students WHERE Status = 'active') AS ActiveStudents,
       (SELECT COUNT(*) FROM Students) AS TotalStudents,
       (SELECT COUNT(*) FROM Professors) AS TotalProfessors,
       (SELECT COUNT(*) FROM Courses) AS TotalCourses,
       (SELECT COUNT(*) FROM Enrollments) AS TotalEnrollments,
       (SELECT ROUND(AVG(Grade), 2) FROM Enrollments WHERE Grade IS NOT NULL) AS AvgGrade`
  ).get();

  const topStudents = db.prepare(
    `WITH StudentGPA AS (
       SELECT s.StudentID, s.FirstName || ' ' || s.LastName AS Name, d.DeptName,
              ROUND(AVG(e.Grade), 2) AS GPA,
              RANK() OVER (ORDER BY AVG(e.Grade) ASC) AS Rank
       FROM Students s
       JOIN Enrollments e ON s.StudentID = e.StudentID
       JOIN CourseOfferings co ON e.OfferingID = co.OfferingID
       JOIN Courses c ON co.CourseID = c.CourseID
       JOIN Departments d ON s.DeptID = d.DeptID
       WHERE e.Status = 'completed' AND e.Grade IS NOT NULL
       GROUP BY s.StudentID HAVING COUNT(*) >= 2
     )
     SELECT * FROM StudentGPA WHERE Rank <= 5`
  ).all();

  return c.json({ overview, topStudents });
});

// --- Audit Log ---

app.get("/api/audit-log", (c) => {
  return c.json(db.prepare("SELECT * FROM AuditLog ORDER BY LogID DESC LIMIT ?").all(parseInt(c.req.query("limit") ?? "50")));
});

// --- Start ---

serve({ fetch: app.fetch, port: 3000 }, () => console.log("http://localhost:3000"));
process.on("SIGINT", () => { closeDb(); process.exit(0); });
