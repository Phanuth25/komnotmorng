import express from "express";
import login from "./routes/users/login_route.js";
import register from "./routes/users/register_route.js";
import { connectDB } from "./config/db.js";

const app = express();
const PORT = process.env.PORT || 3000;

// middleware
app.use(express.json());

// routes
app.use("/api", login);
app.use("/api", register);

// start.
await connectDB();

app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});
