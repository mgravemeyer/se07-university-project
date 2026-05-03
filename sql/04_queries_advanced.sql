PRAGMA foreign_keys = ON;

-- Studenten pro Department
SELECT d.DeptName, COUNT(s.StudentID) AS StudentCount
FROM Departments d
LEFT JOIN Students s ON d.DeptID = s.DeptID
GROUP BY d.DeptID, d.DeptName
ORDER BY StudentCount DESC;

-- average grade per course
SELECT
    c.CourseID,
    c.CourseName,
    COUNT(e.EnrollmentID) AS TotalEnrollments,
    ROUND(AVG(e.Grade), 2) AS AvgGrade,
    MIN(e.Grade) AS BestGrade,
    MAX(e.Grade) AS WorstGrade
FROM Courses c
INNER JOIN CourseOfferings co ON c.CourseID = co.CourseID
INNER JOIN Enrollments e     ON co.OfferingID = e.OfferingID
WHERE e.Grade IS NOT NULL
GROUP BY c.CourseID, c.CourseName
ORDER BY AvgGrade;

-- HAVING
SELECT d.DeptName, COUNT(s.StudentID) AS StudentCount
FROM Departments d
INNER JOIN Students s ON d.DeptID = s.DeptID
GROUP BY d.DeptID, d.DeptName
HAVING COUNT(s.StudentID) > 2;

-- credits and GPA per student
SELECT
    s.FirstName || ' ' || s.LastName AS Student,
    s.MatriculationNr,
    SUM(c.Credits) AS TotalCreditsEarned,
    COUNT(e.EnrollmentID) AS CompletedCourses,
    ROUND(AVG(e.Grade), 2) AS GPA
FROM Students s
INNER JOIN Enrollments e       ON s.StudentID   = e.StudentID
INNER JOIN CourseOfferings co  ON e.OfferingID  = co.OfferingID
INNER JOIN Courses c           ON co.CourseID   = c.CourseID
WHERE e.Status = 'completed'
GROUP BY s.StudentID
ORDER BY TotalCreditsEarned DESC;


-- CASE: deutsches Notensystem
SELECT
    s.FirstName || ' ' || s.LastName AS Student,
    c.CourseID,
    e.Grade,
    CASE
        WHEN e.Grade IS NULL      THEN 'Not yet graded'
        WHEN e.Grade <= 1.5       THEN 'sehr gut'
        WHEN e.Grade <= 2.5       THEN 'gut'
        WHEN e.Grade <= 3.5       THEN 'befriedigend'
        WHEN e.Grade <= 4.0       THEN 'ausreichend'
        ELSE                           'nicht bestanden'
    END AS GradeClassification
FROM Enrollments e
INNER JOIN Students s       ON e.StudentID = s.StudentID
INNER JOIN CourseOfferings co ON e.OfferingID = co.OfferingID
INNER JOIN Courses c        ON co.CourseID = c.CourseID
ORDER BY s.LastName, c.CourseID;

-- passed/failed per course
SELECT
    c.CourseID,
    c.CourseName,
    COUNT(e.EnrollmentID) AS TotalStudents,
    SUM(CASE WHEN e.Grade IS NOT NULL AND e.Grade <= 4.0 THEN 1 ELSE 0 END) AS Passed,
    SUM(CASE WHEN e.Grade IS NOT NULL AND e.Grade > 4.0  THEN 1 ELSE 0 END) AS Failed,
    SUM(CASE WHEN e.Grade IS NULL THEN 1 ELSE 0 END) AS Pending
FROM Courses c
INNER JOIN CourseOfferings co ON c.CourseID = co.CourseID
INNER JOIN Enrollments e     ON co.OfferingID = e.OfferingID
GROUP BY c.CourseID, c.CourseName;


-- CTE: GPA-Ranking
WITH StudentGPA AS (
    SELECT
        s.StudentID,
        s.FirstName || ' ' || s.LastName AS Student,
        d.DeptName,
        ROUND(AVG(e.Grade), 2) AS GPA,
        SUM(c.Credits) AS TotalCredits,
        COUNT(e.EnrollmentID) AS CoursesTaken
    FROM Students s
    INNER JOIN Enrollments e       ON s.StudentID  = e.StudentID
    INNER JOIN CourseOfferings co  ON e.OfferingID = co.OfferingID
    INNER JOIN Courses c           ON co.CourseID  = c.CourseID
    INNER JOIN Departments d       ON s.DeptID     = d.DeptID
    WHERE e.Status = 'completed' AND e.Grade IS NOT NULL
    GROUP BY s.StudentID
)
SELECT Student, DeptName, GPA, TotalCredits, CoursesTaken
FROM StudentGPA
ORDER BY GPA ASC;

