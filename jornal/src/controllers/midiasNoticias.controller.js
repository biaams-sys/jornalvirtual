const prisma = require("../data/prisma");
const supabase = require("../data/supabase");
const crypto = require("crypto");

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

const cadastrar = async (req, res) => {
    try {
        const noticiaId = Number(req.params.id);
        const arquivo = req.file;

        if (!arquivo) {
            return res.status(400).json({ mensagem: "Nenhum arquivo enviado." });
        }

        const noticia = await prisma.noticias.findFirst({
            where: {
                id: noticiaId,
                empresaId: req.user.empresaId
            }
        });

        if (!noticia) {
            return res.status(404).json({ mensagem: "Notícia não encontrada." });
        }

        if (
            noticia.usuarioId !== req.user.id &&
            req.user.tipo !== "ADMINISTRADOR"
        ) {
            return res.status(403).json({ mensagem: "Sem permissão para adicionar mídia nesta notícia." });
        }

        const extensoes = {
            "image/jpeg": "jpg",
            "image/jpg": "jpg",
            "image/png": "png",
            "image/webp": "webp",
            "image/heic": "heic",
            "image/heif": "heif"
        };

        let extensao = extensoes[arquivo.mimetype];
        if (!extensao && arquivo.originalname) {
            const extOriginal = arquivo.originalname.split(".").pop().toLowerCase();
            if (["jpg", "jpeg", "png", "webp", "heic", "heif"].includes(extOriginal)) {
                extensao = extOriginal;
            }
        }

        if (!extensao) {
            return res.status(400).json({ mensagem: "Formato de imagem não permitido." });
        }

        const nomeArquivo = `${Date.now()}-${crypto.randomUUID()}.${extensao}`;
        const caminho = `noticias/${noticiaId}/${nomeArquivo}`;

        const { data, error } = await supabase.storage
            .from("midias")
            .upload(caminho, arquivo.buffer, {
                contentType: arquivo.mimetype || 'image/jpeg',
                upsert: true
            });

        if (error) throw error;

        const novaMidia = await prisma.midiasNoticias.create({
            data: {
                noticiaId: noticiaId,
                path: data.path,
                nomeOriginal: arquivo.originalname,
                nomeArquivo: nomeArquivo,
                mimeType: arquivo.mimeType
            }
        });

        return res.status(201).json({
            mensagem: "Mídia cadastrada com sucesso",
            midia: novaMidia
        });

    } catch (erro) {
        return res.status(500).json({
            mensagem: "Erro ao cadastrar mídia",
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

            if (error) {
                console.error("Erro Supabase:", error);
                throw error;
            }
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
    cadastrar,
    excluir
};