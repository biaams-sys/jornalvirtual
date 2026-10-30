
const express = require("express");

const router = express.Router();

const {
    Login,
    cadastrar,
    listar,
    buscar,
    atualizar,
    excluir,
    pesquisar,
    fotoPerfil,
    atualizarTemplate,
    esqueciSenha,
    redefinirSenha
} = require("../controllers/usuarios.controller");

const { validate } = require("../middlewares/auth");
const { validaAdministrador } = require("../middlewares/validaCargo");
const uploadMidia = require("../middlewares/upload.midia");
const controller = require("../controllers/usuarios.controller");

router.post("/login", Login);
router.post("/esqueci-senha", esqueciSenha);
router.post("/redefinir-senha", redefinirSenha);
router.post("/cadastrar", validate, validaAdministrador, cadastrar);
router.get("/listar", validate, listar);
router.put("/atualizar/:id", validate, atualizar);
router.get("/buscar/:id", validate, buscar);
router.post("/template/:id", validate, uploadMidia, controller.atualizarTemplate);
router.delete("/excluir/:id", validate, excluir);
router.get("/pesquisar", validate, pesquisar);
router.post("/foto-perfil", validate, uploadMidia, fotoPerfil);
router.put("/template/:id", validate, uploadMidia, controller.atualizarTemplate);

module.exports = router;
