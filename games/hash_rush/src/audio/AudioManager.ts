import type { WorldId } from '../levels/LevelConfig';

export type Sfx =
  | 'shoot' | 'deploy' | 'gate' | 'gateBig' | 'hit' | 'unitDie' | 'enemyDie' | 'explosion' | 'bossRoar' | 'bossAttack'
  | 'bossDie' | 'cannonHit' | 'victory' | 'defeat' | 'click' | 'buy' | 'deny' | 'ability' | 'warning' | 'march';

/** Minimum gap between two plays of the same sound, seconds (keeps crowds from becoming noise). */
const THROTTLE: Partial<Record<Sfx, number>> = {
  shoot: 0.05, deploy: 0.06, gate: 0.07, gateBig: 0.12, hit: 0.07, unitDie: 0.09, enemyDie: 0.06, explosion: 0.1,
  cannonHit: 0.2, warning: 0.3, march: 0.24, bossAttack: 0.3,
};

const SCALES: Record<WorldId, { root: number; scale: number[]; bpm: number }> = {
  neon: { root: 110, scale: [0, 3, 5, 7, 10], bpm: 124 },
  desert: { root: 98, scale: [0, 1, 4, 5, 7, 8], bpm: 112 },
  frozen: { root: 123.5, scale: [0, 2, 3, 7, 9], bpm: 108 },
  cyber: { root: 116.5, scale: [0, 3, 5, 6, 7, 10], bpm: 132 },
  volcanic: { root: 87.3, scale: [0, 1, 3, 6, 7], bpm: 120 },
};

/**
 * All audio is synthesised with the Web Audio API — there are no audio files.
 * Layers: sfx bus, music bus (a small step sequencer: kick, bass, arpeggio,
 * hat) -> master. The context is created on the first user gesture (browser
 * autoplay policy) and suspended while the tab is hidden.
 */
export class AudioManager {
  private ctx: AudioContext | null = null;
  private master!: GainNode;
  private sfxBus!: GainNode;
  private musicBus!: GainNode;
  private noise!: AudioBuffer;
  private readonly last = new Map<Sfx, number>();
  private sfxOn = true;
  private musicOn = true;
  private world: WorldId | null = null;
  private timer = 0;
  private nextNote = 0;
  private stepIndex = 0;
  private intensity = 0;

  /** Call from a user gesture. Safe to call repeatedly. */
  unlock(): void {
    if (!this.ctx) {
      const Ctor = window.AudioContext ?? (window as unknown as { webkitAudioContext?: typeof AudioContext }).webkitAudioContext;
      if (!Ctor) return;
      try {
        this.ctx = new Ctor();
      } catch {
        return;
      }
      const ctx = this.ctx;
      this.master = ctx.createGain();
      this.master.gain.value = 0.9;
      const limiter = ctx.createDynamicsCompressor();
      limiter.threshold.value = -12;
      limiter.ratio.value = 8;
      this.master.connect(limiter).connect(ctx.destination);
      this.sfxBus = ctx.createGain();
      this.sfxBus.gain.value = this.sfxOn ? 0.8 : 0;
      this.sfxBus.connect(this.master);
      this.musicBus = ctx.createGain();
      this.musicBus.gain.value = this.musicOn ? 0.34 : 0;
      this.musicBus.connect(this.master);
      this.noise = ctx.createBuffer(1, ctx.sampleRate, ctx.sampleRate);
      const data = this.noise.getChannelData(0);
      for (let i = 0; i < data.length; i++) data[i] = Math.random() * 2 - 1;
    }
    if (this.ctx.state === 'suspended') void this.ctx.resume().catch(() => {});
  }

  get ready(): boolean {
    return this.ctx?.state === 'running';
  }

  setSfx(on: boolean): void {
    this.sfxOn = on;
    if (this.ctx) this.sfxBus.gain.setTargetAtTime(on ? 0.8 : 0, this.ctx.currentTime, 0.03);
  }

  setMusic(on: boolean): void {
    this.musicOn = on;
    if (this.ctx) this.musicBus.gain.setTargetAtTime(on ? 0.34 : 0, this.ctx.currentTime, 0.1);
  }

