import { pool } from "../../config/db.js";


export const Create = {
  Create: async (user_id,category_id,title,start_at,end_at,priority) => {

    const [result] = await pool.query(
      "INSERT INTO schedules (user_id, category_id, title, start_at, end_at, priority) VALUES (?, ?, ?, ?, ?, ?)",
      [user_id, category_id, title, start_at, end_at, priority],
    );
    return result;
  },
};
