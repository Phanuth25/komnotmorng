import { pool } from "../../config/db.js";


export const Register = {
  Register: async (name, email, password_hash) => {
    const [result] = await pool.query(
      "INSERT INTO users (name, email, password_hash) VALUES (?, ?, ?)",
      [name, email, password_hash],
    );
    return result;
  },
};
