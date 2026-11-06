const prisma = require("../data/prisma");
const supabase = require("../data/supabase");

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

const buscar = async (req, res) => {
    try {
        const id = Number(req.params.id);

        const midia = await prisma.midiasNoticias.findFirst({
            where: {
                id,
                noticia: {
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

        if (midia.path && !midia.path.startsWith("uploads/")) {
            const caminho = midia.path.startsWith("midias/")
                ? midia.path.substring("midias/".length)
                : midia.path;

            const { error } = await supabase.storage
                .from("midias")
                .remove([caminho]);

            if (error) throw error;
        }

        await prisma.midiasNoticias.delete({
            where: { id }
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
    listar,
    buscar,
    excluir
};