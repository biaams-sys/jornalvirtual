const express = require("express");
const router = express.Router();

const controller = require("../controllers/midiasPublicacoes.controller");
const { validate } = require("../middlewares/auth");
const storageController = require("../controllers/storage.controller");

router.get("/listar", validate, controller.listar);

router.get("/buscar/:id", validate, controller.buscar);

router.delete("/excluir/:id", validate, controller.excluir);

router.post(
    "/autorizar-upload/:id",
    validate,
    storageController.autorizarUploadPublicacao
);

router.post(
    "/confirmar-upload/:id",
    validate,
    storageController.confirmarUploadPublicacao
);

module.exports = router;