import { Select } from "../../models/schedules/select_model.js";


export const SelectCon = async (req, res) => {
  try {
    const { user_id } =
      req.params;

    if (!user_id) {
      return res.status(400).json({ message: "Missing user_id" });
    }

    const result = await Select.Select(
      user_id,
    );
    if (result.length === 0) {
      return res.status(404).json({ message: "No schdules found" });
    }
    return res.status(201).json({ message: "Select schedules successfully", data: result });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: "Internal server error" });
  }
};