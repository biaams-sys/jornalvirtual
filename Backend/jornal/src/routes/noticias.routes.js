const express = require("express");
const router = express.Router();

const {
    cadastrar,
    listar,
    buscar,
    atualizar,
    excluir
} = require("../controllers/noticias.controller");

const { validate } = require("../middlewares/auth");

router.post("/cadastrar", validate, cadastrar);

router.get("/listar", validate, listar);

router.get("/buscar/:id", validate, buscar);

router.put("/atualizar/:id", validate, atualizar);

router.delete("/excluir/:id", validate, excluir);

module.exports = router;