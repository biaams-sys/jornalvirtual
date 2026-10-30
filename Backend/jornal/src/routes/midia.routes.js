const express = require("express");
const router = express.Router();

const controller = require("../controllers/midia.controller");
const uploadMidia = require("../middlewares/upload.midia");
const { validate } = require("../middlewares/auth");

//router.post("/:id", validate, uploadMidia, controller.cadastrar);

//router.get("/", validate, controller.listar);

router.get("/:servico/:id", validate, controller.buscar);

//router.delete("/:id", validate, controller.excluir);

module.exports = router;