-- 2 CTEs: Vergleich Student vs. Department-Schnitt
WITH DeptAvg AS (
    SELECT
        d.DeptID,
        d.DeptName,
        ROUND(AVG(e.Grade), 2) AS DeptAvgGrade
    FROM Departments d
    INNER JOIN Students s         ON d.DeptID     = s.DeptID
    INNER JOIN Enrollments e      ON s.StudentID  = e.StudentID
    WHERE e.Grade IS NOT NULL
    GROUP BY d.DeptID
),
StudentPerf AS (
    SELECT
        s.StudentID,
        s.FirstName || ' ' || s.LastName AS Student,
        s.DeptID,
        ROUND(AVG(e.Grade), 2) AS StudentAvg
    FROM Students s
    INNER JOIN Enrollments e ON s.StudentID = e.StudentID
    WHERE e.Grade IS NOT NULL
    GROUP BY s.StudentID
)
SELECT
    sp.Student,
    da.DeptName,
    sp.StudentAvg,
    da.DeptAvgGrade,
    ROUND(sp.StudentAvg - da.DeptAvgGrade, 2) AS Difference,
    CASE
        WHEN sp.StudentAvg < da.DeptAvgGrade THEN 'Above average'
        WHEN sp.StudentAvg > da.DeptAvgGrade THEN 'Below average'
        ELSE 'Average'
    END AS Performance
FROM StudentPerf sp
INNER JOIN DeptAvg da ON sp.DeptID = da.DeptID
ORDER BY Difference;


-- Rekursive CTE: alle Voraussetzungen fuer CS401
WITH RECURSIVE PrereqChain AS (
    SELECT
        pr.CourseID,
        pr.PrereqCourseID,
        1 AS Depth,
        pr.CourseID || ' -> ' || pr.PrereqCourseID AS Chain
    FROM Prerequisites pr
    WHERE pr.CourseID = 'CS401'

    UNION ALL

    SELECT
        pc.CourseID,
        pr.PrereqCourseID,
        pc.Depth + 1,
        pc.Chain || ' -> ' || pr.PrereqCourseID
    FROM PrereqChain pc
    INNER JOIN Prerequisites pr ON pc.PrereqCourseID = pr.CourseID
)
SELECT
    pc.CourseID AS TargetCourse,
    c.CourseName AS PrerequisiteName,
    pc.PrereqCourseID,
    pc.Depth,
    pc.Chain
FROM PrereqChain pc
INNER JOIN Courses c ON pc.PrereqCourseID = c.CourseID
ORDER BY pc.Depth, pc.PrereqCourseID;


-- RANK / DENSE_RANK / ROW_NUMBER
SELECT
    c.CourseID,
    c.CourseName,
    s.FirstName || ' ' || s.LastName AS Student,
    e.Grade,
    RANK()       OVER (PARTITION BY co.CourseID ORDER BY e.Grade ASC) AS GradeRank,
    DENSE_RANK() OVER (PARTITION BY co.CourseID ORDER BY e.Grade ASC) AS DenseRank,
    ROW_NUMBER() OVER (PARTITION BY co.CourseID ORDER BY e.Grade ASC) AS RowNum
FROM Enrollments e
INNER JOIN Students s        ON e.StudentID  = s.StudentID
INNER JOIN CourseOfferings co ON e.OfferingID = co.OfferingID
INNER JOIN Courses c         ON co.CourseID  = c.CourseID
WHERE e.Grade IS NOT NULL
ORDER BY c.CourseID, e.Grade;

