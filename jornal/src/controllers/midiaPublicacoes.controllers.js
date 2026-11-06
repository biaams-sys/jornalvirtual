const prisma = require("../data/prisma");
const fs = require("fs");
const supabase = require("../data/supabase");

const cadastrar = async (req, res) => {
    try {

        const publicacaoId = Number(req.params.id);
        const arquivo = req.file;
        const usuario = req.user;

        const publicacao = await prisma.publicacoes.findFirst({
            where: {
                id: publicacaoId,
                empresaId: usuario.empresaId
            }
        });

        if (!publicacao) {
            return res.status(404).json({
                mensagem: "Publicação não encontrada"
            });
        }

        if (
            usuario.tipo !== "ADMINISTRADOR" &&
            publicacao.usuarioId !== usuario.id
        ) {
            if (fs.existsSync(arquivo.path)) {
                fs.unlinkSync(arquivo.path);
            }

            return res.status(403).json({
                mensagem: "Você não possui permissão para adicionar mídias nesta publicação"
            });
        }

        const pasta = `uploads/publicacoes/${publicacaoId}`;
        const caminho = `${pasta}/${arquivo.filename}`;

        if (!fs.existsSync(pasta)) {
            fs.mkdirSync(pasta, { recursive: true });
        }

        fs.renameSync(arquivo.path, caminho);

        const midia = await prisma.midiasPublicacoes.create({
            data: {
                nomeOriginal: arquivo.originalname,
                nomeArquivo: arquivo.filename,
                mimeType: arquivo.mimetype,
                path: caminho,
                publicacaoId
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
            mensagem: "Erro ao cadastrar mídia da publicação",
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

        const midia = await prisma.midiasPublicacoes.findFirst({
            where: {
                id,
                publicacao: {
                    empresaId: req.user.empresaId
                }
            }
        });

        if (!midia) {
            return res.status(404).json({
                mensagem: "Mídia não encontrada"
            });
        }

        const caminho = midia.path.startsWith("midias/")
            ? midia.path.substring("midias/".length)
            : midia.path;

        const { data } = supabase.storage
            .from("midias")
            .getPublicUrl(caminho);

        return res.redirect(data.publicUrl);

    } catch (erro) {
        return res.status(500).json({
            mensagem: "Erro ao buscar mídia",
            erro: erro.message
        });
    }
};

const excluir = async (req, res) => {
    try {
        const id = Number(req.params.id);
        const usuario = req.user;

        const midia = await prisma.midiasPublicacoes.findFirst({
            where: {
                id,
                publicacao: {
                    empresaId: usuario.empresaId
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
            usuario.tipo !== "ADMINISTRADOR" &&
            midia.publicacao.usuarioId !== usuario.id
        ) {
            return res.status(403).json({
                mensagem: "Você não possui permissão para excluir esta mídia"
            });
        }

        const caminho = midia.path.startsWith("midias/")
            ? midia.path.substring("midias/".length)
            : midia.path;

        const { error } = await supabase.storage
            .from("midias")
            .remove([caminho]);

        if (error) {
            throw error;
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