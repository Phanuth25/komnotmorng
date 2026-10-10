import { Router } from "express";
import { RegisterCon } from "../../controllers/users/register_con.js";

const router = Router();

router.post("/register", RegisterCon);

export default router;
