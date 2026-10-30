const prisma = require("../data/prisma");

const listar = async (req, res) => {
    try {

        const hashtags = await prisma.hashtags.findMany({
            where: {
                empresaId: req.user.empresaId
            },
            orderBy: {
                nome: "asc"
            }
        });

        return res.status(200).json(hashtags);

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao listar hashtags",
            erro: erro.message
        });

    }
};

const buscarPorNome = async (req, res) => {
    try {

        const { nome } = req.params;

        const nomeFormatado = nome.startsWith("#")
            ? nome
            : `#${nome}`;

        const hashtag = await prisma.hashtags.findFirst({
            where: {
                nome: nomeFormatado,
                empresaId: req.user.empresaId
            }
        });

        if (!hashtag) {
            return res.status(404).json({
                mensagem: "Hashtag não encontrada"
            });
        }

        return res.status(200).json(hashtag);

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao buscar hashtag",
            erro: erro.message
        });

    }
};

const listarPublicacoes = async (req, res) => {
    try {

        const { nome } = req.params;

        const nomeFormatado = nome.startsWith("#")
            ? nome
            : `#${nome}`;

        const hashtag = await prisma.hashtags.findFirst({
            where: {
                nome: nomeFormatado,
                empresaId: req.user.empresaId
            },
            include: {
                publicacoes: {
                    where: {
                        empresaId: req.user.empresaId
                    },
                    include: {
                        autor: {
                            select: {
                                id: true,
                                nome: true,
                                fotoPerfil: true
                            }
                        },
                        hashtags: true,
                        midias: true,
                        curtidas: true,
                        comentarios: true
                    }
                }
            }
        });

        if (!hashtag) {
            return res.status(404).json({
                mensagem: "Hashtag não encontrada"
            });
        }

        return res.status(200).json(hashtag.publicacoes);

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao listar publicações da hashtag",
            erro: erro.message
        });

    }
};

const ranking = async (req, res) => {
    try {

        const hashtags = await prisma.hashtags.findMany({
            where: {
                empresaId: req.user.empresaId
            },
            include: {
                publicacoes: {
                    where: {
                        empresaId: req.user.empresaId
                    }
                }
            }
        });

        const ranking = hashtags
            .map(item => ({
                id: item.id,
                nome: item.nome,
                quantidadePublicacoes: item.publicacoes.length
            }))
            .sort((a, b) =>
                b.quantidadePublicacoes - a.quantidadePublicacoes
            );

        return res.status(200).json(ranking);

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao gerar ranking de hashtags",
            erro: erro.message
        });

    }
};

module.exports = {
    listar,
    buscarPorNome,
    listarPublicacoes,
    ranking
};