import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";
import { resolve } from "path";

export default defineConfig({
  plugins: [vue()],
  root: resolve("./static/src"),
  base: "/static/",
  server: {
    host: "0.0.0.0",
    port: 5173,
    origin: "http://localhost:5173",
  },
  build: {
    outDir: resolve("./static/dist"),
    emptyOutDir: true,
    manifest: "manifest.json",
    rollupOptions: {
      input: {
        main: resolve("./static/src/main.ts"),
      },
    },
  },
  resolve: {
    alias: {
      "@": resolve("./static/src"),
    },
  },
});
