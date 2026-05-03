PRAGMA foreign_keys = ON;

INSERT INTO Departments (DeptName, DeptCode, Faculty) VALUES
    ('Computer Science',     'CS', 'Engineering & Informatics'),
    ('Mathematics',          'MA', 'Natural Sciences'),
    ('Physics',              'PH', 'Natural Sciences'),
    ('Electrical Engineering','EE', 'Engineering & Informatics'),
    ('Philosophy',           'PL', 'Humanities');

INSERT INTO Professors (FirstName, LastName, Email, Phone, Office, Title, HireDate, DeptID) VALUES
    ('Klaus',    'Mueller',   'mueller@uni.edu',    '+49-555-0001', 'B2.01',  'Prof. Dr.',      '2010-04-01', 1),
    ('Anna',     'Schmidt',   'schmidt@uni.edu',    '+49-555-0002', 'B3.05',  'Prof. Dr.',      '2012-10-01', 2),
    ('Thomas',   'Weber',     'weber@uni.edu',      '+49-555-0003', 'C1.10',  'Prof. Dr.-Ing.', '2015-04-01', 4),
    ('Maria',    'Fischer',   'fischer@uni.edu',     '+49-555-0004', 'B2.03',  'Prof. Dr.',      '2018-10-01', 1),
    ('Stefan',   'Braun',     'braun@uni.edu',       '+49-555-0005', 'D1.02',  'Prof. Dr.',      '2008-04-01', 3),
    ('Elisabeth','Hoffmann',  'hoffmann@uni.edu',    '+49-555-0006', 'A3.01',  'Prof. Dr.',      '2020-04-01', 5),
    ('Juergen',  'Schwarz',   'schwarz@uni.edu',     '+49-555-0007', 'B3.08',  'Prof. Dr.',      '2019-10-01', 2);

-- set HeadProfID after professors exist
UPDATE Departments SET HeadProfID = 1 WHERE DeptCode = 'CS';
UPDATE Departments SET HeadProfID = 2 WHERE DeptCode = 'MA';
UPDATE Departments SET HeadProfID = 5 WHERE DeptCode = 'PH';
UPDATE Departments SET HeadProfID = 3 WHERE DeptCode = 'EE';
UPDATE Departments SET HeadProfID = 6 WHERE DeptCode = 'PL';

INSERT INTO Students (FirstName, LastName, Email, MatriculationNr, MatriculationDate, DateOfBirth, DeptID, Status) VALUES
    ('Alice',    'Becker',    'alice.becker@stud.uni.edu',    'MN-2023-001', '2023-10-01', '2003-03-15', 1, 'active'),
    ('Bob',      'Wagner',    'bob.wagner@stud.uni.edu',      'MN-2023-002', '2023-10-01', '2002-07-22', 2, 'active'),
    ('Clara',    'Richter',   'clara.richter@stud.uni.edu',   'MN-2023-003', '2023-10-01', '2003-11-08', 1, 'active'),
    ('David',    'Koch',      'david.koch@stud.uni.edu',      'MN-2022-001', '2022-10-01', '2001-01-30', 3, 'active'),
    ('Eva',      'Schulz',    'eva.schulz@stud.uni.edu',      'MN-2022-002', '2022-10-01', '2002-05-12', 4, 'active'),
    ('Felix',    'Hartmann',  'felix.hartmann@stud.uni.edu',  'MN-2024-001', '2024-10-01', '2004-09-03', 1, 'active'),
    ('Greta',    'Lange',     'greta.lange@stud.uni.edu',     'MN-2024-002', '2024-10-01', '2005-02-18', 2, 'active'),
    ('Hans',     'Krause',    'hans.krause@stud.uni.edu',     'MN-2021-001', '2021-10-01', '2000-12-01', 1, 'graduated'),
    ('Ingrid',   'Wolf',      'ingrid.wolf@stud.uni.edu',     'MN-2023-004', '2023-04-01', '2003-06-25', 5, 'active'),
    ('Jan',      'Peters',    'jan.peters@stud.uni.edu',      'MN-2022-003', '2022-04-01', '2001-08-14', 3, 'on_leave');

INSERT INTO StudentPhones (StudentID, Phone, PhoneType) VALUES
    (1, '+49-170-1001', 'mobile'),
    (1, '+49-30-2001',  'home'),
    (2, '+49-170-1002', 'mobile'),
    (3, '+49-170-1003', 'mobile'),
    (3, '+49-170-1033', 'work'),
    (4, '+49-170-1004', 'mobile'),
    (5, '+49-170-1005', 'mobile'),
    (6, '+49-170-1006', 'mobile'),
    (7, '+49-170-1007', 'mobile'),
    (8, '+49-170-1008', 'mobile'),
    (9, '+49-170-1009', 'mobile'),
    (10,'+49-170-1010', 'mobile');

