import { Update } from "../../models/schedules/update_model.js";

const ALLOWED = ["scheduled", "completed", "cancelled"];

export const UpdateCon = async (req, res) => {
  try {
    const { id } = req.params;
    const { user_id, status } = req.body;

    if (!id || !user_id || !status) {
      return res.status(400).json({ message: "Missing required fields" });
    }
    if (!ALLOWED.includes(status)) {
      return res.status(400).json({ message: "Invalid status" });
    }

    const result = await Update.Status(id, user_id, status);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Schedule not found" });
    }
    return res.status(200).json({ message: "Status updated successfully" });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: "Internal server error" });
  }
};