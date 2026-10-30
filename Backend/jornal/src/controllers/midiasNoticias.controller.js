const prisma = require("../data/prisma");
const fs = require("fs");

const cadastrar = async (req, res) => {
    try {

        const noticiaId = Number(req.params.id);
        const arquivo = req.file;
        const usuario = req.user;

        const noticia = await prisma.noticias.findFirst({
            where: {
                id: noticiaId,
                empresaId: usuario.empresaId
            }
        });

        if (!noticia) {
            return res.status(404).json({
                mensagem: "Notícia não encontrada"
            });
        }

        if (
            usuario.tipo !== "ADMINISTRADOR" &&
            noticia.usuarioId !== usuario.id
        ) {
            if (fs.existsSync(arquivo.path)) {
                fs.unlinkSync(arquivo.path);
            }

            return res.status(403).json({
                mensagem: "Você não possui permissão para adicionar mídias nesta notícia"
            });
        }

        const pastaFinal = `uploads/noticias/${noticiaId}`;
        const caminhoFinal = `${pastaFinal}/${arquivo.filename}`;

        if (!fs.existsSync(pastaFinal)) {
            fs.mkdirSync(pastaFinal, { recursive: true });
        }

        fs.renameSync(arquivo.path, caminhoFinal);

        const midia = await prisma.midiasNoticias.create({
            data: {
                nomeOriginal: arquivo.originalname,
                nomeArquivo: arquivo.filename,
                mimeType: arquivo.mimetype,
                path: caminhoFinal,
                noticiaId
            }
        });

        return res.status(201).json({
            mensagem: "Mídia adicionada com sucesso",
            midia
        });

    } catch (erro) {

        if (req.file && fs.existsSync(req.file.path)) {
            fs.unlinkSync(req.file.path);
        }

        return res.status(500).json({
            mensagem: "Erro ao cadastrar mídia",
            erro: erro.message
        });

    }
};

const listar = async (req, res) => {
    try {

        const lista = await prisma.midiasNoticias.findMany({
            where: {
                noticia: {
                    empresaId: req.user.empresaId
                }
            },
            include: {
                noticia: true
            }
        });

        return res.status(200).json(lista);

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao listar mídias",
            erro: erro.message
        });

    }
};

// const buscar = async (req, res) => {
//     try {

//         const id = Number(req.params.id);

//         const midia = await prisma.midiasNoticias.findFirst({
//             where: {
//                 id,
//                 noticia: {
//                     empresaId: req.user.empresaId
//                 }
//             },
//             include: {
//                 noticia: true
//             }
//         });

//         if (!midia) {
//             return res.status(404).json({
//                 mensagem: "Mídia não encontrada"
//             });
//         }

//         return res.status(200).json(midia);

//     } catch (erro) {

//         return res.status(500).json({
//             mensagem: "Erro ao buscar mídia",
//             erro: erro.message
//         });

//     }
// };


const buscar = async (req, res) => {
  try {
    const id = Number(req.params.id);

    const midia = await prisma.midiasNoticias.findUnique({
      where: { id },
    });

    if (!midia) {
      return res.status(404).json({ erro: "Arquivo não encontrado" });
    }

    if (!fs.existsSync(midia.path)) {
      return res.status(404).json({ erro: "Arquivo não encontrado no servidor" });
    }

    res.sendFile(midia.path, { root: "." });
  } catch (erro) {
    return res.status(500).json({ erro: "Erro ao buscar arquivo" });
  }
};


const excluir = async (req, res) => {
    try {

        const id = Number(req.params.id);
        const usuario = req.user;

        const midia = await prisma.midiasNoticias.findFirst({
            where: {
                id,
                noticia: {
                    empresaId: usuario.empresaId
                }
            },
            include: {
                noticia: true
            }
        });

        if (!midia) {
            return res.status(404).json({
                mensagem: "Mídia não encontrada"
            });
        }

        if (
            usuario.tipo !== "ADMINISTRADOR" &&
            midia.noticia.usuarioId !== usuario.id
        ) {
            return res.status(403).json({
                mensagem: "Você não possui permissão para excluir esta mídia"
            });
        }

        if (fs.existsSync(midia.path)) {
            fs.unlinkSync(midia.path);
        }

        await prisma.midiasNoticias.delete({
            where: {
                id
            }
        });

        return res.status(200).json({
            mensagem: "Mídia excluída com sucesso"
        });

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao excluir mídia",
            erro: erro.message
        });

    }
};

module.exports = {
    cadastrar,
    listar,
    buscar,
    excluir
};