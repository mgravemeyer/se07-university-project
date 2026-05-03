PRAGMA foreign_keys = ON;

-- HeadProfID is NULL because Professors table comes after
CREATE TABLE IF NOT EXISTS Departments (
    DeptID      INTEGER PRIMARY KEY AUTOINCREMENT,
    DeptName    TEXT    NOT NULL UNIQUE,
    DeptCode    TEXT    NOT NULL UNIQUE,
    Faculty     TEXT    NOT NULL,
    HeadProfID  INTEGER DEFAULT NULL,
    CreatedAt   TEXT    NOT NULL DEFAULT (datetime('now')),

    CHECK (length(DeptCode) BETWEEN 2 AND 5),

    FOREIGN KEY (HeadProfID) REFERENCES Professors(ProfID)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS Professors (
    ProfID      INTEGER PRIMARY KEY AUTOINCREMENT,
    FirstName   TEXT    NOT NULL,
    LastName    TEXT    NOT NULL,
    Email       TEXT    NOT NULL UNIQUE,
    Phone       TEXT,
    Office      TEXT,
    Title       TEXT    NOT NULL DEFAULT 'Prof. Dr.',
    HireDate    TEXT    NOT NULL,
    DeptID      INTEGER NOT NULL,

    CHECK (Email LIKE '%@%.%'),
    CHECK (HireDate GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),

    FOREIGN KEY (DeptID) REFERENCES Departments(DeptID)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS Students (
    StudentID          INTEGER PRIMARY KEY AUTOINCREMENT,
    FirstName          TEXT    NOT NULL,
    LastName           TEXT    NOT NULL,
    Email              TEXT    NOT NULL UNIQUE,
    MatriculationNr    TEXT    NOT NULL UNIQUE,
    MatriculationDate  TEXT    NOT NULL,
    DateOfBirth        TEXT,
    DeptID             INTEGER NOT NULL,
    Status             TEXT    NOT NULL DEFAULT 'active',

    CHECK (Email LIKE '%@%.%'),
    CHECK (Status IN ('active', 'inactive', 'graduated', 'on_leave')),
    CHECK (MatriculationDate GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),

    FOREIGN KEY (DeptID) REFERENCES Departments(DeptID)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- eigene Tabelle wegen 1NF (mehrwertige Attribute)
CREATE TABLE IF NOT EXISTS StudentPhones (
    StudentID   INTEGER NOT NULL,
    Phone       TEXT    NOT NULL,
    PhoneType   TEXT    NOT NULL DEFAULT 'mobile',

    PRIMARY KEY (StudentID, Phone),

    CHECK (PhoneType IN ('mobile', 'home', 'work')),

    FOREIGN KEY (StudentID) REFERENCES Students(StudentID)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Rooms (
    RoomID      INTEGER PRIMARY KEY AUTOINCREMENT,
    RoomNumber  TEXT    NOT NULL,
    Building    TEXT    NOT NULL,
    Capacity    INTEGER NOT NULL,
    RoomType    TEXT    NOT NULL DEFAULT 'lecture_hall',

    UNIQUE (RoomNumber, Building),

    CHECK (Capacity > 0),
    CHECK (RoomType IN ('lecture_hall', 'seminar', 'lab', 'exam_hall'))
);

CREATE TABLE IF NOT EXISTS Courses (
    CourseID     TEXT    PRIMARY KEY,
    CourseName   TEXT    NOT NULL,
    Credits      INTEGER NOT NULL,
    Description  TEXT,
    DeptID       INTEGER NOT NULL,
    CourseLevel  TEXT    NOT NULL DEFAULT 'bachelor',

    CHECK (Credits BETWEEN 1 AND 30),
    CHECK (CourseLevel IN ('bachelor', 'master', 'doctoral')),

    FOREIGN KEY (DeptID) REFERENCES Departments(DeptID)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- M:N Self-Referenz
CREATE TABLE IF NOT EXISTS Prerequisites (
    CourseID        TEXT NOT NULL,
    PrereqCourseID  TEXT NOT NULL,

    PRIMARY KEY (CourseID, PrereqCourseID),

    CHECK (CourseID != PrereqCourseID),

    FOREIGN KEY (CourseID)       REFERENCES Courses(CourseID)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (PrereqCourseID) REFERENCES Courses(CourseID)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS Semesters (
    SemesterID   TEXT PRIMARY KEY,
    SemesterName TEXT NOT NULL,
    StartDate    TEXT NOT NULL,
    EndDate      TEXT NOT NULL,

    CHECK (StartDate < EndDate)
);

-- UNIQUE constraints gegen Doppelbuchungen
CREATE TABLE IF NOT EXISTS CourseOfferings (
    OfferingID  INTEGER PRIMARY KEY AUTOINCREMENT,
    CourseID    TEXT    NOT NULL,
    SemesterID  TEXT    NOT NULL,
    ProfID      INTEGER NOT NULL,
    RoomID      INTEGER NOT NULL,
    DayOfWeek   TEXT    NOT NULL,
    StartTime   TEXT    NOT NULL,
    EndTime     TEXT    NOT NULL,
    MaxStudents INTEGER NOT NULL DEFAULT 100,

    UNIQUE (CourseID, SemesterID),
    UNIQUE (ProfID, SemesterID, DayOfWeek, StartTime),
    UNIQUE (RoomID, SemesterID, DayOfWeek, StartTime),

    CHECK (StartTime < EndTime),
    CHECK (MaxStudents > 0),
    CHECK (DayOfWeek IN ('Monday','Tuesday','Wednesday','Thursday','Friday')),

    FOREIGN KEY (CourseID)   REFERENCES Courses(CourseID)     ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (SemesterID) REFERENCES Semesters(SemesterID) ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (ProfID)     REFERENCES Professors(ProfID)    ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (RoomID)     REFERENCES Rooms(RoomID)         ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Noten: deutsches System, 1.0 (beste) bis 5.0 (durchgefallen)
CREATE TABLE IF NOT EXISTS Enrollments (
    EnrollmentID  INTEGER PRIMARY KEY AUTOINCREMENT,
    StudentID     INTEGER NOT NULL,
    OfferingID    INTEGER NOT NULL,
    EnrollDate    TEXT    NOT NULL DEFAULT (date('now')),
    Grade         REAL,
    GradeDate     TEXT,
    Status        TEXT    NOT NULL DEFAULT 'enrolled',

    UNIQUE (StudentID, OfferingID),

    CHECK (Grade IS NULL OR (Grade >= 1.0 AND Grade <= 5.0)),
    CHECK (Status IN ('enrolled', 'completed', 'failed', 'withdrawn')),

    FOREIGN KEY (StudentID)  REFERENCES Students(StudentID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (OfferingID) REFERENCES CourseOfferings(OfferingID)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- bis zu 3 Versuche pro Pruefung
CREATE TABLE IF NOT EXISTS ExamResults (
    ExamResultID  INTEGER PRIMARY KEY AUTOINCREMENT,
    EnrollmentID  INTEGER NOT NULL,
    AttemptNumber INTEGER NOT NULL DEFAULT 1,
    ExamDate      TEXT    NOT NULL,
    ExamType      TEXT    NOT NULL,
    Score         REAL,
    Grade         REAL,
    Passed        INTEGER,

    UNIQUE (EnrollmentID, AttemptNumber),

    CHECK (AttemptNumber BETWEEN 1 AND 3),
    CHECK (ExamType IN ('written', 'oral', 'project', 'portfolio')),
    CHECK (Score IS NULL OR (Score >= 0 AND Score <= 100)),
    CHECK (Grade IS NULL OR (Grade >= 1.0 AND Grade <= 5.0)),
    CHECK (Passed IS NULL OR Passed IN (0, 1)),

    FOREIGN KEY (EnrollmentID) REFERENCES Enrollments(EnrollmentID)
        ON UPDATE CASCADE ON DELETE CASCADE
);
