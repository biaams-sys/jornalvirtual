const prisma = require("../data/prisma");
const fs = require("fs");

const buscar = async (req, res) => {
    try {
        const servico = req.params.servico;
        const id = parseInt(req.params.id);

        //localhost:3000/midia/usuario/1

        let midia = "";

        if (servico == "usuario") {
            midia = await prisma.usuario.findUnique({
                where: { id },
            });

        } else if (servico == "publicacao") {
            midia = await prisma.midiasPublicacoes.findUnique({
                where: { id },
            });
        } else if (servico == "noticia") {
            midia = await prisma.midiasNoticias.findUnique({
                where: { id },
            });
        }
        // }else if(servico == "template"){
        //     midia = await prisma.midiasTemplates.findUnique({
        //         where: { id },
        //     });
        // }


        if (!midia) {
            return res.status(404).json({ erro: "Arquivo não encontrado" });
        }

        if (!fs.existsSync(midia.path)) {
            return res.status(404).json({ erro: "Arquivo não encontrado no servidor" });
        }

        if (servico == "usuario") {
            res.sendFile(midia.fotoPerfil, { root: "." });
        } else {
            res.sendFile(midia.path, { root: "." });
        }
    } catch (erro) {
        return res.status(500).json({ erro: "Erro ao buscar arquivo" });
    }
};

module.exports = {
    buscar,
}
// const cadastrar = async (req, res) => {
//   try {
//     const idPublicacao = parseInt(req.params.id);
//     const arquivo = req.file;

//     const pastaFinal = `uploads/publicacoes/${idPublicacao}`;
//     const caminhoFinal = `${pastaFinal}/${arquivo.filename}`;

//     if (!fs.existsSync(pastaFinal)) {
//       fs.mkdirSync(pastaFinal, { recursive: true });
//     }

//     fs.renameSync(arquivo.path, caminhoFinal);

//     const midia = await prisma.midia.create({
//       data: {
//         nomeOriginal: arquivo.originalname,
//         nomeArquivo: arquivo.filename,
//         mimeType: arquivo.mimetype,
//         path: caminhoFinal,
//         noticiasId: idPublicacao
//       },
//     });

//     res.status(201).json(midia);
//   } catch (error) {
//     if (req.file && fs.existsSync(req.file.path)) {
//       fs.unlinkSync(req.file.path);
//     }
//     res.status(500).json({ error: error.message });
//   }
// };

// const listar = async (req, res) => {
//   const lista = await prisma.midia.findMany();
//   res.status(200).json(lista);
// };

// const atualizar = async (req, res) => {
//   const { id } = req.params;
//   const dados = req.body;

//   const item = await prisma.midia.update({
//     where: { id: Number(id) },
//     data: dados,
//   });

//   res.status(200).json(item);
// };

// const excluir = async (req, res) => {
//   const { id } = req.params;

//   const item = await prisma.midia.delete({
//     where: { id: Number(id) },
//   });

//   res.status(200).json(item);
// };

// module.exports = {
//   cadastrar,
//   listar,
//   buscar,
//   atualizar,
//   excluir,
// };