import { Router } from "express";
import { UpdateCon } from "../../controllers/schedules/update_con.js";

const router = Router();

router.patch("/updatestatus/:id", UpdateCon);

export default router;