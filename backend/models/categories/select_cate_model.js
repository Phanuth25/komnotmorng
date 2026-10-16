import { pool } from "../../config/db.js";

export const SelectCate = {

  SelectAllCate: async () => {
    const [rows] = await pool.query("SELECT id, name FROM categories");
    return rows;
  }

}

