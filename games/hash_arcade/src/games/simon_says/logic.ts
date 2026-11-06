export type Check = 'ok' | 'round-done' | 'fail';

/** Judges the latest input against the sequence so far. */
export function checkInput(sequence: number[], inputs: number[]): Check {
  const i = inputs.length - 1;
  if (inputs[i] !== sequence[i]) return 'fail';
  return inputs.length === sequence.length ? 'round-done' : 'ok';
}

/** Playback speeds up with length, floored so it stays readable. */
export const stepMs = (length: number) => Math.max(260, 620 - length * 25);

export const PAD_TONES = [329.6, 392, 523.3, 659.3];
