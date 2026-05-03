PRAGMA foreign_keys = ON;

-- Views

CREATE VIEW IF NOT EXISTS v_active_students AS
SELECT
    s.StudentID, s.FirstName, s.LastName, s.Email,
    s.MatriculationNr, d.DeptName, d.DeptCode, s.MatriculationDate
FROM Students s
INNER JOIN Departments d ON s.DeptID = d.DeptID
WHERE s.Status = 'active';

CREATE VIEW IF NOT EXISTS v_course_catalog AS
SELECT
    c.CourseID, c.CourseName, c.Credits, c.CourseLevel, c.Description,
    d.DeptName, co.SemesterID,
    p.Title || ' ' || p.LastName AS Professor,
    r.RoomNumber || ' (' || r.Building || ')' AS Location,
    co.DayOfWeek,
    co.StartTime || '-' || co.EndTime AS TimeSlot,
    co.MaxStudents,
    (SELECT COUNT(*) FROM Enrollments e WHERE e.OfferingID = co.OfferingID) AS CurrentEnrollment,
    co.MaxStudents - (SELECT COUNT(*) FROM Enrollments e WHERE e.OfferingID = co.OfferingID) AS SpotsAvailable
FROM Courses c
LEFT JOIN CourseOfferings co ON c.CourseID = co.CourseID
LEFT JOIN Professors p      ON co.ProfID = p.ProfID
LEFT JOIN Rooms r           ON co.RoomID = r.RoomID
LEFT JOIN Departments d     ON c.DeptID  = d.DeptID;

CREATE VIEW IF NOT EXISTS v_student_transcript AS
SELECT
    s.StudentID,
    s.FirstName || ' ' || s.LastName AS StudentName,
    s.MatriculationNr,
    c.CourseID, c.CourseName, c.Credits,
    sem.SemesterID, sem.SemesterName,
    e.Grade,
    e.Status AS EnrollmentStatus,
    CASE
        WHEN e.Grade IS NULL        THEN 'Pending'
        WHEN e.Grade <= 1.5         THEN 'sehr gut'
        WHEN e.Grade <= 2.5         THEN 'gut'
        WHEN e.Grade <= 3.5         THEN 'befriedigend'
        WHEN e.Grade <= 4.0         THEN 'ausreichend'
        ELSE                             'nicht bestanden'
    END AS GradeLabel
FROM Enrollments e
INNER JOIN Students s        ON e.StudentID  = s.StudentID
INNER JOIN CourseOfferings co ON e.OfferingID = co.OfferingID
INNER JOIN Courses c         ON co.CourseID  = c.CourseID
INNER JOIN Semesters sem     ON co.SemesterID = sem.SemesterID;

CREATE VIEW IF NOT EXISTS v_department_stats AS
SELECT
    d.DeptID, d.DeptName, d.DeptCode,
    (SELECT COUNT(*) FROM Professors p WHERE p.DeptID = d.DeptID) AS ProfessorCount,
    (SELECT COUNT(*) FROM Students s WHERE s.DeptID = d.DeptID AND s.Status = 'active') AS ActiveStudents,
    (SELECT COUNT(*) FROM Courses c WHERE c.DeptID = d.DeptID) AS CourseCount,
    (SELECT p.Title || ' ' || p.FirstName || ' ' || p.LastName
     FROM Professors p WHERE p.ProfID = d.HeadProfID) AS DepartmentHead
FROM Departments d;


-- Audit-Log

CREATE TABLE IF NOT EXISTS AuditLog (
    LogID       INTEGER PRIMARY KEY AUTOINCREMENT,
    TableName   TEXT    NOT NULL,
    Action      TEXT    NOT NULL,
    RecordID    TEXT    NOT NULL,
    OldValues   TEXT,
    NewValues   TEXT,
    ChangedAt   TEXT    NOT NULL DEFAULT (datetime('now')),
    ChangedBy   TEXT    DEFAULT 'system'
);


-- Triggers

CREATE TRIGGER IF NOT EXISTS trg_check_enrollment_capacity
BEFORE INSERT ON Enrollments
BEGIN
    SELECT CASE
        WHEN (
            SELECT COUNT(*) FROM Enrollments
            WHERE OfferingID = NEW.OfferingID AND Status != 'withdrawn'
        ) >= (
            SELECT MaxStudents FROM CourseOfferings
            WHERE OfferingID = NEW.OfferingID
        )
        THEN RAISE(ABORT, 'ERROR: Course offering is full. Cannot enroll more students.')
    END;
END;

CREATE TRIGGER IF NOT EXISTS trg_check_prerequisites
BEFORE INSERT ON Enrollments
BEGIN
    SELECT CASE
        WHEN EXISTS (
            SELECT pr.PrereqCourseID
            FROM CourseOfferings co
            INNER JOIN Prerequisites pr ON co.CourseID = pr.CourseID
            WHERE co.OfferingID = NEW.OfferingID
              AND pr.PrereqCourseID NOT IN (
                  SELECT co2.CourseID
                  FROM Enrollments e2
                  INNER JOIN CourseOfferings co2 ON e2.OfferingID = co2.OfferingID
                  WHERE e2.StudentID = NEW.StudentID AND e2.Status = 'completed'
              )
        )
        THEN RAISE(ABORT, 'ERROR: Student has not completed all prerequisites for this course.')
    END;
END;

-- auto-set status when graded
CREATE TRIGGER IF NOT EXISTS trg_auto_status_on_grade
AFTER UPDATE OF Grade ON Enrollments
WHEN NEW.Grade IS NOT NULL AND OLD.Grade IS NULL
BEGIN
    UPDATE Enrollments
    SET Status = CASE
            WHEN NEW.Grade <= 4.0 THEN 'completed'
            ELSE 'failed'
        END,
        GradeDate = date('now')
    WHERE EnrollmentID = NEW.EnrollmentID;
END;

CREATE TRIGGER IF NOT EXISTS trg_audit_enrollment_insert
AFTER INSERT ON Enrollments
BEGIN
    INSERT INTO AuditLog (TableName, Action, RecordID, NewValues)
    VALUES (
        'Enrollments', 'INSERT',
        CAST(NEW.EnrollmentID AS TEXT),
        'StudentID=' || NEW.StudentID || ', OfferingID=' || NEW.OfferingID || ', Status=' || NEW.Status
    );
END;
