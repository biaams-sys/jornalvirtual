
const nodemailer = require("nodemailer");
require("dotenv").config();

async function testarEmail() {
    try {
        const transporte = nodemailer.createTransport({
            host: process.env.SMTP_HOST,
            port: Number(process.env.SMTP_PORT),
            secure: false,
            auth: {
                user: process.env.SMTP_USER,
                pass: process.env.SMTP_PASS
            }
        });

        await transporte.verify();

        console.log("SMTP autenticado com sucesso!");
    } catch (erro) {
        console.error("Falha no SMTP:", {
            codigo: erro.code,
            resposta: erro.response,
            comando: erro.command
        });
    }
}

testarEmail();
