import { Register } from "../../models/users/register_model.js";
import { Login } from "../../models/users/login_model.js";
import bcrypt from "bcrypt";

export const RegisterCon = async (req, res) => {
  const { name, email, password } = req.body;
  const existingUser = await Login.findUsersByEmail(email);
  if (existingUser.length > 0) {
    return res.status(400).json({ message: "Email already exists" });
  }
  const saltRounds = 10;
  const password_hash = await bcrypt.hash(password, saltRounds);
  const result = await Register.Register(name, email, password_hash);
  return res
    .status(201)
    .json({ message: "User registered successfully", user: result });
};
