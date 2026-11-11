
const { PrismaClient } = require("@prisma/client");
const { PrismaPg } = require("@prisma/adapter-pg");

const adapter = new PrismaPg({
    connectionString: process.env.DATABASE_URL,
    ssl: {
        rejectUnauthorized: false
    },
    max: 1,
    connectionTimeoutMillis: 15000,
    idleTimeoutMillis: 30000
});

const prisma = new PrismaClient({ adapter });

module.exports = prisma;
