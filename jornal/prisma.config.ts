import "dotenv/config";
import { defineConfig } from "prisma/config";

export default defineConfig({
  schema: "prisma/schema.prisma",

  migrations: {
    path: "prisma/migrations",
  },

  datasource: {
    // Busca a URL direto do seu .env sem frescuras de funções
    url: process.env.DATABASE_URL || "", 
  },
});

