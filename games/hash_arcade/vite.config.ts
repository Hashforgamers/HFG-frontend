import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';

// Builds into the Flutter asset bundle. Names carry a content hash so an app
// update never serves last version's cached scripts (index.html is no-cache).
export default defineConfig({
  base: './',
  plugins: [react(), tailwindcss()],
  // Odd One Out's rules live in ../odd_one_out and are shared, not copied
  server: { fs: { allow: ['..'] } },
  build: {
    outDir: '../../assets/html_games/hash_arcade',
    emptyOutDir: true,
    target: 'es2020',
    rollupOptions: {
      output: {
        entryFileNames: 'app/arcade-[hash].js',
        // lazy games are all index.tsx; name each chunk after its game folder
        chunkFileNames: (c) => `app/${c.facadeModuleId?.match(/games\/(\w+)\/index/)?.[1] ?? c.name}-[hash].js`,
        assetFileNames: 'app/[name]-[hash][extname]',
      },
    },
  },
  test: { environment: 'node', include: ['tests/**/*.test.ts'] },
});
