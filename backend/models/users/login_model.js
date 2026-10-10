import { pool } from "../../config/db.js";

export const Login = {

  findUsersByEmail: async (email) => {
    const [rows] = await pool.query("SELECT * FROM users where email = ?", [email]);
    return rows;
  }

}

