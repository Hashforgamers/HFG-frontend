import { defineConfig } from 'vitest/config';

// Builds straight into the Flutter asset bundle. File names are stable (no
// content hash) because pubspec.yaml lists the folders and the in-app asset
// server sends its own cache headers.
export default defineConfig({
  base: './',
  build: {
    outDir: '../../assets/html_games/hash_rush',
    emptyOutDir: true,
    assetsDir: 'app',
    target: 'es2020',
    chunkSizeWarningLimit: 900,
    rollupOptions: {
      output: {
        entryFileNames: 'app/hash_rush.js',
        chunkFileNames: 'app/[name].js',
        assetFileNames: 'app/[name][extname]',
      },
    },
  },
  test: { environment: 'node', include: ['tests/**/*.test.ts'] },
});
