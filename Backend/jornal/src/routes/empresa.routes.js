const express = require("express");
const router = express.Router();

const {
    listar,
    buscar,
    atualizar,
    excluir,
    cadastrar
} = require("../controllers/empresa.controller");

const { validate } = require("../middlewares/auth");
const { validaAdministrador } = require("../middlewares/validaCargo");

router.post("/cadastrar", validate, validaAdministrador, cadastrar);

router.get("/listar", validate, validaAdministrador, listar);

router.get("/buscar/:id", validate, validaAdministrador, buscar);

router.put("/atualizar/:id", validate, validaAdministrador, atualizar);

router.delete("/excluir/:id", validate, validaAdministrador, excluir);

module.exports = router;