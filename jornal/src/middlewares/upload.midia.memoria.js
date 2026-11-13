const multer = require("multer");

const tiposValidos = [
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp",
    "image/heic",
    "image/heif"
];

const extensoesValidas = [
    "jpg",
    "jpeg",
    "png",
    "webp",
    "heic",
    "heif"
];

const upload = multer({
    storage: multer.memoryStorage(),
    fileFilter: (req, file, callback) => {
        const extensao = file.originalname.split(".").pop().toLowerCase();
        
        const mimetypeValido = tiposValidos.includes(file.mimetype);
        const extensaoValida = extensoesValidas.includes(extensao);

        if (mimetypeValido || extensaoValida) {
            callback(null, true);
        } else {
            callback(new Error("Formato de imagem inválido. Envie JPG, PNG, WEBP ou HEIC."));
        }
    },
    limits: {
        fileSize: 10 * 1024 * 1024 // 10MB
    }
}).single("arquivo");

module.exports = (req, res, next) => {
    upload(req, res, (erro) => {
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