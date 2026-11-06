import { SIM_DT } from '../gameplay/constants';

/**
 * requestAnimationFrame driver with a fixed-timestep accumulator: `step` runs
 * zero or more times per frame at exactly SIM_DT, `render` once. A slow frame
 * runs at most MAX_STEPS steps, so a hitch (or a backgrounded tab coming back)
 * slows the game down instead of making it leap forward.
 */
export class GameLoop {
  static readonly MAX_STEPS = 4;
  private raf = 0;
  private last = 0;
  private acc = 0;
  private running = false;
  /** Smoothed frame time in ms (for the quality manager and the debug overlay). */
  frameMs = 16.7;

  constructor(
    private readonly step: (dt: number) => void,
    private readonly render: (frameDt: number, alpha: number) => void,
  ) {}

  start(): void {
    if (this.running) return;
    this.running = true;
    this.last = performance.now();
    this.acc = 0;
    this.raf = requestAnimationFrame(this.tick);
  }

  stop(): void {
    this.running = false;
    cancelAnimationFrame(this.raf);
  }

  /** Drop accumulated time (after a pause or a tab switch). */
  reset(): void {
    this.last = performance.now();
    this.acc = 0;
  }

  private readonly tick = (now: number): void => {
    if (!this.running) return;
    this.raf = requestAnimationFrame(this.tick);
    const frame = Math.min(0.25, Math.max(0, (now - this.last) / 1000));
    this.last = now;
    this.frameMs += (frame * 1000 - this.frameMs) * 0.1;
    this.acc += frame;
    let steps = 0;
    while (this.acc >= SIM_DT && steps < GameLoop.MAX_STEPS) {
      this.step(SIM_DT);
      this.acc -= SIM_DT;
      steps++;
    }
    if (this.acc > SIM_DT) this.acc = 0;
    this.render(frame, this.acc / SIM_DT);
  };
}
