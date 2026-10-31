import './styles/main.css';
import { Game } from './core/Game';

const boot = document.getElementById('boot')!;
const fill = document.getElementById('boot-fill')!;
const label = document.getElementById('boot-label')!;
const stage = document.getElementById('stage')!;

const game = new Game(stage, (fraction, text) => {
  fill.style.transform = `scaleX(${Math.max(0.02, fraction).toFixed(3)})`;
  label.textContent = text.toUpperCase();
});

game
  .init()
  .then(() => boot.classList.add('done'))
  .catch((err: unknown) => {
    console.error(err);
    label.className = 'err';
    label.textContent = err instanceof Error ? err.message : 'HASH RUSH could not start.';
  });

// handle for automated tests and debugging
(window as unknown as { __hashRush: Game }).__hashRush = game;
