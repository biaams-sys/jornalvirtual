const prisma = require("../data/prisma");

const cadastrar = async (req, res) => {
    try {

        const { texto } = req.body;
        const usuarioId = req.user.id;
        const empresaId = req.user.empresaId;

        if (!texto || texto.trim() === "") {
            return res.status(400).json({
                mensagem: "Publicação vazia"
            });
        }

        const publicacao = await prisma.publicacoes.create({
            data: {
                texto: texto.trim(),
                usuarioId,
                empresaId
            }
        });

        // Encontra as hashtags dentro do texto
        const hashtagsEncontradas = texto.match(/#[a-zA-ZÀ-ÿ0-9_]+/g) || [];

        // Remove hashtags repetidas
        const hashtagsUnicas = [
            ...new Set(
                hashtagsEncontradas.map(
                    hashtag => hashtag.toLowerCase()
                )
            )
        ];

        for (const nome of hashtagsUnicas) {

            let tag = await prisma.hashtags.findFirst({
                where: {
                    nome,
                    empresaId
                }
            });

            if (!tag) {
                tag = await prisma.hashtags.create({
                    data: {
                        nome,
                        empresaId
                    }
                });
            }

            await prisma.publicacoes.update({
                where: {
                    id: publicacao.id
                },
                data: {
                    hashtags: {
                        connect: {
                            id: tag.id
                        }
                    }
                }
            });
        }

        return res.status(201).json({
            mensagem: "Publicação criada com sucesso.",
            publicacao
        });

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao criar publicação.",
            erro: erro.message
        });

    }
};

const listar = async (req, res) => {
    try {

        const lista = await prisma.publicacoes.findMany({

            where: {
                empresaId: req.user.empresaId
            },

            orderBy: {
                dataPublicacao: "desc"
            },

            include: {

                empresa: {
                    select: {
                        id: true,
                        nome: true,
                        logo: true
                    }
                },

                autor: {
                    select: {
                        id: true,
                        nome: true,
                        fotoPerfil: true,
                        tipo: true
                    }
                },

                hashtags: true,

                comentarios: {
                    include: {
                        autor: {
                            select: {
                                id: true,
                                nome: true,
                                fotoPerfil: true
                            }
                        }
                    }
                },

                curtidas: true,

                denuncias: true,

                midias: true

            }

        });

        return res.status(200).json(lista);

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao listar publicações.",
            erro: erro.message
        });

    }
};

const buscar = async (req, res) => {
    try {

        const id = Number(req.params.id);

        const publicacao = await prisma.publicacoes.findFirst({

            where: {
                id,
                empresaId: req.user.empresaId
            },

            include: {

                empresa: {
                    select: {
                        id: true,
                        nome: true,
                        logo: true
                    }
                },

                autor: {
                    select: {
                        id: true,
                        nome: true,
                        fotoPerfil: true,
                        tipo: true
                    }
                },

                hashtags: true,

                comentarios: {
                    include: {
                        autor: {
                            select: {
                                id: true,
                                nome: true,
                                fotoPerfil: true
                            }
                        }
                    }
                },

                curtidas: true,

                denuncias: true,

                midias: true

            }

        });

        if (!publicacao) {
            return res.status(404).json({
                mensagem: "Publicação não encontrada."
            });
        }

        return res.status(200).json(publicacao);

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao buscar publicação.",
            erro: erro.message
        });

    }
};

const atualizar = async (req, res) => {
    try {

        const id = Number(req.params.id);
        const { texto } = req.body;

        const publicacao = await prisma.publicacoes.findFirst({

            where: {
                id,
                empresaId: req.user.empresaId
            }

        });

        if (!publicacao) {

            return res.status(404).json({
                mensagem: "Publicação não encontrada."
            });

        }

        if (
            req.user.id !== publicacao.usuarioId &&
            req.user.tipo !== "ADMINISTRADOR"
        ) {

            return res.status(403).json({
                mensagem: "Sem permissão."
            });

        }

        const atualizada = await prisma.publicacoes.update({

            where: {
                id
            },

            data: {
                texto
            }

        });

        return res.status(200).json({
            mensagem: "Publicação atualizada com sucesso.",
            publicacao: atualizada
        });

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao atualizar publicação.",
            erro: erro.message
        });

    }
};

const excluir = async (req, res) => {
    try {

        const id = Number(req.params.id);

        const publicacao = await prisma.publicacoes.findFirst({

            where: {
                id,
                empresaId: req.user.empresaId
            }

        });

        if (!publicacao) {

            return res.status(404).json({
                mensagem: "Publicação não encontrada."
            });

        }

        if (
            req.user.id !== publicacao.usuarioId &&
            req.user.tipo !== "ADMINISTRADOR"
        ) {

            return res.status(403).json({
                mensagem: "Sem permissão."
            });

        }

        await prisma.publicacoes.delete({
            where: {
                id
            }
        });

        return res.status(200).json({
            mensagem: "Publicação excluída com sucesso."
        });

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao excluir publicação.",
            erro: erro.message
        });

    }
};

const listarPorUsuario = async (req, res) => {
    try {

        const id = Number(req.params.id);

        const usuario = await prisma.usuarios.findFirst({

            where: {
                id,
                empresaId: req.user.empresaId
            }

        });

        if (!usuario) {

            return res.status(404).json({
                mensagem: "Usuário não encontrado."
            });

        }

        const lista = await prisma.publicacoes.findMany({

            where: {
                usuarioId: id,
                empresaId: req.user.empresaId
            },

            include: {

                hashtags: true,

                midias: true

            },

            orderBy: {
                dataPublicacao: "desc"
            }

        });

        return res.status(200).json(lista);

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao listar publicações do usuário.",
            erro: erro.message
        });

    }
};

module.exports = {
    cadastrar,
    listar,
    buscar,
    atualizar,
    excluir,
    listarPorUsuario
};