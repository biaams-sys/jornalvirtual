const prisma = require("../data/prisma");

const validarExclusaoComentario = async (req, res, next) => {
    try {
        const usuario = req.user;
        const comentarioId = Number(req.params.id);

        const comentario = await prisma.comentarios.findUnique({
            where: {
                id: comentarioId
            },
            include: {
                publicacao: true
            }
        });

        if (!comentario) {
            return res.status(404).json({
                mensagem: "Comentário não encontrado"
            });
        }

        if (comentario.publicacao.empresaId !== usuario.empresaId) {
            return res.status(403).json({
                mensagem: "Você não pode acessar comentários de outra empresa"
            });
        }

        const ehDono = comentario.usuarioId === usuario.id;
        const ehVerificado = usuario.tipo === "VERIFICADO";
        const ehAdministrador = usuario.tipo === "ADMINISTRADOR";

        if (ehDono || ehVerificado || ehAdministrador) {
            return next();
        }

        return res.status(403).json({
            mensagem: "Sem permissão para excluir comentário"
        });

    } catch (erro) {
        return res.status(500).json({
            mensagem: "Erro interno",
            erro: erro.message
        });
    }
};

module.exports = {
    validarExclusaoComentario
};