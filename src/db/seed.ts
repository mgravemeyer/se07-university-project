import { closeDb } from "./connection.js";
import { seedDatabase } from "./init.js";

try {
  seedDatabase();
} finally {
  closeDb();
}
