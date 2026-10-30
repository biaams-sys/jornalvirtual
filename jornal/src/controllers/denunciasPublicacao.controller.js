const prisma = require("../data/prisma");

const denunciar = async (req, res) => {
    try {

        const { publicacaoId, motivo } = req.body;

        if (!publicacaoId || !motivo) {
            return res.status(400).json({
                mensagem: "Publicação e motivo são obrigatórios"
            });
        }

        const publicacao = await prisma.publicacoes.findFirst({
            where: {
                id: Number(publicacaoId),
                empresaId: req.user.empresaId
            }
        });

        if (!publicacao) {
            return res.status(404).json({
                mensagem: "Publicação não encontrada"
            });
        }

        const denunciaExistente = await prisma.denunciasPublicacao.findFirst({
            where: {
                usuarioId: req.user.id,
                publicacaoId: Number(publicacaoId)
            }
        });

        if (denunciaExistente) {
            return res.status(400).json({
                mensagem: "Você já denunciou esta publicação"
            });
        }

        const denuncia = await prisma.denunciasPublicacao.create({
            data: {
                motivo,
                usuarioId: req.user.id,
                publicacaoId: Number(publicacaoId)
            }
        });

        return res.status(201).json({
            mensagem: "Publicação denunciada com sucesso",
            denuncia
        });

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao denunciar publicação",
            erro: erro.message
        });

    }
};

const listar = async (req, res) => {
    try {

        if (req.user.tipo !== "ADMINISTRADOR") {
            return res.status(403).json({
                mensagem: "Usuário sem permissão"
            });
        }

        const denuncias = await prisma.denunciasPublicacao.findMany({
            where: {
                publicacao: {
                    empresaId: req.user.empresaId
                }
            },
            orderBy: {
                dataDenuncia: "desc"
            },
            include: {
                usuario: {
                    select: {
                        id: true,
                        nome: true,
                        email: true
                    }
                },
                publicacao: true
            }
        });

        return res.status(200).json(denuncias);

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao listar denúncias",
            erro: erro.message
        });

    }
};

const buscar = async (req, res) => {
    try {

        if (req.user.tipo !== "ADMINISTRADOR") {
            return res.status(403).json({
                mensagem: "Usuário sem permissão"
            });
        }

        const id = Number(req.params.id);

        const denuncia = await prisma.denunciasPublicacao.findFirst({
            where: {
                id,
                publicacao: {
                    empresaId: req.user.empresaId
                }
            },
            include: {
                usuario: true,
                publicacao: true
            }
        });

        if (!denuncia) {
            return res.status(404).json({
                mensagem: "Denúncia não encontrada"
            });
        }

        return res.status(200).json(denuncia);

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao buscar denúncia",
            erro: erro.message
        });

    }
};

const excluir = async (req, res) => {
    try {

        if (req.user.tipo !== "ADMINISTRADOR") {
            return res.status(403).json({
                mensagem: "Usuário sem permissão"
            });
        }

        const id = Number(req.params.id);

        const denuncia = await prisma.denunciasPublicacao.findFirst({
            where: {
                id,
                publicacao: {
                    empresaId: req.user.empresaId
                }
            }
        });

        if (!denuncia) {
            return res.status(404).json({
                mensagem: "Denúncia não encontrada"
            });
        }

        await prisma.denunciasPublicacao.delete({
            where: {
                id
            }
        });

        return res.status(200).json({
            mensagem: "Denúncia excluída com sucesso"
        });

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao excluir denúncia",
            erro: erro.message
        });

    }
};

module.exports = {
    denunciar,
    listar,
    buscar,
    excluir
};