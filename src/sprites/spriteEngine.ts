// Port of the legacy office-worker sprite engine (agent-monitor.html 742-803).
// Same architecture: ONE shared requestAnimationFrame loop drawing every
// registered canvas. 6 characters, 16×32 px frames drawn at 3× zoom,
// nearest-neighbour. The loop self-stops when the registry empties.
import char0 from "./char_0.png";
import char1 from "./char_1.png";
import char2 from "./char_2.png";
import char3 from "./char_3.png";
import char4 from "./char_4.png";
import char5 from "./char_5.png";

export const CHAR_W = 16;
export const CHAR_H = 32;
export const CHAR_ZOOM = 3;

export type SpriteAnim = "idle" | "typing" | "error";

const ANIM_DEF: Record<SpriteAnim, { frames: number[]; ms: number }> = {
  idle: { frames: [0, 1], ms: 900 },
  typing: { frames: [4, 5, 6], ms: 220 },
  error: { frames: [2, 3], ms: 140 }
};

const CHAR_IMGS = [char0, char1, char2, char3, char4, char5].map((src) => {
  const img = new Image();
  img.src = src;
  return img;
});

export function charIdx(id: string): number {
  let h = 0;
  for (let i = 0; i < id.length; i++) h = (Math.imul(31, h) + id.charCodeAt(i)) | 0;
  return Math.abs(h) % CHAR_IMGS.length;
}

interface Entry {
  charIdx: number;
  getAnim: () => SpriteAnim;
  anim: SpriteAnim;
  tick: number;
  fi: number;
}

const registry = new Map<HTMLCanvasElement, Entry>();
let rafRunning = false;
let lastTs = 0;

function tickLoop(ts: number) {
  if (!registry.size) {
    rafRunning = false;
    return;
  }
  requestAnimationFrame(tickLoop);
  const dt = Math.min(ts - lastTs, 100);
  lastTs = ts;
  for (const [canvas, s] of registry) {
    const anim = s.getAnim();
    if (anim !== s.anim) {
      s.anim = anim;
      s.tick = 0;
      s.fi = 0;
    }
    const af = ANIM_DEF[s.anim];
    s.tick += dt;
    if (s.tick >= af.ms) {
      s.tick = 0;
      s.fi = (s.fi + 1) % af.frames.length;
    }
    const img = CHAR_IMGS[s.charIdx];
    if (!img.complete) continue;
    const ctx = canvas.getContext("2d");
    if (!ctx) continue;
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.imageSmoothingEnabled = false;
    ctx.drawImage(
      img,
      af.frames[s.fi] * CHAR_W, 0, CHAR_W, CHAR_H,
      0, 0, CHAR_W * CHAR_ZOOM, CHAR_H * CHAR_ZOOM
    );
  }
}

/** Register a canvas; returns the unregister cleanup for useEffect. */
export function registerSprite(
  canvas: HTMLCanvasElement,
  idx: number,
  getAnim: () => SpriteAnim
): () => void {
  registry.set(canvas, { charIdx: idx, getAnim, anim: getAnim(), tick: 0, fi: 0 });
  if (!rafRunning) {
    rafRunning = true;
    lastTs = performance.now();
    requestAnimationFrame(tickLoop);
  }
  return () => registry.delete(canvas);
}
