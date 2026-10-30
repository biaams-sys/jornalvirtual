const express = require("express");
const router = express.Router();

const controller = require("../controllers/midiasPublicacoes.controller");
const uploadMidia = require("../middlewares/upload.midia");
const { validate } = require("../middlewares/auth");

router.post("/cadastrar/:id", validate, uploadMidia, controller.cadastrar);

router.get("/listar", validate, controller.listar);

router.get("/buscar/:id", validate, controller.buscar);

router.delete("/excluir/:id", validate, controller.excluir);

module.exports = router;