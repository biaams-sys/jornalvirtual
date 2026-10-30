const prisma = require("../data/prisma");
const fs = require("fs");

const cadastrar = async (req, res) => {
    try {

        const publicacaoId = Number(req.params.id);
        const arquivo = req.file;

        const publicacao = await prisma.publicacoes.findFirst({
            where: {
                id: publicacaoId,
                empresaId: req.user.empresaId
            }
        });

        if (!publicacao) {
            return res.status(404).json({
                mensagem: "Publicação não encontrada"
            });
        }

        if (
            publicacao.usuarioId !== req.user.id &&
            req.user.tipo !== "ADMINISTRADOR"
        ) {
            return res.status(403).json({
                mensagem: "Sem permissão para adicionar mídia"
            });
        }

        const pastaFinal = `uploads/publicacoes/${publicacaoId}`;
        const caminhoFinal = `${pastaFinal}/${arquivo.filename}`;

        if (!fs.existsSync(pastaFinal)) {
            fs.mkdirSync(pastaFinal, { recursive: true });
        }

        fs.renameSync(arquivo.path, caminhoFinal);

        const midia = await prisma.midiasPublicacoes.create({
            data: {
                nomeOriginal: arquivo.originalname,
                nomeArquivo: arquivo.filename,
                mimeType: arquivo.mimetype,
                path: caminhoFinal,
                publicacaoId
            }
        });

        return res.status(201).json(midia);

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

        const lista = await prisma.midiasPublicacoes.findMany({
            where: {
                publicacao: {
                    empresaId: req.user.empresaId
                }
            },
            include: {
                publicacao: true
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

//         const midia = await prisma.midiasPublicacoes.findFirst({
//             where: {
//                 id,
//                 publicacao: {
//                     empresaId: req.user.empresaId
//                 }
//             },
//             include: {
//                 publicacao: true
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

    const midia = await prisma.midiasPublicacoes.findUnique({
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

        const midia = await prisma.midiasPublicacoes.findFirst({
            where: {
                id,
                publicacao: {
                    empresaId: req.user.empresaId
                }
            },
            include: {
                publicacao: true
            }
        });

        if (!midia) {
            return res.status(404).json({
                mensagem: "Mídia não encontrada"
            });
        }

        if (
            midia.publicacao.usuarioId !== req.user.id &&
            req.user.tipo !== "ADMINISTRADOR"
        ) {
            return res.status(403).json({
                mensagem: "Sem permissão para excluir esta mídia"
            });
        }

        if (fs.existsSync(midia.path)) {
            fs.unlinkSync(midia.path);
        }

        await prisma.midiasPublicacoes.delete({
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