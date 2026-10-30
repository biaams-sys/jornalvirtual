
const prisma = require("../data/prisma");
const crypto = require("crypto");
const jsonwebtoken = require("jsonwebtoken");
const nodemailer = require("nodemailer");
require("dotenv").config();

const TIPOS_VALIDOS = [
    "USUARIO",
    "VERIFICADO",
    "ADMINISTRADOR"
];

const Login = async (req, res) => {
    try {
        let { email, senha } = req.body;

        if (!email || !senha) {
            return res.status(400).json({
                mensagem: "Email e senha obrigatórios"
            });
        }

        email = email.toLowerCase().trim();

        const senhaHash = crypto
            .createHash("md5")
            .update(senha)
            .digest("hex");

        console.log(email, senhaHash);

        const usuario = await prisma.usuarios.findUnique({
            where: {
                email
            },
            include: {
                empresa: {
                    include: {
                        tema: true
                    }
                }
            }
        });

        if (!usuario) {
            return res.status(401).json({
                mensagem: "Email ou senha inválidos"
            });
        }

        if (usuario.senha !== senhaHash) {
            return res.status(401).json({
                mensagem: "Email ou senha inválidos"
            });
        }

        const token = jsonwebtoken.sign(
            {
                id: usuario.id,
                nome: usuario.nome,
                tipo: usuario.tipo,
                empresaId: usuario.empresaId
            },
            process.env.SECRET_JWT,
            {
                expiresIn: "120min"
            }
        );

        return res.status(200).json({
            mensagem: "Login realizado com sucesso",
            token
        });

    } catch (erro) {
        return res.status(500).json({
            mensagem: "Erro ao realizar login",
            erro: erro.message
        });
    }
};

const cadastrar = async (req, res) => {
    try {
        let {
            nome,
            email,
            senha,
            bio,
            tipo,
            fotoPerfil,
            template,
            empresaId
        } = req.body;

        const usuarioLogado = req.user;

        if (usuarioLogado.tipo !== "ADMINISTRADOR") {
            return res.status(403).json({
                mensagem: "Somente administradores podem cadastrar usuários."
            });
        }

        if (!nome || !email || !senha || !tipo || !empresaId) {
            return res.status(400).json({
                mensagem: "Campos obrigatórios não preenchidos."
            });
        }

        empresaId = Number(empresaId);

        if (empresaId !== usuarioLogado.empresaId) {
            return res.status(403).json({
                mensagem: "Você só pode cadastrar usuários da sua empresa."
            });
        }

        const empresa = await prisma.empresa.findUnique({
            where: {
                id: empresaId
            }
        });

        if (!empresa) {
            return res.status(404).json({
                mensagem: "Empresa não encontrada."
            });
        }

        nome = nome.trim();
        email = email.toLowerCase().trim();
        tipo = tipo.toUpperCase();

        if (!TIPOS_VALIDOS.includes(tipo)) {
            return res.status(400).json({
                mensagem: "Tipo inválido."
            });
        }

        const existe = await prisma.usuarios.findUnique({
            where: {
                email
            }
        });

        if (existe) {
            return res.status(400).json({
                mensagem: "Email já cadastrado."
            });
        }

        const senhaHash = crypto
            .createHash("md5")
            .update(senha)
            .digest("hex");

        const novoUsuario = await prisma.usuarios.create({
            data: {
                nome,
                email,
                senha: senhaHash,
                bio,
                tipo,
                fotoPerfil,
                template,
                empresaId
            }
        });

        const { senha: _, ...usuarioCriado } = novoUsuario;

        return res.status(201).json({
            mensagem: "Usuário criado com sucesso.",
            usuario: usuarioCriado
        });

    } catch (erro) {
        return res.status(500).json({
            mensagem: "Erro ao cadastrar usuário.",
            erro: erro.message
        });
    }
};

