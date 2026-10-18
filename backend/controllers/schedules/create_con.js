import { Create } from "../../models/schedules/create_model.js";

const nextDay = (d) => {
  const dt = new Date(`${d}T00:00:00Z`);
  dt.setUTCDate(dt.getUTCDate() + 1);
  return dt.toISOString().slice(0, 10);
};

export const CreateCon = async (req, res) => {
  try {
    const { user_id, category_id, title, date, start, end, priority } =
      req.body;

    if (!user_id || !category_id || !title || !date || !start || !end) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    if (isNaN(new Date(`${date}T00:00:00Z`))) {
      return res.status(400).json({ message: "Invalid date" });
    }
    if (end === start) {
      return res
        .status(400)
        .json({ message: "End time must be different from start time" });
    }

    // If the end time is earlier than the start time, the task runs past
    // midnight, so the end belongs to the next day.
    const endDate = end < start ? nextDay(date) : date;

    const start_at = `${date} ${start}`;
    const end_at = `${endDate} ${end}`;
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