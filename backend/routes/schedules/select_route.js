import { Router } from "express";
import { SelectCon } from "../../controllers/schedules/select_con.js";

const router = Router();

router.get("/selectallsche/:user_id", SelectCon);

export default router;
