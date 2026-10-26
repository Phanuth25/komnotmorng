import { Router } from "express";
import { DeleteCon } from "../../controllers/schedules/delete_con.js";

const router = Router();

router.delete("/deleteschedule/:id", DeleteCon);

export default router;