const listar = async (req, res) => {
    try {
        const lista = await prisma.usuarios.findMany({
            where: {
                empresaId: req.user.empresaId
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

        return res.status(200).json(lista);

    } catch (erro) {
        return res.status(500).json({
            mensagem: "Erro ao listar usuários",
            erro: erro.message
        });
    }
};

const buscar = async (req, res) => {
    try {
        const id = Number(req.params.id);

        const usuario = await prisma.usuarios.findFirst({
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
                }
            }
        });

        if (!usuario) {
            return res.status(404).json({
                mensagem: "Usuário não encontrado."
            });
        }

        const { senha, ...usuarioSemSenha } = usuario;

        return res.status(200).json(usuarioSemSenha);

    } catch (erro) {
        return res.status(500).json({
            mensagem: "Erro ao buscar usuário",
            erro: erro.message
        });
    }
};

const atualizar = async (req, res) => {
    try {
        const id = Number(req.params.id);
        const dados = { ...req.body };

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

        if (
            req.user.id !== id &&
            req.user.tipo !== "ADMINISTRADOR"
        ) {
            return res.status(403).json({
                mensagem: "Sem permissão."
            });
        }

        delete dados.id;
        delete dados.dataCriacao;
        delete dados.empresa;

        if (req.user.tipo !== "ADMINISTRADOR") {
            delete dados.nome;
            delete dados.email;
            delete dados.tipo;
            delete dados.empresaId;
            delete dados.senha;
        } else {
            if (dados.empresaId) {
                dados.empresaId = Number(dados.empresaId);

                if (dados.empresaId !== req.user.empresaId) {
                    return res.status(403).json({
                        mensagem: "Não é permitido mover usuários para outra empresa."
                    });
                }
            }

            if (dados.tipo) {
                dados.tipo = dados.tipo.toUpperCase();

                if (!TIPOS_VALIDOS.includes(dados.tipo)) {
                    return res.status(400).json({
                        mensagem: "Tipo de usuário inválido."
                    });
                }
            }
        }

        if (dados.email) {
            dados.email = dados.email.toLowerCase().trim();
        }

        if (dados.nome) {
            dados.nome = dados.nome.trim();
        }

        if (dados.senha && dados.senha.trim() !== "") {
            dados.senha = crypto
                .createHash("md5")
                .update(dados.senha)
                .digest("hex");
        } else {
            delete dados.senha;
        }

        const atualizado = await prisma.usuarios.update({
            where: {
                id
            },
            data: dados
        });

        const { senha, ...usuarioFinal } = atualizado;

        return res.status(200).json({
            mensagem: "Usuário atualizado com sucesso.",
            usuario: usuarioFinal
        });

    } catch (erro) {
        return res.status(500).json({
            mensagem: "Erro ao atualizar usuário.",
            erro: erro.message
        });
    }
};

const excluir = async (req, res) => {
    try {
        const id = Number(req.params.id);

        if (req.user.tipo !== "ADMINISTRADOR") {
            return res.status(403).json({
                mensagem: "Somente administradores podem excluir usuários."
            });
        }

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

        await prisma.usuarios.delete({
            where: {
                id
            }
        });

        return res.status(200).json({
            mensagem: "Usuário excluído com sucesso."
        });

    } catch (erro) {
        return res.status(500).json({
            mensagem: "Erro ao excluir usuário.",
            erro: erro.message
        });
    }
};

const pesquisar = async (req, res) => {
    try {
        const { termo } = req.query;

        const usuarios = await prisma.usuarios.findMany({
            where: {
                empresaId: req.user.empresaId,
                nome: {
                    contains: termo,
                    mode: "insensitive"
                }
            }
        });

        return res.status(200).json({
            usuarios
        });

    } catch (erro) {
        return res.status(500).json({
            mensagem: "Erro ao pesquisar usuários.",
            erro: erro.message
        });
    }
};

const fotoPerfil = async (req, res) => {
    const usuarioId = req.user.id;
    const arquivo = req.file;

    const fs = require("fs");

    const pasta = `uploads/perfil/${usuarioId}`;
    const caminho = `${pasta}/${arquivo.filename}`;

    if (!fs.existsSync(pasta)) {
        fs.mkdirSync(pasta, { recursive: true });
    }

    fs.renameSync(arquivo.path, caminho);

    await prisma.usuarios.update({
        where: {
            id: usuarioId
        },
        data: {
            fotoPerfil: caminho
        }
    });

    return res.status(200).json({
        mensagem: "Foto de perfil atualizada",
        caminho
    });
};

const atualizarTemplate = async (req, res) => {
    try {
        const usuarioId = req.user.id;
        const arquivo = req.file;

        const fs = require("fs");

        const pasta = `uploads/templates/${usuarioId}`;
        const caminho = `${pasta}/${arquivo.filename}`;

        if (!fs.existsSync(pasta)) {
            fs.mkdirSync(pasta, { recursive: true });
        }

        fs.renameSync(arquivo.path, caminho);

        await prisma.usuarios.update({
            where: {
                id: usuarioId
            },
            data: {
                template: caminho
            }
        });

        return res.status(200).json({
            mensagem: "Template atualizado com sucesso",
            caminho
        });

    } catch (erro) {
        return res.status(500).json({
            mensagem: "Erro ao atualizar template",
            erro: erro.message
        });
    }
};

const esqueciSenha = async (req, res) => {
    try {
        const email = typeof req.body.email === "string"
            ? req.body.email.toLowerCase().trim()
            : "";

        if (!email) {
            return res.status(400).json({
                mensagem: "Informe um e-mail válido."
            });
        }

        const mensagem = "Se o e-mail estiver cadastrado, você receberá um link para redefinir sua senha.";

        const usuario = await prisma.usuarios.findUnique({
            where: {
                email
            }
        });

        if (!usuario) {
            return res.status(200).json({
                mensagem
            });
        }

        const token = crypto.randomBytes(32).toString("hex");

        const tokenHash = crypto
            .createHash("sha256")
            .update(token)
            .digest("hex");

        const expiracao = new Date(Date.now() + 30 * 60 * 1000);
        const urlBase = process.env.FRONTEND_URL;

        if (
            !urlBase ||
            !process.env.SMTP_HOST ||
            !process.env.SMTP_USER ||
            !process.env.SMTP_PASS ||
            !process.env.SMTP_FROM
        ) {
            throw new Error("Configuração de envio de e-mail incompleta.");
        }

        await prisma.$transaction(async (tx) => {
            await tx.recuperacaoSenha.deleteMany({
                where: {
                    usuarioId: usuario.id
                }
            });

            await tx.recuperacaoSenha.create({
                data: {
                    usuarioId: usuario.id,
                    tokenHash,
                    expiracao
                }
            });
        });

        const transporte = nodemailer.createTransport({
            host: process.env.SMTP_HOST,
            port: Number(process.env.SMTP_PORT || 587),
            secure: Number(process.env.SMTP_PORT || 587) === 465,
            auth: {
                user: process.env.SMTP_USER,
                pass: process.env.SMTP_PASS
            }
        });

        const link = `${urlBase.replace(/\/$/, "")}/html/redefinir-senha.html?token=${encodeURIComponent(token)}`;
        await transporte.sendMail({
            from: process.env.SMTP_FROM,
            to: usuario.email,
            subject: "Recuperação de senha - JornalOnline",
            text: `Olá, ${usuario.nome}!

Para redefinir sua senha, acesse: ${link}

O link expira em 30 minutos.

Se você não solicitou a recuperação, ignore esta mensagem.`
        });

        return res.status(200).json({
            mensagem
        });

    } catch (erro) {
        console.error("Erro na recuperação de senha:", erro);

        return res.status(500).json({
            mensagem: "Não foi possível processar a solicitação no momento."
        });
    }
};

const redefinirSenha = async (req, res) => {
    try {
        const { token, senha } = req.body;

        if (
            typeof token !== "string" ||
            !/^[a-f0-9]{64}$/i.test(token) ||
            typeof senha !== "string" ||
            senha.length < 8
        ) {
            return res.status(400).json({
                mensagem: "Informe um token válido e uma senha com pelo menos 8 caracteres."
            });
        }

        const tokenHash = crypto
            .createHash("sha256")
            .update(token)
            .digest("hex");

        const senhaHash = crypto
            .createHash("md5")
            .update(senha)
            .digest("hex");

        const recuperacao = await prisma.recuperacaoSenha.findUnique({
            where: {
                tokenHash
            }
        });

        if (!recuperacao || recuperacao.expiracao <= new Date()) {
            return res.status(400).json({
                mensagem: "Link inválido ou expirado. Solicite outro."
            });
        }

        const alterou = await prisma.$transaction(async (tx) => {
            const consumido = await tx.recuperacaoSenha.deleteMany({
                where: {
                    id: recuperacao.id,
                    tokenHash,
                    expiracao: {
                        gt: new Date()
                    }
                }
            });

            if (consumido.count !== 1) {
                return false;
            }

            await tx.usuarios.update({
                where: {
                    id: recuperacao.usuarioId
                },
                data: {
                    senha: senhaHash
                }
            });

            await tx.recuperacaoSenha.deleteMany({
                where: {
                    usuarioId: recuperacao.usuarioId
                }
            });

            return true;
        });

        if (!alterou) {
            return res.status(400).json({
                mensagem: "Link inválido ou expirado. Solicite outro."
            });
        }

        return res.status(200).json({
            mensagem: "Senha redefinida com sucesso."
        });

    } catch (erro) {
        console.error("Erro ao redefinir senha:", erro);

        return res.status(500).json({
            mensagem: "Erro ao redefinir a senha."
        });
    }
};

module.exports = {
    Login,
    cadastrar,
    listar,
    buscar,
    atualizar,
    excluir,
    pesquisar,
    fotoPerfil,
    atualizarTemplate,
    esqueciSenha,
    redefinirSenha
};
