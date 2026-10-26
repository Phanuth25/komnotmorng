import { pool } from "../../config/db.js";

export const Delete = {
  Delete: async (id, user_id) => {
    const [result] = await pool.query(
      "DELETE FROM schedules WHERE id = ? AND user_id = ?",
      [id, user_id],
    );
    return result;
  },
};