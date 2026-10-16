import { Create } from "../../models/schedules/create_model.js";

export const CreateCon = async (req, res) => {
  try {
    const { user_id, category_id, title, date, start, end, priority } =
      req.body;

    if (!user_id || !category_id || !title || !date || !start || !end) {
      return res.status(400).json({ message: "Missing required fields" });
    }
    const start_at = `${date} ${start}`;
    const end_at = `${date} ${end}`;
    await Create.Create(
      user_id,
      category_id,
      title,
      start_at,
      end_at,
      priority,
    );

    return res.status(201).json({ message: "Task created successfully" });
  } catch (err) {
    if (err.code === "ER_DUP_ENTRY") {
      return res.status(409).json({ message: "Task already exists" });
    }
    console.error(err);
    return res.status(500).json({ message: "Internal server error" });
  }
};
