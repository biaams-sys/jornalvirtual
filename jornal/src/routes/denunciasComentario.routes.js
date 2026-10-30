const express = require("express");

const router = express.Router();

const {
    denunciar,
    listar,
    buscar,
    excluir
} = require("../controllers/denunciasComentario.controller");

const { validate } = require("../middlewares/auth");
const { validaAdministrador } = require("../middlewares/validaCargo");

router.post("/cadastrar", validate, denunciar);

router.get("/listar", validate, validaAdministrador, listar);

router.get("/buscar/:id", validate, validaAdministrador, buscar);

router.delete("/excluir/:id", validate, validaAdministrador, excluir);

module.exports = router;