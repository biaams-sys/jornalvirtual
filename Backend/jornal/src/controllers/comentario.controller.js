const prisma = require("../data/prisma");


const cadastrar = async (req, res) => {
    try {

        const usuarioId = req.user.id;
        const empresaId = req.user.empresaId;

        const { publicacaoId, texto, comentarioPaiId } = req.body;

        if (!publicacaoId || !texto) {
            return res.status(400).json({
                mensagem: "publicacaoId e texto são obrigatórios"
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

        if (comentarioPaiId) {

            const comentarioPai = await prisma.comentarios.findUnique({
                where: {
                    id: Number(comentarioPaiId)
                }
            });

            if (!comentarioPai) {
                return res.status(404).json({
                    mensagem: "Comentário pai não encontrado"
                });
            }
        }

        const comentario = await prisma.comentarios.create({
            data: {
                texto,
                usuarioId,
                publicacaoId: Number(publicacaoId),
                comentarioPaiId: comentarioPaiId
                    ? Number(comentarioPaiId)
                    : null
            }
        });

        return res.status(201).json({
            mensagem: "Comentário criado com sucesso",
            comentario
        });

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao criar comentário",
            erro: erro.message
        });

    }
};


const listarPorPublicacao = async (req, res) => {
    try {

        const empresaId = req.user.empresaId;
        const publicacaoId = Number(req.params.publicacaoId);

        const publicacao = await prisma.publicacoes.findFirst({
            where: {
                id: publicacaoId,
                empresaId
            }
        });

        if (!publicacao) {
            return res.status(404).json({
                mensagem: "Publicação não encontrada"
            });
        }

        const comentarios = await prisma.comentarios.findMany({
            where: {
                publicacaoId,
                comentarioPaiId: null
            },
            include: {
                autor: {
                    select: {
                        id: true,
                        nome: true,
                        fotoPerfil: true,
                        tipo: true
                    }
                },
                respostas: {
                    include: {
                        autor: {
                            select: {
                                id: true,
                                nome: true,
                                fotoPerfil: true,
                                tipo: true
                            }
                        }
                    },
                    orderBy: {
                        dataPublicacao: "asc"
                    }
                }
            },
            orderBy: {
                dataPublicacao: "desc"
            }
        });

        return res.status(200).json(comentarios);

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao listar comentários",
            erro: erro.message
        });

    }
};


const buscar = async (req, res) => {
    try {

        const empresaId = req.user.empresaId;
        const id = Number(req.params.id);

        const comentario = await prisma.comentarios.findUnique({
            where: {
                id
            },
            include: {
                autor: true,
                publicacao: true,
                respostas: {
                    include: {
                        autor: true
                    }
                }
            }
        });

        if (!comentario || comentario.publicacao.empresaId !== empresaId) {
            return res.status(404).json({
                mensagem: "Comentário não encontrado"
            });
        }

        return res.status(200).json(comentario);

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao buscar comentário",
            erro: erro.message
        });

    }
};


const excluir = async (req, res) => {
    try {

        const empresaId = req.user.empresaId;
        const usuario = req.user;
        const id = Number(req.params.id);

        const comentario = await prisma.comentarios.findUnique({
            where: {
                id
            },
            include: {
                publicacao: true
            }
        });

        if (!comentario || comentario.publicacao.empresaId !== empresaId) {
            return res.status(404).json({
                mensagem: "Comentário não encontrado"
            });
        }

        if (
            usuario.tipo !== "ADMINISTRADOR" &&
            comentario.usuarioId !== usuario.id
        ) {
            return res.status(403).json({
                mensagem: "Você não possui permissão para excluir este comentário"
            });
        }

        await prisma.comentarios.delete({
            where: {
                id
            }
        });

        return res.status(200).json({
            mensagem: "Comentário excluído com sucesso"
        });

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao excluir comentário",
            erro: erro.message
        });

    }
};

module.exports = {
    cadastrar,
    listarPorPublicacao,
    buscar,
    excluir
};