INSERT INTO Rooms (RoomNumber, Building, Capacity, RoomType) VALUES
    ('A1.01', 'Main Hall',        120, 'lecture_hall'),
    ('A1.02', 'Main Hall',         80, 'lecture_hall'),
    ('A2.03', 'Science Building',  60, 'lecture_hall'),
    ('B1.01', 'Lab Building',      30, 'lab'),
    ('B1.02', 'Lab Building',      25, 'lab'),
    ('C1.01', 'Seminar Building',  20, 'seminar'),
    ('C1.02', 'Seminar Building',  20, 'seminar'),
    ('D1.01', 'Exam Center',      200, 'exam_hall');

INSERT INTO Courses (CourseID, CourseName, Credits, Description, DeptID, CourseLevel) VALUES
    ('CS101', 'Introduction to Computer Science',  6,  'Fundamentals of CS including algorithms and data structures', 1, 'bachelor'),
    ('CS201', 'Data Structures & Algorithms',       6,  'Advanced data structures, sorting, graph algorithms',        1, 'bachelor'),
    ('CS301', 'Database Systems',                   6,  'Relational databases, SQL, normalization, transactions',     1, 'bachelor'),
    ('CS401', 'Machine Learning',                   6,  'Supervised and unsupervised learning, neural networks',      1, 'master'),
    ('MA101', 'Linear Algebra',                     6,  'Vectors, matrices, linear transformations',                  2, 'bachelor'),
    ('MA201', 'Calculus II',                        6,  'Multivariable calculus, integration techniques',             2, 'bachelor'),
    ('MA301', 'Numerical Methods',                  6,  'Numerical solutions to mathematical problems',              2, 'master'),
    ('PH101', 'Mechanics',                          6,  'Classical mechanics, Newtonian physics',                    3, 'bachelor'),
    ('PH201', 'Electrodynamics',                    6,  'Maxwells equations, electromagnetic waves',                 3, 'bachelor'),
    ('EE101', 'Circuit Theory',                     6,  'Basic circuit analysis, Kirchhoffs laws',                   4, 'bachelor'),
    ('EE201', 'Digital Systems',                    6,  'Boolean algebra, combinational and sequential circuits',    4, 'bachelor'),
    ('PL101', 'Introduction to Philosophy',         4,  'Overview of major philosophical traditions',                5, 'bachelor'),
    ('PL201', 'Ethics in Technology',               4,  'Ethical considerations in modern technology',               5, 'bachelor');

INSERT INTO Prerequisites (CourseID, PrereqCourseID) VALUES
    ('CS201', 'CS101'),
    ('CS301', 'CS201'),
    ('CS401', 'CS201'),
    ('CS401', 'MA201'),
    ('MA201', 'MA101'),
    ('MA301', 'MA201'),
    ('PH201', 'PH101'),
    ('PH201', 'MA101'),
    ('EE201', 'EE101'),
    ('PL201', 'PL101');

INSERT INTO Semesters (SemesterID, SemesterName, StartDate, EndDate) VALUES
    ('WS2024', 'Winter Semester 2024/25', '2024-10-01', '2025-03-31'),
    ('SS2025', 'Summer Semester 2025',    '2025-04-01', '2025-09-30'),
    ('WS2025', 'Winter Semester 2025/26', '2025-10-01', '2026-03-31');

-- WS2024
INSERT INTO CourseOfferings (CourseID, SemesterID, ProfID, RoomID, DayOfWeek, StartTime, EndTime, MaxStudents) VALUES
    ('CS101', 'WS2024', 1, 1, 'Monday',    '09:00', '10:30', 100),
    ('MA101', 'WS2024', 2, 2, 'Tuesday',   '09:00', '10:30', 80),
    ('PH101', 'WS2024', 5, 3, 'Wednesday', '11:00', '12:30', 60),
    ('EE101', 'WS2024', 3, 4, 'Thursday',  '14:00', '15:30', 30),
    ('PL101', 'WS2024', 6, 6, 'Friday',    '09:00', '10:30', 20);

