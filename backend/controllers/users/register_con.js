import { Register } from "../../models/users/register_model.js";
import bcrypt from "bcrypt";

export const RegisterCon = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ message: "All fields are required" });
    }

    const password_hash = await bcrypt.hash(password, 10);
    await Register.Register(name, email, password_hash);

    return res.status(201).json({ message: "User registered successfully" });
  } catch (err) {
    if (err.code === "ER_DUP_ENTRY") {
      return res.status(409).json({ message: "Email already exists" });
    }
    console.error(err);
    return res.status(500).json({ message: "Internal server error" });
  }
};