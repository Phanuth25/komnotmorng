import { Router } from "express";
import { SelectCateCon } from "../../controllers/categories/select_cate_con.js";

const router = Router();

router.get("/selectallcate", SelectCateCon);

export default router;
