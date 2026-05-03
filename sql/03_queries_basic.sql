PRAGMA foreign_keys = ON;

-- alle aktiven Studenten
SELECT StudentID, FirstName, LastName, Email, Status
FROM Students
WHERE Status = 'active'
ORDER BY LastName, FirstName;

SELECT * FROM Students
WHERE MatriculationNr = 'MN-2023-001';

-- LIKE
SELECT FirstName, LastName, Email
FROM Professors
WHERE Email LIKE '%@uni.edu'
  AND LastName LIKE 'S%';

-- INSERT / UPDATE / DELETE
INSERT INTO Students (FirstName, LastName, Email, MatriculationNr, MatriculationDate, DateOfBirth, DeptID)
VALUES ('Karla', 'Meyer', 'karla.meyer@stud.uni.edu', 'MN-2025-001', '2025-10-01', '2005-04-20', 1);

UPDATE Students
SET Status = 'on_leave'
WHERE MatriculationNr = 'MN-2025-001';

DELETE FROM Students
WHERE MatriculationNr = 'MN-2025-001';


-- INNER JOIN
SELECT s.FirstName, s.LastName, d.DeptName, d.Faculty
FROM Students s
INNER JOIN Departments d ON s.DeptID = d.DeptID
WHERE s.Status = 'active'
ORDER BY d.DeptName, s.LastName;

-- 5-table join: course catalog
SELECT
    co.OfferingID,
    c.CourseID,
    c.CourseName,
    sem.SemesterName,
    p.Title || ' ' || p.LastName AS Professor,
    r.RoomNumber || ' (' || r.Building || ')' AS Location,
    co.DayOfWeek,
    co.StartTime || ' - ' || co.EndTime AS TimeSlot,
    r.Capacity
FROM CourseOfferings co
INNER JOIN Courses c    ON co.CourseID   = c.CourseID
INNER JOIN Semesters sem ON co.SemesterID = sem.SemesterID
INNER JOIN Professors p ON co.ProfID     = p.ProfID
INNER JOIN Rooms r      ON co.RoomID     = r.RoomID
ORDER BY sem.StartDate, co.DayOfWeek, co.StartTime;


-- LEFT JOIN: Studenten die nie eingeschrieben waren
SELECT s.StudentID, s.FirstName, s.LastName, s.Status
FROM Students s
LEFT JOIN Enrollments e ON s.StudentID = e.StudentID
WHERE e.EnrollmentID IS NULL;

SELECT c.CourseID, c.CourseName, co.SemesterID,
       CASE WHEN co.OfferingID IS NOT NULL THEN 'Yes' ELSE 'Not offered' END AS IsScheduled
FROM Courses c
LEFT JOIN CourseOfferings co ON c.CourseID = co.CourseID
ORDER BY c.CourseID, co.SemesterID;


-- Multi-Table JOIN
SELECT
    s.FirstName || ' ' || s.LastName AS Student,
    s.MatriculationNr,
    c.CourseID,
    c.CourseName,
    c.Credits,
    sem.SemesterName,
    p.Title || ' ' || p.LastName AS Professor,
    e.Grade,
    e.Status AS EnrollmentStatus
FROM Enrollments e
INNER JOIN Students s        ON e.StudentID  = s.StudentID
INNER JOIN CourseOfferings co ON e.OfferingID = co.OfferingID
INNER JOIN Courses c         ON co.CourseID  = c.CourseID
INNER JOIN Professors p      ON co.ProfID   = p.ProfID
INNER JOIN Semesters sem     ON co.SemesterID = sem.SemesterID
ORDER BY s.LastName, sem.StartDate, c.CourseID;


-- scalar subquery: grade better than average
SELECT s.FirstName, s.LastName, e.Grade
FROM Enrollments e
INNER JOIN Students s ON e.StudentID = s.StudentID
WHERE e.Grade IS NOT NULL
  AND e.Grade < (SELECT AVG(Grade) FROM Enrollments WHERE Grade IS NOT NULL)
ORDER BY e.Grade;

-- IN
SELECT DISTINCT s.FirstName, s.LastName
FROM Students s
WHERE s.StudentID IN (
    SELECT e.StudentID
    FROM Enrollments e
    INNER JOIN CourseOfferings co ON e.OfferingID = co.OfferingID
    INNER JOIN Courses c ON co.CourseID = c.CourseID
    WHERE c.DeptID = (SELECT DeptID FROM Departments WHERE DeptCode = 'CS')
);

-- EXISTS
SELECT p.Title || ' ' || p.FirstName || ' ' || p.LastName AS Professor
FROM Professors p
WHERE EXISTS (
    SELECT 1 FROM CourseOfferings co WHERE co.ProfID = p.ProfID
);

-- NOT EXISTS
SELECT p.Title || ' ' || p.FirstName || ' ' || p.LastName AS Professor
FROM Professors p
WHERE NOT EXISTS (
    SELECT 1 FROM CourseOfferings co WHERE co.ProfID = p.ProfID
);

-- korrelierte Subquery
SELECT
    s.FirstName || ' ' || s.LastName AS Student,
    (SELECT MIN(e.Grade) FROM Enrollments e WHERE e.StudentID = s.StudentID AND e.Grade IS NOT NULL) AS BestGrade,
    (SELECT MAX(e.Grade) FROM Enrollments e WHERE e.StudentID = s.StudentID AND e.Grade IS NOT NULL) AS WorstGrade
FROM Students s
WHERE s.Status IN ('active', 'graduated')
ORDER BY BestGrade;


-- self-join: courses with their prerequisites
SELECT
    c.CourseID AS Course,
    c.CourseName,
    p.CourseID AS Prerequisite,
    p.CourseName AS PrerequisiteName
FROM Prerequisites pr
INNER JOIN Courses c ON pr.CourseID = c.CourseID
INNER JOIN Courses p ON pr.PrereqCourseID = p.CourseID
ORDER BY c.CourseID;

SELECT
    c.CourseID,
    c.CourseName,
    COUNT(*) AS DependentCourseCount
FROM Prerequisites pr
INNER JOIN Courses c ON pr.PrereqCourseID = c.CourseID
GROUP BY c.CourseID, c.CourseName
ORDER BY DependentCourseCount DESC;