  /** Tab hidden / call interruption: stop the clock. `resume` is a no-op until unlocked. */
  suspend(): void {
    if (this.ctx?.state === 'running') void this.ctx.suspend().catch(() => {});
  }

  resume(): void {
    if (this.ctx?.state === 'suspended') void this.ctx.resume().catch(() => {});
    if (this.ctx) this.nextNote = this.ctx.currentTime + 0.1;
  }

  // --- synthesis helpers ---------------------------------------------------

  private tone(type: OscillatorType, f0: number, f1: number, dur: number, gain: number, when = 0, bus?: GainNode): void {
    const ctx = this.ctx!;
    const t = ctx.currentTime + when;
    const osc = ctx.createOscillator();
    const g = ctx.createGain();
    osc.type = type;
    osc.frequency.setValueAtTime(f0, t);
    if (f1 !== f0) osc.frequency.exponentialRampToValueAtTime(Math.max(20, f1), t + dur);
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(gain, t + 0.008);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    osc.connect(g).connect(bus ?? this.sfxBus);
    osc.start(t);
    osc.stop(t + dur + 0.02);
  }

  private burst(dur: number, gain: number, f0: number, f1: number, when = 0, type: BiquadFilterType = 'lowpass', bus?: GainNode): void {
    const ctx = this.ctx!;
    const t = ctx.currentTime + when;
    const src = ctx.createBufferSource();
    src.buffer = this.noise;
    src.loop = true;
    const filter = ctx.createBiquadFilter();
    filter.type = type;
    filter.frequency.setValueAtTime(f0, t);
    filter.frequency.exponentialRampToValueAtTime(Math.max(30, f1), t + dur);
    const g = ctx.createGain();
    g.gain.setValueAtTime(gain, t);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    src.connect(filter).connect(g).connect(bus ?? this.sfxBus);
    src.start(t, Math.random());
    src.stop(t + dur + 0.02);
  }

  play(name: Sfx, pitch = 1): void {
    const ctx = this.ctx;
    if (!ctx || ctx.state !== 'running' || !this.sfxOn) return;
    const gap = THROTTLE[name];
    if (gap) {
      const prev = this.last.get(name) ?? -1;
      if (ctx.currentTime - prev < gap) return;
      this.last.set(name, ctx.currentTime);
    }
    const p = pitch * (0.96 + Math.random() * 0.08);
    switch (name) {
      case 'shoot': this.tone('square', 520 * p, 180 * p, 0.09, 0.12); this.burst(0.05, 0.1, 5000, 900); break;
      case 'deploy': this.tone('sine', 300 * p, 620 * p, 0.07, 0.1); break;
      case 'gate': this.tone('triangle', 660 * p, 990 * p, 0.12, 0.16); this.tone('sine', 1320 * p, 1320 * p, 0.1, 0.06, 0.04); break;
      case 'gateBig':
        [0, 4, 7, 12, 16].forEach((semi, i) => this.tone('triangle', 440 * p * Math.pow(2, semi / 12), 440 * p * Math.pow(2, semi / 12), 0.16, 0.14, i * 0.045));
        break;
      case 'hit': this.burst(0.05, 0.14, 2600, 500); break;
      case 'unitDie': this.tone('square', 300 * p, 90 * p, 0.12, 0.07); break;
      case 'enemyDie': this.burst(0.11, 0.18, 1800, 220); this.tone('sawtooth', 200 * p, 60, 0.12, 0.08); break;
      case 'explosion': this.burst(0.5, 0.5, 900, 50); this.tone('sine', 120, 34, 0.42, 0.5); break;
      case 'bossRoar': this.tone('sawtooth', 90, 46, 1.1, 0.34); this.tone('sawtooth', 135, 60, 1.0, 0.2); this.burst(0.9, 0.2, 500, 120); break;
      case 'bossAttack': this.tone('sawtooth', 160 * p, 70, 0.34, 0.22); this.burst(0.22, 0.14, 1200, 200); break;
      case 'bossDie':
        for (let i = 0; i < 5; i++) { this.burst(0.5, 0.4, 1000, 60, i * 0.32); this.tone('sine', 140 - i * 16, 30, 0.4, 0.4, i * 0.32); }
        break;
      case 'cannonHit': this.burst(0.2, 0.36, 700, 90); this.tone('square', 150, 60, 0.2, 0.2); break;
      case 'victory':
        [0, 4, 7, 12, 7, 12, 16].forEach((semi, i) => this.tone('triangle', 523.25 * Math.pow(2, semi / 12), 523.25 * Math.pow(2, semi / 12), i === 6 ? 0.7 : 0.18, 0.2, i * 0.13));
        break;
      case 'defeat': [0, -2, -5, -9].forEach((semi, i) => this.tone('sawtooth', 220 * Math.pow(2, semi / 12), 210 * Math.pow(2, semi / 12), 0.36, 0.14, i * 0.24)); break;
      case 'click': this.tone('sine', 880, 660, 0.05, 0.12); break;
      case 'buy': this.tone('triangle', 660, 660, 0.08, 0.16); this.tone('triangle', 990, 990, 0.14, 0.16, 0.08); break;
      case 'deny': this.tone('square', 170, 140, 0.14, 0.1); break;
      case 'ability': this.tone('sawtooth', 220, 880, 0.3, 0.16); this.burst(0.3, 0.12, 400, 6000, 0, 'bandpass'); break;
      case 'warning': this.tone('square', 740, 740, 0.07, 0.07); this.tone('square', 740, 740, 0.07, 0.07, 0.12); break;
      case 'march': this.burst(0.05, 0.05, 500, 160); break;
    }
  }

