import express from "express";
import login from "./routes/users/login_route.js";
import register from "./routes/users/register_route.js";
import create from "./routes/schedules/create_route.js";
import selectCate from "./routes/categories/select_cate_route.js";
import selectSche from "./routes/schedules/select_route.js";
import update from "./routes/schedules/update_route.js";
import deleteSchedule from "./routes/schedules/delete_route.js";

import cors from "cors";

import { connectDB } from "./config/db.js";

const app = express();
const PORT = process.env.PORT || 3000;

// middleware
app.use(cors());
app.use(express.json());

// routes
app.use("/api", login);
app.use("/api", register);
app.use("/api", create);
app.use("/api", selectCate);
app.use("/api", selectSche);
app.use("/api", update);
app.use("/api", deleteSchedule);
// start.
await connectDB();

app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});
