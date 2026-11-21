import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';

// Builds straight into the Flutter asset bundle with stable names, like hash_rush.
export default defineConfig({
  base: './',
  plugins: [react(), tailwindcss()],
  build: {
    outDir: '../../assets/html_games/odd_one_out',
    emptyOutDir: true,
    target: 'es2020',
    rollupOptions: {
      output: {
        entryFileNames: 'app/odd_one_out.js',
        chunkFileNames: 'app/[name].js',
        assetFileNames: 'app/[name][extname]',
      },
    },
  },
  test: { environment: 'node', include: ['tests/**/*.test.ts'] },
});
