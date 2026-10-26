import { Delete } from "../../models/schedules/delete_model.js";

export const DeleteCon = async (req, res) => {
  try {
    const { id } = req.params;
    const { user_id } = req.query;

    if (!id || !user_id) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    const result = await Delete.Delete(id, user_id);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Schedule not found" });
    }
    return res.status(200).json({ message: "Task deleted successfully" });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: "Internal server error" });
  }
};