-- SS2025
INSERT INTO CourseOfferings (CourseID, SemesterID, ProfID, RoomID, DayOfWeek, StartTime, EndTime, MaxStudents) VALUES
    ('CS201', 'SS2025', 4, 1, 'Monday',    '09:00', '10:30', 80),
    ('MA201', 'SS2025', 7, 2, 'Tuesday',   '09:00', '10:30', 80),
    ('PH201', 'SS2025', 5, 3, 'Wednesday', '11:00', '12:30', 60),
    ('EE201', 'SS2025', 3, 5, 'Thursday',  '14:00', '15:30', 25),
    ('PL201', 'SS2025', 6, 7, 'Friday',    '09:00', '10:30', 20);

-- WS2025
INSERT INTO CourseOfferings (CourseID, SemesterID, ProfID, RoomID, DayOfWeek, StartTime, EndTime, MaxStudents) VALUES
    ('CS301', 'WS2025', 1, 1, 'Monday',    '09:00', '10:30', 80),
    ('CS401', 'WS2025', 4, 3, 'Tuesday',   '14:00', '15:30', 40),
    ('MA301', 'WS2025', 2, 2, 'Wednesday', '09:00', '10:30', 60),
    ('CS101', 'WS2025', 1, 1, 'Thursday',  '09:00', '10:30', 100),
    ('MA101', 'WS2025', 7, 2, 'Friday',    '09:00', '10:30', 80);

INSERT INTO Enrollments (StudentID, OfferingID, EnrollDate, Grade, GradeDate, Status) VALUES
    (1, 1, '2024-09-15', 1.3, '2025-02-15', 'completed'),
    (1, 2, '2024-09-15', 1.7, '2025-02-18', 'completed'),
    (2, 2, '2024-09-16', 1.0, '2025-02-18', 'completed'),
    (3, 1, '2024-09-15', 2.3, '2025-02-15', 'completed'),
    (4, 3, '2024-09-17', 2.0, '2025-02-20', 'completed'),
    (5, 4, '2024-09-18', 1.7, '2025-02-22', 'completed'),
    (9, 5, '2024-09-20', 2.7, '2025-02-25', 'completed'),
    (6, 1, '2024-09-15', 3.0, '2025-02-15', 'completed'),
    (7, 2, '2024-09-16', 2.0, '2025-02-18', 'completed'),
    (8, 1, '2024-09-14', 1.0, '2025-02-15', 'completed');

INSERT INTO Enrollments (StudentID, OfferingID, EnrollDate, Grade, GradeDate, Status) VALUES
    (1, 6, '2025-03-15', 1.7, '2025-08-10', 'completed'),
    (1, 7, '2025-03-15', 2.0, '2025-08-12', 'completed'),
    (3, 6, '2025-03-15', 2.7, '2025-08-10', 'completed'),
    (2, 7, '2025-03-16', 1.3, '2025-08-12', 'completed'),
    (5, 9, '2025-03-18', 2.0, '2025-08-14', 'completed'),
    (9, 10,'2025-03-20', 1.7, '2025-08-16', 'completed'),
    (6, 6, '2025-03-15', NULL, NULL,         'enrolled'),
    (4, 8, '2025-03-17', 2.3, '2025-08-13', 'completed');

INSERT INTO Enrollments (StudentID, OfferingID, EnrollDate, Grade, Status) VALUES
    (1, 11, '2025-09-10', NULL, 'enrolled'),
    (1, 12, '2025-09-10', NULL, 'enrolled'),
    (3, 11, '2025-09-10', NULL, 'enrolled'),
    (2, 13, '2025-09-12', NULL, 'enrolled'),
    (7, 15, '2025-09-14', NULL, 'enrolled'),
    (6, 14, '2025-09-13', NULL, 'enrolled');

INSERT INTO ExamResults (EnrollmentID, AttemptNumber, ExamDate, ExamType, Score, Grade, Passed) VALUES
    (1,  1, '2025-02-10', 'written',   87.5, 1.3, 1),
    (2,  1, '2025-02-14', 'written',   82.0, 1.7, 1),
    (3,  1, '2025-02-14', 'written',   95.0, 1.0, 1),
    (4,  1, '2025-02-10', 'written',   72.0, 2.3, 1),
    (8,  1, '2025-02-10', 'written',   55.0, 4.0, 1),
    (10, 1, '2025-02-10', 'written',   98.0, 1.0, 1),
    (11, 1, '2025-08-05', 'project',   83.0, 1.7, 1),
    (13, 1, '2025-08-05', 'project',   68.0, 2.7, 1),
    (14, 1, '2025-08-08', 'written',   88.0, 1.3, 1),
    (17, 1, '2025-08-05', 'project',   40.0, 5.0, 0),
    (17, 2, '2025-09-01', 'oral',      62.0, 3.0, 1);
