const prisma = require("../data/prisma");

const cadastrar = async (req, res) => {
    try {

        const { titulo, subtitulo, texto } = req.body;

        if (
            req.user.tipo !== "VERIFICADO" &&
            req.user.tipo !== "ADMINISTRADOR"
        ) {
            return res.status(403).json({
                mensagem: "Usuário sem permissão para criar notícias"
            });
        }

        if (!titulo || !texto) {
            return res.status(400).json({
                mensagem: "Título e texto são obrigatórios"
            });
        }

        const noticia = await prisma.noticias.create({
            data: {
                titulo,
                subtitulo,
                texto,
                usuarioId: req.user.id,
                empresaId: req.user.empresaId
            }
        });

        return res.status(201).json({
            mensagem: "Notícia criada com sucesso",
            noticia
        });

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao cadastrar notícia",
            erro: erro.message
        });

    }
};

const listar = async (req, res) => {
    try {

        const noticias = await prisma.noticias.findMany({
            where: {
                empresaId: req.user.empresaId
            },
            orderBy: {
                dataPublicacao: "desc"
            },
            include: {
                autor: {
                    select: {
                        id: true,
                        nome: true,
                        tipo: true,
                        fotoPerfil: true
                    }
                },
                midias: true
            }
        });

        return res.status(200).json(noticias);

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao listar notícias",
            erro: erro.message
        });

    }
};

const buscar = async (req, res) => {
    try {

        const id = Number(req.params.id);

        const noticia = await prisma.noticias.findFirst({
            where: {
                id,
                empresaId: req.user.empresaId
            },
            include: {
                autor: {
                    select: {
                        id: true,
                        nome: true,
                        tipo: true,
                        fotoPerfil: true
                    }
                },
                midias: true
            }
        });

        if (!noticia) {
            return res.status(404).json({
                mensagem: "Notícia não encontrada"
            });
        }

        return res.status(200).json(noticia);

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao buscar notícia",
            erro: erro.message
        });

    }
};

const atualizar = async (req, res) => {
    try {

        const id = Number(req.params.id);

        const noticia = await prisma.noticias.findFirst({
            where: {
                id,
                empresaId: req.user.empresaId
            }
        });

        if (!noticia) {
            return res.status(404).json({
                mensagem: "Notícia não encontrada"
            });
        }

        
        if (
            noticia.usuarioId !== req.user.id &&
            req.user.tipo !== "ADMINISTRADOR"
        ) {
            return res.status(403).json({
                mensagem: "Sem permissão para editar esta notícia"
            });
        }

        const { titulo, subtitulo, texto } = req.body;

        const noticiaAtualizada = await prisma.noticias.update({
            where: {
                id
            },
            data: {
                titulo,
                subtitulo,
                texto
            }
        });

        return res.status(200).json({
            mensagem: "Notícia atualizada com sucesso",
            noticia: noticiaAtualizada
        });

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao atualizar notícia",
            erro: erro.message
        });

    }
};

const excluir = async (req, res) => {
    try {

        const id = Number(req.params.id);

        const noticia = await prisma.noticias.findFirst({
            where: {
                id,
                empresaId: req.user.empresaId
            }
        });

        if (!noticia) {
            return res.status(404).json({
                mensagem: "Notícia não encontrada"
            });
        }

   
        if (
            noticia.usuarioId !== req.user.id &&
            req.user.tipo !== "ADMINISTRADOR"
        ) {
            return res.status(403).json({
                mensagem: "Sem permissão para excluir esta notícia"
            });
        }

        await prisma.noticias.delete({
            where: {
                id
            }
        });

        return res.status(200).json({
            mensagem: "Notícia excluída com sucesso"
        });

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao excluir notícia",
            erro: erro.message
        });

    }
};

module.exports = {
    cadastrar,
    listar,
    buscar,
    atualizar,
    excluir
};