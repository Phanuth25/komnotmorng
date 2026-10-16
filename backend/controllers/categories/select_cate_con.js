import { SelectCate } from "../../models/categories/select_cate_model.js";

export const SelectCateCon = async (req, res) => {
  try {
    const categories = await SelectCate.SelectAllCate();
    if (!categories || categories.length === 0) {
      return res.status(404).json({ message: "No categories found" });
    }
    return res
      .status(200)
      .json({ message: "Categories retrieved successfully", categories });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: "Internal server error" });
  }
};
