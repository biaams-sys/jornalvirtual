require("dotenv").config();

const express = require("express");
const cors = require("cors");

const app = express();

app.use(express.json());
app.use(cors());
app.use("/uploads", express.static("uploads"));

const usuariosRoutes = require("./src/routes/usuarios.routes");
const publicacoesRoutes = require("./src/routes/publicacoes.routes");
const curtidasRoutes = require("./src/routes/curtidas.routes");
const comentarioRoutes = require("./src/routes/comentario.routes");
const midiasPublicacoesRoutes = require("./src/routes/midiasPublicacoes.routes");
const noticiasRoutes = require("./src/routes/noticias.routes");
const midiasNoticiasRoutes = require("./src/routes/midiasNoticias.routes");
const denunciasPublicacaoRoutes = require("./src/routes/denunciasPublicacao.routes");
const denunciasComentarioRoutes = require("./src/routes/denunciasComentario.routes");
const hashtagsRoutes = require("./src/routes/hashtags.routes");
const empresaRoutes = require("./src/routes/empresa.routes");
const temaRoutes = require("./src/routes/tema.routes");

const midiaRoutes = require("./src/routes/midia.routes");

app.use("/usuarios", usuariosRoutes);
app.use("/publicacoes", publicacoesRoutes);
app.use("/curtidas", curtidasRoutes);
app.use("/comentarios", comentarioRoutes);
app.use("/midias-publicacoes", midiasPublicacoesRoutes);
app.use("/noticias", noticiasRoutes);
app.use("/midias-noticias", midiasNoticiasRoutes);
app.use("/denuncias-publicacao", denunciasPublicacaoRoutes);
app.use("/denuncias-comentario", denunciasComentarioRoutes);
app.use("/hashtags", hashtagsRoutes);
app.use("/empresa", empresaRoutes);
app.use("/tema", temaRoutes);

app.use("/midia", midiaRoutes);

app.listen(3000, () => {
    console.log("Servidor rodando na porta 3000");
});