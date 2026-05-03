# University Management System

SQLite database with 12 tables, normalized to BCNF, with a REST API on top. No ORM.

## Setup

```bash
npm install
npm run db:reset      # creates university.db, applies schema, seeds data
npm run dev           # starts on http://localhost:3000
```

Needs Node.js >= 22. SQLite is embedded, no extra database server needed.

Other scripts:

```bash
npm run db:init       # only schema + indexes
npm run db:seed       # only seed data
npm run build && npm start   # production build
```

## What the API does / Use cases

### Students

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/students` | List students (filter: `?status=`, `?dept=`) |
| GET | `/api/students/:id` | Student detail with phone numbers |
| POST | `/api/students` | Create student with phones |
| DELETE | `/api/students/:id` | Delete student |
| GET | `/api/students/:id/transcript` | Transcript with GPA |

### Courses

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/courses` | List all courses |
| GET | `/api/courses/:id` | Course with prerequisite chain (recursive CTE) |

### Enrollments

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/enrollments` | Enroll student (triggers check capacity + prerequisites) |
| PUT | `/api/enrollments/:id/grade` | Set grade (trigger auto-updates status) |

### Stats

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/departments` | Department stats (via view) |
| GET | `/api/stats/overview` | Top students by GPA (CTE + RANK) |
| GET | `/api/audit-log` | Audit trail (`?limit=`) |

## Database design

The schema went through three iterations:

1. **Sketch** — `docs/er-diagram-handdrawn.png`, rough entities and relationships on paper
2. **Logical model** — `docs/database.dbml` and `docs/er-diagram.png`, with cardinalities and foreign keys
3. **Implementation** — `sql/01_schema.sql`, with CHECK constraints, triggers, and views

Normalization walkthrough (UNF to BCNF) is in `docs/normalization.md`.

### Tables

12 tables in four groups:

- **Organization**: Departments, Professors, Rooms, Semesters
- **Academic**: Courses, Prerequisites, CourseOfferings
- **Students**: Students, StudentPhones
- **Records**: Enrollments, ExamResults, AuditLog

Interesting bits:
- M:N between Students and CourseOfferings via Enrollments (with Grade, Status on the junction table)
- Self-referential M:N on Courses via Prerequisites
- Circular FK between Departments and Professors (nullable HeadProfID)

### Constraints

Business rules are enforced in the database, not in app code:
- CHECK constraints for email format, date format, grade ranges, enums
- UNIQUE constraints to prevent double-booked professors/rooms and duplicate enrollments
- Foreign keys with CASCADE/RESTRICT/SET NULL depending on the relationship
- 4 triggers: capacity check, prerequisite check, auto-status on grading, audit log
- 4 views: active students, course catalog, transcript, department stats

### Indexes

Defined in `sql/05_indexes.sql`. Mainly FK columns (SQLite doesn't auto-index those), plus a couple composite and partial indexes for common queries.

## Seed data

Hand-written in `sql/02_seed_data.sql`. Small dataset (about 120 rows total) but covers the edge cases: failed + retaken exams, prerequisite chains, schedules across three semesters.

## Files

```
docs/
  er-diagram-handdrawn.png    sketch
  er-diagram.png              final ER diagram
  database.dbml               DBML source
  normalization.md            UNF → BCNF walkthrough
sql/
  01_schema.sql               tables, FKs, constraints
  02_seed_data.sql            seed data
  03_queries_basic.sql        JOINs, subqueries
  04_queries_advanced.sql     CTEs, window functions
  05_indexes.sql              index definitions
  06_triggers_views.sql       triggers, views, audit table
  07_transactions.sql         transaction examples
src/
  db/connection.ts            DB connection, WAL setup
  db/init.ts                  schema + seed runner
  db/reset.ts                 drop + recreate
  db/seed.ts                  standalone seed
  server.ts                   all API endpoints
```

## Tech

- Node.js + TypeScript
- Hono (web framework)
- better-sqlite3 (database driver)
- Zod (input validation)
