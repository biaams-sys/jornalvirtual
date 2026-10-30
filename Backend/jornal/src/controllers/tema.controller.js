const prisma = require("../data/prisma");

const cadastrar = async (req, res) => {
    try {

        if (req.user.tipo !== "ADMINISTRADOR") {
            return res.status(403).json({
                mensagem: "Somente administradores podem cadastrar um tema."
            });
        }

        const {
            empresaId,
            primary,
            primaryDark,
            secondary,
            secondaryLight,
            background,
            surface,
            text,
            textLight,
            border,
            danger
        } = req.body;

        if (!empresaId) {
            return res.status(400).json({
                mensagem: "empresaId é obrigatório."
            });
        }

        const empresa = await prisma.empresa.findUnique({
            where: {
                id: Number(empresaId)
            },
            include: {
                tema: true
            }
        });

        if (!empresa) {
            return res.status(404).json({
                mensagem: "Empresa não encontrada."
            });
        }

        if (empresa.tema) {
            return res.status(400).json({
                mensagem: "Esta empresa já possui um tema."
            });
        }

        const tema = await prisma.temaEmpresa.create({
            data: {
                empresaId: Number(empresaId),
                primary,
                primaryDark,
                secondary,
                secondaryLight,
                background,
                surface,
                text,
                textLight,
                border,
                danger
            }
        });

        return res.status(201).json({
            mensagem: "Tema criado com sucesso.",
            tema
        });

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao cadastrar tema.",
            erro: erro.message
        });

    }
};

const listar = async (req, res) => {
    try {

        const temas = await prisma.temaEmpresa.findMany({
            include: {
                empresa: {
                    select: {
                        id: true,
                        nome: true,
                        logo: true
                    }
                }
            }
        });

        return res.status(200).json(temas);

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao listar temas.",
            erro: erro.message
        });

    }
};

const buscar = async (req, res) => {
    try {
        const empresaId = Number(req.params.empresaId);

        const tema = await prisma.temaEmpresa.findUnique({
            where: {
                empresaId: empresaId
            },
            include: {
                empresa: {
                    select: {
                        id: true,
                        nome: true,
                        logo: true
                    }
                }
            }
        });

        if (!tema) {
            return res.status(404).json({
                mensagem: "Tema não encontrado."
            });
        }

        return res.status(200).json(tema);

    } catch (erro) {
        return res.status(500).json({
            mensagem: "Erro ao buscar tema.",
            erro: erro.message
        });
    }
};




const atualizar = async (req, res) => {
    try {

        if (req.user.tipo !== "ADMINISTRADOR") {
            return res.status(403).json({
                mensagem: "Somente administradores podem alterar o tema."
            });
        }

        const empresaId = Number(req.params.empresaId);

        const tema = await prisma.temaEmpresa.findUnique({
            where: {
                empresaId
            }
        });

        if (!tema) {
            return res.status(404).json({
                mensagem: "Tema não encontrado."
            });
        }

        const {
            primary,
            primaryDark,
            secondary,
            secondaryLight,
            background,
            surface,
            text,
            textLight,
            border,
            danger
        } = req.body;

        const dados = {};

        if (primary !== undefined) dados.primary = primary;
        if (primaryDark !== undefined) dados.primaryDark = primaryDark;
        if (secondary !== undefined) dados.secondary = secondary;
        if (secondaryLight !== undefined) dados.secondaryLight = secondaryLight;
        if (background !== undefined) dados.background = background;
        if (surface !== undefined) dados.surface = surface;
        if (text !== undefined) dados.text = text;
        if (textLight !== undefined) dados.textLight = textLight;
        if (border !== undefined) dados.border = border;
        if (danger !== undefined) dados.danger = danger;

        const temaAtualizado = await prisma.temaEmpresa.update({
            where: {
                empresaId
            },
            data: dados
        });

        return res.status(200).json({
            mensagem: "Tema atualizado com sucesso.",
            tema: temaAtualizado
        });

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao atualizar tema.",
            erro: erro.message
        });

    }
};

const excluir = async (req, res) => {
    try {

        if (req.user.tipo !== "ADMINISTRADOR") {
            return res.status(403).json({
                mensagem: "Somente administradores podem excluir o tema."
            });
        }

        const empresaId = Number(req.params.empresaId);

        const tema = await prisma.temaEmpresa.findUnique({
            where: {
                empresaId
            }
        });

        if (!tema) {
            return res.status(404).json({
                mensagem: "Tema não encontrado."
            });
        }

        await prisma.temaEmpresa.delete({
            where: {
                empresaId
            }
        });

        return res.status(200).json({
            mensagem: "Tema excluído com sucesso."
        });

    } catch (erro) {

        return res.status(500).json({
            mensagem: "Erro ao excluir tema.",
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