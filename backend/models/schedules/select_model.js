import { pool } from "../../config/db.js";

export const Select = {
  Select: async (user_id) => {
    const [rows] = await pool.query(
      "SELECT * From schedule_with_category where user_id = ?",
      [user_id],
    );
    return rows;
  },
};
