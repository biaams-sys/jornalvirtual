const { PrismaClient } = require("@prisma/client");
const { PrismaPg } = require("@prisma/adapter-pg");
const pg = require("pg");

// Cria um pool tradicional do driver pg com limites de tolerância mais altos
const pool = new pg.Pool({ 
    connectionString: process.env.DATABASE_URL,
    connectionTimeoutMillis: 15000, // Dá até 15 segundos para fazer o handshake com os EUA
    idleTimeoutMillis: 30000,
    max: 10 // Limita as conexões simultâneas locais
});

const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

module.exports = prisma;
