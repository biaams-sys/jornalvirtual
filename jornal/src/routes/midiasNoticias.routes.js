const express = require("express");
const router = express.Router();

const controller = require("../controllers/midiasNoticias.controller");
const { validate } = require("../middlewares/auth");
const storageController = require("../controllers/storage.controller");

router.get("/listar", validate, controller.listar);

router.get("/buscar/:id", validate, controller.buscar);

router.delete("/excluir/:id", validate, controller.excluir);

router.post(
    "/autorizar-upload/:id",
    validate,
    storageController.autorizarUploadNoticia
);

router.post(
    "/confirmar-upload/:id",
    validate,
    storageController.confirmarUploadNoticia
);

module.exports = router;