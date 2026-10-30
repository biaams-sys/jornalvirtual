const express = require("express");
const router = express.Router();

const {
    cadastrar,
    listar,
    buscar,
    excluir
} = require("../controllers/midiasNoticias.controller");

const uploadMidia = require("../middlewares/upload.midia");
const { validate } = require("../middlewares/auth");

router.post("/cadastrar/:id", validate, uploadMidia, cadastrar);

router.get("/listar", validate, listar);

router.get("/buscar/:id", validate, buscar);

router.delete("/excluir/:id", validate, excluir);

module.exports = router;