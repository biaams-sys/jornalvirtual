const express = require("express");

const router = express.Router();

const {
    cadastrar,
    listar,
    buscar,
    atualizar,
    excluir,
    listarPorUsuario
} = require("../controllers/publicacoes.controller");

const { validate } = require("../middlewares/auth");

router.post("/cadastrar", validate, cadastrar);
router.get("/listar", validate, listar);
router.get("/buscar/:id", validate, buscar);
router.put("/atualizar/:id", validate, atualizar);
router.delete("/excluir/:id", validate, excluir);
router.get("/usuario/:id", validate, listarPorUsuario);

module.exports = router;