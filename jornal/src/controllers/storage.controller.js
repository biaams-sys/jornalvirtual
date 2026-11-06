
const supabase = require("../data/supabase");
const crypto = require("crypto");

const BUCKET = "midias";

const tiposPermitidos = {
    "image/jpeg": "jpg",
    "image/png": "png",
    "image/webp": "webp",
    "video/mp4": "mp4",
    "video/webm": "webm",
    "video/x-matroska": "mkv"
};

const autorizarUploadPublicacao = async (req, res) => {
    try {
        const publicacaoId = Number(req.params.id);
        const { nomeOriginal, mimeType } = req.body;

        if (!Number.isInteger(publicacaoId) || publicacaoId <= 0) {
            return res.status(400).json({
                mensagem: "ID da publicação inválido"
            });
        }

        const publicacao = await require("../data/prisma").publicacoes.findFirst({
            where: {
                id: publicacaoId,
                empresaId: req.user.empresaId
            }
        });

        if (!publicacao) {
            return res.status(404).json({
                mensagem: "Publicação não encontrada"
            });
        }

        if (
            publicacao.usuarioId !== req.user.id &&
            req.user.tipo !== "ADMINISTRADOR"
        ) {
            return res.status(403).json({
                mensagem: "Sem permissão para adicionar mídia"
            });
        }

        if (!nomeOriginal || !tiposPermitidos[mimeType]) {
            return res.status(400).json({
                mensagem: "Arquivo ou formato não permitido"
            });
        }

        const extensao = tiposPermitidos[mimeType];
        const nomeArquivo = `${Date.now()}-${crypto.randomUUID()}.${extensao}`;
        const path = `publicacoes/${publicacaoId}/${nomeArquivo}`;

        const { data, error } = await supabase.storage
            .from(BUCKET)
            .createSignedUploadUrl(path);

        if (error) {
            throw error;
        }

        const { data: urlData } = supabase.storage
            .from(BUCKET)
            .getPublicUrl(path);

        return res.status(200).json({
            mensagem: "Autorização criada com sucesso",
            signedUrl: data.signedUrl,
            token: data.token,
            path,
            nomeOriginal,
            nomeArquivo,
            mimeType,
            publicUrl: urlData.publicUrl
        });

    } catch (erro) {
        return res.status(500).json({
            mensagem: "Erro ao autorizar upload",
            erro: erro.message
        });
    }
};

const confirmarUploadPublicacao = async (req, res) => {
    try {
        const publicacaoId = Number(req.params.id);
        const { path, nomeOriginal, nomeArquivo, mimeType } = req.body;

        const prisma = require("../data/prisma");

        const publicacao = await prisma.publicacoes.findFirst({
            where: {
                id: publicacaoId,
                empresaId: req.user.empresaId
            }
        });

        if (!publicacao) {
            return res.status(404).json({
                mensagem: "Publicação não encontrada"
            });
        }

        if (
            publicacao.usuarioId !== req.user.id &&
            req.user.tipo !== "ADMINISTRADOR"
        ) {
            return res.status(403).json({
                mensagem: "Sem permissão para adicionar mídia"
            });
        }

        const prefixoEsperado = `publicacoes/${publicacaoId}/`;

        if (
            !path ||
            !path.startsWith(prefixoEsperado) ||
            !nomeOriginal ||
            !nomeArquivo ||
            !tiposPermitidos[mimeType]
        ) {
            return res.status(400).json({
                mensagem: "Dados da mídia inválidos"
            });
        }

        const { data: arquivo, error } = await supabase.storage
            .from(BUCKET)
            .createSignedUrl(path, 60);

        if (error || !arquivo) {
            return res.status(400).json({
                mensagem: "Arquivo não encontrado no armazenamento"
            });
        }

        const midia = await prisma.midiasPublicacoes.create({
            data: {
                nomeOriginal,
                nomeArquivo,
                mimeType,
                path,
                publicacaoId
            }
        });

        return res.status(201).json({
            mensagem: "Mídia cadastrada com sucesso",
            midia
        });

    } catch (erro) {
        return res.status(500).json({
            mensagem: "Erro ao confirmar upload",
            erro: erro.message
        });
    }
};

module.exports = {
    autorizarUploadPublicacao,
    confirmarUploadPublicacao
};
