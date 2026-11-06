/**
 * Fixed-size pool of reusable objects. `acquire` never allocates: when every
 * item is busy it hands back the oldest one, so an effect can be cut short
 * but a spawn can never fail or grow memory.
 */
export class ObjectPool<T> {
  private readonly items: T[] = [];
  private readonly busy: boolean[] = [];
  private cursor = 0;

  constructor(size: number, create: (index: number) => T) {
    for (let i = 0; i < size; i++) {
      this.items.push(create(i));
      this.busy.push(false);
    }
  }

  get size(): number {
    return this.items.length;
  }

  acquire(): T {
    const n = this.items.length;
    for (let k = 0; k < n; k++) {
      const i = (this.cursor + k) % n;
      if (!this.busy[i]) {
        this.busy[i] = true;
        this.cursor = (i + 1) % n;
        return this.items[i]!;
      }
    }
    const i = this.cursor;
    this.cursor = (i + 1) % n;
    return this.items[i]!;
  }

  release(item: T): void {
    const i = this.items.indexOf(item);
    if (i >= 0) this.busy[i] = false;
  }

  forEachBusy(fn: (item: T) => void): void {
    for (let i = 0; i < this.items.length; i++) if (this.busy[i]) fn(this.items[i]!);
  }

  releaseAll(): void {
    this.busy.fill(false);
  }
}
