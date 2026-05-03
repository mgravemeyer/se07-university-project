import { readFileSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";
import { getDb, closeDb } from "./connection.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const SQL_DIR = join(__dirname, "..", "..", "sql");

export function initializeDatabase(): void {
  const db = getDb();

  console.log("Initializing database...");

  // Run schema (tables only, no triggers yet - seed data must go in first)
  const schema = readFileSync(join(SQL_DIR, "01_schema.sql"), "utf-8");
  db.exec(schema);
  console.log("  Schema created.");

  // Run indexes
  const indexes = readFileSync(join(SQL_DIR, "05_indexes.sql"), "utf-8");
  // Filter out EXPLAIN QUERY PLAN and PRAGMA lines (they return results, not DDL)
  const indexDDL = indexes
    .split("\n")
    .filter(
      (line) =>
        !line.trim().startsWith("EXPLAIN") &&
        !line.trim().startsWith("PRAGMA index_") &&
        !line.trim().startsWith("PRAGMA index_list")
    )
    .join("\n");
  db.exec(indexDDL);
  console.log("  Indexes created.");

  console.log("Database initialized successfully.");
}

export function seedDatabase(): void {
  const db = getDb();

  console.log("Seeding database...");

  const seed = readFileSync(join(SQL_DIR, "02_seed_data.sql"), "utf-8");
  db.exec(seed);

  console.log("Database seeded successfully.");
}

export function createTriggersAndViews(): void {
  const db = getDb();

  console.log("Creating triggers and views...");

  // Triggers & views are created AFTER seed data so that validation triggers
  // (like prerequisite checks) don't block seed inserts.
  const triggersViews = readFileSync(
    join(SQL_DIR, "06_triggers_views.sql"),
    "utf-8"
  );
  db.exec(triggersViews);

  console.log("  Triggers and views created.");
}

// Run if executed directly
const isMain = process.argv[1]?.includes("init");
if (isMain) {
  try {
    initializeDatabase();
    seedDatabase();
    createTriggersAndViews();
  } finally {
    closeDb();
  }
}