-- laufende Credits-Summe
WITH OrderedEnrollments AS (
    SELECT
        s.StudentID,
        s.FirstName || ' ' || s.LastName AS Student,
        sem.SemesterID,
        c.CourseID,
        c.Credits,
        e.Grade,
        sem.StartDate
    FROM Enrollments e
    INNER JOIN Students s        ON e.StudentID  = s.StudentID
    INNER JOIN CourseOfferings co ON e.OfferingID = co.OfferingID
    INNER JOIN Courses c         ON co.CourseID  = c.CourseID
    INNER JOIN Semesters sem     ON co.SemesterID = sem.SemesterID
    WHERE e.Status = 'completed'
)
SELECT
    Student,
    SemesterID,
    CourseID,
    Credits,
    Grade,
    SUM(Credits) OVER (
        PARTITION BY StudentID ORDER BY StartDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS RunningCreditTotal,
    ROUND(AVG(Grade) OVER (
        PARTITION BY StudentID ORDER BY StartDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS RunningAvgGrade
FROM OrderedEnrollments
ORDER BY Student, StartDate, CourseID;

-- NTILE + PERCENT_RANK
SELECT
    s.FirstName || ' ' || s.LastName AS Student,
    c.CourseID,
    e.Grade,
    NTILE(4) OVER (ORDER BY e.Grade ASC) AS Quartile,
    ROUND(PERCENT_RANK() OVER (ORDER BY e.Grade ASC) * 100, 1) AS PercentileRank
FROM Enrollments e
INNER JOIN Students s        ON e.StudentID  = s.StudentID
INNER JOIN CourseOfferings co ON e.OfferingID = co.OfferingID
INNER JOIN Courses c         ON co.CourseID  = c.CourseID
WHERE e.Grade IS NOT NULL
ORDER BY e.Grade;

-- LAG/LEAD: Pruefungsversuche vergleichen
SELECT
    s.FirstName || ' ' || s.LastName AS Student,
    c.CourseID,
    er.AttemptNumber,
    er.ExamType,
    er.Score,
    er.Grade,
    er.Passed,
    LAG(er.Score) OVER (PARTITION BY er.EnrollmentID ORDER BY er.AttemptNumber) AS PreviousScore,
    er.Score - LAG(er.Score) OVER (PARTITION BY er.EnrollmentID ORDER BY er.AttemptNumber) AS ScoreImprovement
FROM ExamResults er
INNER JOIN Enrollments e     ON er.EnrollmentID = e.EnrollmentID
INNER JOIN Students s        ON e.StudentID     = s.StudentID
INNER JOIN CourseOfferings co ON e.OfferingID   = co.OfferingID
INNER JOIN Courses c         ON co.CourseID     = c.CourseID
ORDER BY s.LastName, c.CourseID, er.AttemptNumber;


-- UNION
SELECT FirstName, LastName, Email, 'Professor' AS Role
FROM Professors
WHERE DeptID = (SELECT DeptID FROM Departments WHERE DeptCode = 'CS')
UNION
SELECT FirstName, LastName, Email, 'Student' AS Role
FROM Students
WHERE DeptID = (SELECT DeptID FROM Departments WHERE DeptCode = 'CS')
ORDER BY Role, LastName;

-- INTERSECT: enrolled in both CS101 and MA101
SELECT s.FirstName, s.LastName
FROM Students s
INNER JOIN Enrollments e     ON s.StudentID = e.StudentID
INNER JOIN CourseOfferings co ON e.OfferingID = co.OfferingID
WHERE co.CourseID = 'CS101'
INTERSECT
SELECT s.FirstName, s.LastName
FROM Students s
INNER JOIN Enrollments e     ON s.StudentID = e.StudentID
INNER JOIN CourseOfferings co ON e.OfferingID = co.OfferingID
WHERE co.CourseID = 'MA101';

-- EXCEPT: CS students not enrolled in MA101
SELECT s.FirstName, s.LastName
FROM Students s
WHERE s.DeptID = (SELECT DeptID FROM Departments WHERE DeptCode = 'CS')
EXCEPT
SELECT s.FirstName, s.LastName
FROM Students s
INNER JOIN Enrollments e     ON s.StudentID = e.StudentID
INNER JOIN CourseOfferings co ON e.OfferingID = co.OfferingID
WHERE co.CourseID = 'MA101';


-- Semester-Report
WITH SemesterStats AS (
    SELECT
        sem.SemesterID,
        sem.SemesterName,
        c.CourseID,
        c.CourseName,
        d.DeptName,
        COUNT(e.EnrollmentID) AS EnrolledCount,
        SUM(CASE WHEN e.Status = 'completed' THEN 1 ELSE 0 END) AS CompletedCount,
        SUM(CASE WHEN e.Status = 'withdrawn' THEN 1 ELSE 0 END) AS WithdrawnCount,
        ROUND(AVG(CASE WHEN e.Grade IS NOT NULL THEN e.Grade END), 2) AS AvgGrade,
        co.MaxStudents,
        ROUND(COUNT(e.EnrollmentID) * 100.0 / co.MaxStudents, 1) AS UtilizationPct
    FROM Semesters sem
    INNER JOIN CourseOfferings co ON sem.SemesterID = co.SemesterID
    INNER JOIN Courses c         ON co.CourseID    = c.CourseID
    INNER JOIN Departments d     ON c.DeptID       = d.DeptID
    LEFT  JOIN Enrollments e     ON co.OfferingID  = e.OfferingID
    GROUP BY sem.SemesterID, c.CourseID
)
SELECT
    SemesterName,
    CourseID,
    CourseName,
    DeptName,
    EnrolledCount,
    CompletedCount,
    WithdrawnCount,
    AvgGrade,
    UtilizationPct || '%' AS RoomUtilization,
    CASE
        WHEN UtilizationPct >= 80 THEN 'High demand'
        WHEN UtilizationPct >= 50 THEN 'Normal'
        ELSE 'Low enrollment'
    END AS DemandLevel
FROM SemesterStats
ORDER BY SemesterName, DeptName, CourseID;
