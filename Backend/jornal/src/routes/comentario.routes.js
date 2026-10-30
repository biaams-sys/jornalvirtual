const express = require("express");
const router = express.Router();

const {
    cadastrar,
    listarPorPublicacao,
    buscar,
    excluir
} = require("../controllers/comentario.controller");

const { validate } = require("../middlewares/auth");
const { validarExclusaoComentario } = require("../middlewares/comentarios.middlewares");

router.post("/cadastrar", validate, cadastrar);
router.get("/publicacao/:publicacaoId", validate, listarPorPublicacao);
router.get("/:id", validate, buscar);

router.delete("/:id", validate, validarExclusaoComentario, excluir);

module.exports = router;