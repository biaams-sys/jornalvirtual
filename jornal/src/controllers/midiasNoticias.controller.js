const prisma = require("../data/prisma");
const supabase = require("../data/supabase");
const crypto = require("crypto");

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
                path: data.path
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