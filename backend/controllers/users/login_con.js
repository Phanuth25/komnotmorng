import { Login } from "../../models/users/login_model.js";
import bcrypt from "bcrypt";

export const LoginCon = async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ message: "Email and password are required" });
  }
  console.log("Received login request:", { email, password }); // Log the received email and password
  const user = await Login.findUsersByEmail(email);
  if (!user) {
    return res.status(404).json({ message: "Incorrect Email" });
  }
  console.log("User found:", user); // Log the user object to see its structure
  const userData = user[0];
  console.log("User data:", userData); // Log the user data to see its structure
  const isMatch = await bcrypt.compare(password, userData.password_hash);
  if (!isMatch) {
    return res.status(401).json({ message: "Incorrect Password entered" });
  }
  res.status(200).json({ message: "Login successful", data: userData.name });
};
