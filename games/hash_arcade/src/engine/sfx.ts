// Tiny Web Audio synth — original arcade blips, no audio files to ship.

let ctx: AudioContext | null = null;

function tone(freq: number, start: number, dur: number, type: OscillatorType, gain = 0.15, slideTo?: number) {
  if (!ctx) return;
  const t = ctx.currentTime + start;
  const osc = ctx.createOscillator();
  const g = ctx.createGain();
  osc.type = type;
  osc.frequency.setValueAtTime(freq, t);
  if (slideTo) osc.frequency.exponentialRampToValueAtTime(slideTo, t + dur);
  g.gain.setValueAtTime(gain, t);
  g.gain.exponentialRampToValueAtTime(0.001, t + dur);
  osc.connect(g).connect(ctx.destination);
  osc.start(t);
  osc.stop(t + dur);
}

export const sfx = {
  enabled: true,
  /** Must run inside a user gesture the first time (autoplay rules). */
  unlock() {
    if (!ctx) {
      const AC = window.AudioContext ?? (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      if (AC) ctx = new AC();
    }
    void ctx?.resume();
  },
  correct(mult: number) {
    if (!this.enabled) return;
    const base = 520 + mult * 60;
    tone(base, 0, 0.09, 'square', 0.08);
    tone(base * 1.5, 0.06, 0.12, 'square', 0.07);
  },
  wrong() {
    if (!this.enabled) return;
    tone(180, 0, 0.25, 'sawtooth', 0.12, 70);
  },
  streak() {
    if (!this.enabled) return;
    [660, 830, 990, 1320].forEach((f, i) => tone(f, i * 0.07, 0.12, 'triangle', 0.1));
  },
  tick() {
    if (!this.enabled) return;
    tone(1000, 0, 0.04, 'sine', 0.05);
  },
  /** A pitched pad tone (Simon pads, memory cells). */
  note(freq: number, dur = 0.25) {
    if (!this.enabled) return;
    tone(freq, 0, dur, 'triangle', 0.14);
  },
  over() {
    if (!this.enabled) return;
    [440, 330, 220].forEach((f, i) => tone(f, i * 0.15, 0.25, 'triangle', 0.12));
  },
};
