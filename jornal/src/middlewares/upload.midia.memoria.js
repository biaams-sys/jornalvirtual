
const multer = require("multer");

const tiposPermitidos = [
    "image/jpeg",
    "image/png",
    "image/webp"
];

const extensoesPermitidas = [
    "jpg",
    "jpeg",
    "png",
    "webp"
];

const filtrarExtensao = (req, file, callback) => {
    const extensao = file.originalname
        .split(".")
        .pop()
        .toLowerCase();

    if (
        tiposPermitidos.includes(file.mimetype) &&
        extensoesPermitidas.includes(extensao)
    ) {
        callback(null, true);
    } else {
        callback(
            new Error("Envie uma imagem JPG, JPEG, PNG ou WEBP.")
        );
    }
};

const uploadMidia = multer({
    storage: multer.memoryStorage(),
    fileFilter: filtrarExtensao,
    limits: {
        fileSize: 10 * 1024 * 1024
    }
}).single("arquivo");

module.exports = (req, res, next) => {
    uploadMidia(req, res, (erro) => {
        if (erro) {
            return res.status(400).json({
                erro: erro.message
            });
        }

        if (!req.file) {
            return res.status(400).json({
                erro: "Arquivo não enviado."
            });
        }

        next();
    });
};
