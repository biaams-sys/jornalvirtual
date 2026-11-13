const multer = require("multer");

const tiposPermitidos = [
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp",
    "image/heic",
    "image/heif"
];

const extensoesPermitidas = [
    "jpg",
    "jpeg",
    "png",
    "webp",
    "heic",
    "heif"
];

const filtrarExtensao = (req, file, callback) => {
    const extensao = file.originalname
        .split(".")
        .pop()
        .toLowerCase();

    if (
        tiposPermitidos.includes(file.mimetype) ||
        extensaoPermitidas.includes(extensao)
    ) {
        callback(null, true);
    } else {
        callback(
            new Error("Formato de imagem inválido. Envie JPG, PNG, WEBP ou HEIC.")
        );
    }
};

const uploadMidia = multer({
    storage: multer.memoryStorage(),
    fileFilter: filtrarExtensao,
    limits: {
        fileSize: 10 * 1024 * 1024 // 10MB
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