const express = require("express");
const router = express.Router();

const {
    listar,
    ranking,
    buscarPorNome,
    listarPublicacoes
} = require("../controllers/hashtags.controller");

const { validate } = require("../middlewares/auth");

router.get("/listar", validate, listar);

router.get("/ranking", validate, ranking);

router.get("/nome/:nome", validate, buscarPorNome);

router.get("/publicacoes/:nome", validate, listarPublicacoes);

module.exports = router;