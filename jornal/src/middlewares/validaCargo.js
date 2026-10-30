const validaAdministrador = (req, res, next) => {

    if (!req.user) {
        return res.status(401).json({
            mensagem: "Token não informado."
        });
    }

    if (req.user.tipo !== "ADMINISTRADOR") {
        return res.status(403).json({
            mensagem: "Usuário sem permissão."
        });
    }

    next();
};

const validaVerificado = (req, res, next) => {

    if (!req.user) {
        return res.status(401).json({
            mensagem: "Token não informado."
        });
    }

    if (
        req.user.tipo !== "VERIFICADO" &&
        req.user.tipo !== "ADMINISTRADOR"
    ) {
        return res.status(403).json({
            mensagem: "Usuário sem permissão."
        });
    }

    next();
};

const validaUsuario = (req, res, next) => {

    if (!req.user) {
        return res.status(401).json({
            mensagem: "Token não informado."
        });
    }

    if (
        req.user.tipo !== "USUARIO" &&
        req.user.tipo !== "VERIFICADO" &&
        req.user.tipo !== "ADMINISTRADOR"
    ) {
        return res.status(403).json({
            mensagem: "Usuário sem permissão."
        });
    }

    next();
};

const validaProprioPerfil = (req, res, next) => {

    if (!req.user) {
        return res.status(401).json({
            mensagem: "Token não informado."
        });
    }

    const idPerfil = Number(req.params.id);

    if (
        req.user.id !== idPerfil &&
        req.user.tipo !== "ADMINISTRADOR"
    ) {
        return res.status(403).json({
            mensagem: "Usuário sem permissão."
        });
    }

    next();
};

module.exports = {
    validaAdministrador,
    validaVerificado,
    validaUsuario,
    validaProprioPerfil
};