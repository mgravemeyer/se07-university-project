PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

-- all or nothing
BEGIN TRANSACTION;
    INSERT INTO Enrollments (StudentID, OfferingID, EnrollDate, Status)
    VALUES (4, 14, '2025-09-20', 'enrolled');

    INSERT INTO Enrollments (StudentID, OfferingID, EnrollDate, Status)
    VALUES (4, 15, '2025-09-20', 'enrolled');
COMMIT;


-- Rollback
BEGIN TRANSACTION;
    UPDATE Enrollments SET Grade = 1.0 WHERE Grade IS NOT NULL;
ROLLBACK;


-- Savepoint
BEGIN TRANSACTION;
    UPDATE Students SET Status = 'graduated' WHERE StudentID = 8;

    SAVEPOINT sp_grade_update;

    UPDATE Enrollments SET Grade = 1.0
    WHERE StudentID = 1 AND OfferingID = 11;

    UPDATE Enrollments SET Grade = 2.3
    WHERE StudentID = 1 AND OfferingID = 12;

    ROLLBACK TO sp_grade_update;

    UPDATE Enrollments SET Grade = 1.7
    WHERE StudentID = 1 AND OfferingID = 11;
COMMIT;


-- atomic course transfer
BEGIN TRANSACTION;
    SELECT CASE
        WHEN (
            SELECT COUNT(*) FROM Enrollments
            WHERE OfferingID = 13 AND Status != 'withdrawn'
        ) >= (
            SELECT MaxStudents FROM CourseOfferings WHERE OfferingID = 13
        )
        THEN RAISE(ABORT, 'Target course is full')
    END;

    UPDATE Enrollments SET Status = 'withdrawn'
    WHERE StudentID = 2 AND OfferingID = 13;

    INSERT INTO Enrollments (StudentID, OfferingID, EnrollDate, Status)
    VALUES (2, 14, date('now'), 'enrolled');
COMMIT;
