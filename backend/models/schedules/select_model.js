import { pool } from "../../config/db.js";

export const Select = {
  Select: async (user_id) => {
    const [rows] = await pool.query(
      "SELECT * From schedules where user_id = ?",
      [user_id],
    );
    return rows;
  },
};