  // --- music -----------------------------------------------------------------

  /** 0 = cruising, 1 = boss fight: adds the lead and opens the hat. */
  setIntensity(v: number): void {
    this.intensity = v;
  }

  startMusic(world: WorldId): void {
    this.world = world;
    this.stepIndex = 0;
    if (this.ctx) this.nextNote = this.ctx.currentTime + 0.1;
    if (!this.timer) this.timer = window.setInterval(() => this.schedule(), 60);
  }

  stopMusic(): void {
    window.clearInterval(this.timer);
    this.timer = 0;
  }

  private schedule(): void {
    const ctx = this.ctx;
    if (!ctx || ctx.state !== 'running' || !this.world || !this.musicOn) return;
    const song = SCALES[this.world];
    const stepDur = 60 / song.bpm / 4;
    if (this.nextNote < ctx.currentTime) this.nextNote = ctx.currentTime + 0.05;
    while (this.nextNote < ctx.currentTime + 0.18) {
      const when = this.nextNote - ctx.currentTime;
      const s = this.stepIndex % 16;
      const bar = Math.floor(this.stepIndex / 16);
      const note = (degree: number, octave: number) => {
        const sc = song.scale;
        const d = ((degree % sc.length) + sc.length) % sc.length;
        return song.root * Math.pow(2, octave + (sc[d]! + 12 * Math.floor(degree / sc.length)) / 12);
      };
      const chord = [0, 0, 3, 2][bar % 4]!;
      if (s % 4 === 0) { this.tone('sine', 150, 42, 0.16, 0.9, when, this.musicBus); }
      if (s % 2 === 1 || this.intensity > 0.5) this.burst(0.03, s % 4 === 2 ? 0.2 : 0.09, 9000, 6000, when, 'highpass', this.musicBus);
      if (s % 8 === 4) this.burst(0.1, 0.3, 2400, 700, when, 'bandpass', this.musicBus);
      if ([0, 3, 6, 8, 11, 14].includes(s)) this.tone('sawtooth', note(chord, -1), note(chord, -1), stepDur * 1.6, 0.34, when, this.musicBus);
      if (s % 2 === 0) {
        const arp = [0, 2, 4, 2, 5, 4, 2, 1][(s / 2 + bar) % 8]!;
        this.tone('triangle', note(chord + arp, 1), note(chord + arp, 1), stepDur * 1.2, 0.16, when, this.musicBus);
      }
      if (this.intensity > 0.5 && s % 4 === 2) {
        const lead = [4, 5, 7, 5][bar % 4]!;
        this.tone('square', note(chord + lead, 2), note(chord + lead, 2), stepDur * 2, 0.07, when, this.musicBus);
      }
      this.nextNote += stepDur;
      this.stepIndex++;
    }
  }
}
