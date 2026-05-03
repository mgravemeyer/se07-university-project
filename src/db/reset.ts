import { existsSync, unlinkSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";
import { closeDb } from "./connection.js";
import { initializeDatabase, seedDatabase, createTriggersAndViews } from "./init.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const DB_PATH = join(__dirname, "..", "..", "university.db");

closeDb();

if (existsSync(DB_PATH)) {
  unlinkSync(DB_PATH);
  console.log("Old database deleted.");
}

initializeDatabase();
seedDatabase();
createTriggersAndViews();
closeDb();
console.log("Database reset complete.");
