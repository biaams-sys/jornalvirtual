const supabase = require("./supabase");

const BUCKET = "midias";

const enviarArquivo = async (arquivo, caminho) => {
    const { data, error } = await supabase.storage
        .from(BUCKET)
        .upload(caminho, arquivo.buffer, {
            contentType: arquivo.mimetype,
            upsert: true
        });

    if (error) {
        throw error;
    }

    const { data: urlData } = supabase.storage
        .from(BUCKET)
        .getPublicUrl(data.path);

    return {
        path: data.path,
        url: urlData.publicUrl
    };
};

const excluirArquivo = async (caminho) => {
    const { error } = await supabase.storage
        .from(BUCKET)
        .remove([caminho]);

    if (error) {
        throw error;
    }
};

module.exports = {
    enviarArquivo,
    excluirArquivo
};