const express = require("express");
const router = express.Router();

const controller = require("../controllers/midiasPublicacoes.controller");
const upload = require("../middlewares/upload.midia");
const { validate } = require("../middlewares/auth");

router.post("/:id", validate, upload, controller.cadastrar);

router.get("/", validate, controller.listar);

router.delete("/:id", validate, controller.excluir);

module.exports = router;