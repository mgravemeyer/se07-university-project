PRAGMA foreign_keys = ON;

-- before: full table scan
EXPLAIN QUERY PLAN
SELECT * FROM Enrollments WHERE StudentID = 1 AND Status = 'completed';


-- single-column
CREATE INDEX IF NOT EXISTS idx_students_lastname ON Students(LastName);
CREATE INDEX IF NOT EXISTS idx_students_status ON Students(Status);
CREATE INDEX IF NOT EXISTS idx_professors_lastname ON Professors(LastName);
CREATE INDEX IF NOT EXISTS idx_courses_deptid ON Courses(DeptID);

-- FK columns (SQLite doesn't auto-index these)
CREATE INDEX IF NOT EXISTS idx_enrollments_studentid ON Enrollments(StudentID);
CREATE INDEX IF NOT EXISTS idx_enrollments_offeringid ON Enrollments(OfferingID);
CREATE INDEX IF NOT EXISTS idx_courseofferings_courseid ON CourseOfferings(CourseID);
CREATE INDEX IF NOT EXISTS idx_courseofferings_profid ON CourseOfferings(ProfID);
CREATE INDEX IF NOT EXISTS idx_courseofferings_roomid ON CourseOfferings(RoomID);
CREATE INDEX IF NOT EXISTS idx_courseofferings_semesterid ON CourseOfferings(SemesterID);
CREATE INDEX IF NOT EXISTS idx_examresults_enrollmentid ON ExamResults(EnrollmentID);
CREATE INDEX IF NOT EXISTS idx_students_deptid ON Students(DeptID);
CREATE INDEX IF NOT EXISTS idx_professors_deptid ON Professors(DeptID);

-- composite
CREATE INDEX IF NOT EXISTS idx_enrollments_status_grade
    ON Enrollments(Status, Grade);

CREATE INDEX IF NOT EXISTS idx_offerings_semester_day_time
    ON CourseOfferings(SemesterID, DayOfWeek, StartTime);

-- partial
CREATE INDEX IF NOT EXISTS idx_students_active
    ON Students(LastName, FirstName)
    WHERE Status = 'active';

CREATE INDEX IF NOT EXISTS idx_enrollments_ungraded
    ON Enrollments(OfferingID)
    WHERE Grade IS NULL AND Status = 'enrolled';


-- after: should use index now
EXPLAIN QUERY PLAN
SELECT * FROM Enrollments WHERE StudentID = 1 AND Status = 'completed';
