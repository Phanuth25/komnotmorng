import { Router } from "express";
import { LoginCon } from "../../controllers/users/login_con.js";

const router = Router();

router.post("/login", LoginCon);

export default router;
