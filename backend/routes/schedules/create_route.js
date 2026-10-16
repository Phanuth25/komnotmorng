import { Router } from "express";
import { CreateCon } from "../../controllers/schedules/create_con.js";

const router = Router();

router.post("/create", CreateCon);

export default router;
