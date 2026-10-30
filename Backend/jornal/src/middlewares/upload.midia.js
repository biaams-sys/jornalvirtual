const multer = require("multer");

const validarNomeArquivo = (req, file, callback) => {
  const nome = req.body.nome || "arquivo";

  const nomeFormatado = nome
    .toLowerCase()
    .replaceAll(" ", "-");

  const partes = file.originalname.split(".");
  const ext = partes.length > 1 ? partes.pop() : "jpg";

  const nomeFinal =
    Date.now() +
    "-" +
    nomeFormatado +
    "." +
    ext;

  callback(null, nomeFinal);
};

const definirDestino = (req, file, callback) => {
  callback(null, "uploads/temp");
};

const tiposPermitidos = [
  "image/jpeg",
  "image/png",
  "image/webp",

  "video/mp4",
  "video/webm",
  "video/mkv",

  // Alguns navegadores podem enviar esses MIME types
  "application/octet-stream",
  "application/octet-stream",
];

const filtrarExtensao = (req, file, callback) => {
  const extensao = file.originalname
    .split(".")
    .pop()
    .toLowerCase();

  const extensoesPermitidas = [
    "jpg",
    "jpeg",
    "png",
    "webp",
    "mp4",
    "webm",
    "mkv",
  ];

  if (
    tiposPermitidos.includes(file.mimetype) ||
    extensoesPermitidas.includes(extensao)
  ) {
    callback(null, true);
  } else {
    callback(
      new Error(
        `Arquivo não permitido. Tipo recebido: ${file.mimetype}`
      )
    );
  }
};

const armazenamento = multer.diskStorage({
  destination: definirDestino,
  filename: validarNomeArquivo,
});

const uploadMidia = (req, res, next) => {
  const filemulter = multer({
    storage: armazenamento,
    fileFilter: filtrarExtensao,
    limits: {
      fileSize: 50 * 1024 * 1024,
    },
  });

  filemulter.single("arquivo")(
    req,
    res,
    function (erro) {
      if (erro) {
        return res.status(400).json({
          erro: erro.message,
        });
      }

      if (!req.file) {
        return res.status(400).json({
          erro: "Arquivo não enviado",
        });
      }

      next();
    }
  );
};

module.exports = uploadMidia;