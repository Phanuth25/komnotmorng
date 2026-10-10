import { Login } from "../../models/users/login_model.js";


export const LoginCon = async (req, res) => {
  const { email, password } = req.body;
  const user = await Login.findUsersByEmail(email);
  if (!user) {
    return res.status(404).json({ message: "Incorrect Email" });
  }
  if (user.password !== password) {
    return res.status(401).json({ message: "Incorrect Password" });
  }
  res.json({ message: "Login successful", data: user });
};  