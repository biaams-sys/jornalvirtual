const jsonwebtoken = require("jsonwebtoken");

const validate = (req, res, next) => {

    const token = req.headers.authorization?.split(" ")[1];

    if (!token) {
        return res.status(401).json({
            mensagem: "Acesso negado. Token não informado."
        });
    }

    try {

        const payload = jsonwebtoken.verify(
            token,
            process.env.SECRET_JWT
        );

        req.user = payload;

        next();

    } catch (erro) {

        console.error("Erro na validação do token:", erro);

        return res.status(401).json({
            mensagem: "Token inválido."
        });

    }

};

module.exports = {
    validate
};