import { pool } from "../../config/db.js";

export const Update = {
  Status: async (id, user_id, status) => {
    const [result] = await pool.query(
      "UPDATE schedules SET status = ? WHERE id = ? AND user_id = ?",
      [status, id, user_id],
    );
    return result;
  },
};