import { Login } from "../../models/users/login_model.js";
import bcrypt from "bcrypt";

export const LoginCon = async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ message: "Email and password are required" });
  }
  console.log("Received login request:", { email, password });
  const user = await Login.findUsersByEmail(email);
  if (!user || user.length === 0) {
    return res.status(404).json({ message: "Incorrect Email" });
  }
  console.log("User found:", user);
  const userData = user[0];
  console.log("User data:", userData);
  const isMatch = await bcrypt.compare(password, userData.password_hash);
  if (!isMatch) {
    return res.status(401).json({ message: "Incorrect Password entered" });
  }
  res.status(200).json({
    message: "Login successful",
    data: [userData.name, userData.id],
  });
};