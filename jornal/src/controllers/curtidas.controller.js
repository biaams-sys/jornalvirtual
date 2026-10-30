const prisma = require("../data/prisma");

const curtir = async (req, res) => {
    try {

        const usuarioId = req.user.id;
        const empresaId = req.user.empresaId;
        const { publicacaoId } = req.body;

        if (!publicacaoId) {
            return res.status(400).json({
                mensagem: "publicacaoId obrigatório"
            });
        }

        const publicacao = await prisma.publicacoes.findFirst({
            where: {
                id: Number(publicacaoId),
                empresaId
            }
        });

        if (!publicacao) {
            return res.status(404).json({
                mensagem: "Publicação não encontrada"
            });
        }

        const jaCurtiu = await prisma.curtidas.findFirst({
            where: {
                usuarioId,
                publicacaoId: Number(publicacaoId)
            }
        });

        if (jaCurtiu) {
            return res.status(400).json({
                mensagem: "Você já curtiu essa publicação"
            });
        }

        const curtida = await prisma.curtidas.create({
            data: {
                usuarioId,
                publicacaoId: Number(publicacaoId)
            }
        });

        return res.status(201).json({
            mensagem: "Curtida realizada com sucesso",
            curtida
        });

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao curtir publicação",
            erro: erro.message
        });

    }
};

const descurtir = async (req, res) => {
    try {

        const usuarioId = req.user.id;
        const empresaId = req.user.empresaId;
        const { publicacaoId } = req.body;

        if (!publicacaoId) {
            return res.status(400).json({
                mensagem: "publicacaoId obrigatório"
            });
        }

        const publicacao = await prisma.publicacoes.findFirst({
            where: {
                id: Number(publicacaoId),
                empresaId
            }
        });

        if (!publicacao) {
            return res.status(404).json({
                mensagem: "Publicação não encontrada"
            });
        }

        const curtida = await prisma.curtidas.findFirst({
            where: {
                usuarioId,
                publicacaoId: Number(publicacaoId)
            }
        });

        if (!curtida) {
            return res.status(404).json({
                mensagem: "Curtida não encontrada"
            });
        }

        await prisma.curtidas.delete({
            where: {
                id: curtida.id
            }
        });

        return res.status(200).json({
            mensagem: "Curtida removida com sucesso"
        });

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao remover curtida",
            erro: erro.message
        });

    }
};

const contarCurtidas = async (req, res) => {
    try {

        const empresaId = req.user.empresaId;
        const { publicacaoId } = req.params;

        const publicacao = await prisma.publicacoes.findFirst({
            where: {
                id: Number(publicacaoId),
                empresaId
            }
        });

        if (!publicacao) {
            return res.status(404).json({
                mensagem: "Publicação não encontrada"
            });
        }

        const totalCurtidas = await prisma.curtidas.count({
            where: {
                publicacaoId: Number(publicacaoId)
            }
        });

        return res.status(200).json({
            publicacaoId: Number(publicacaoId),
            curtidas: totalCurtidas
        });

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao contar curtidas",
            erro: erro.message
        });

    }
};

module.exports = {
    curtir,
    descurtir,
    contarCurtidas
};