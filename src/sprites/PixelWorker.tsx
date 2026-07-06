import { makeStyles } from "@fluentui/react-components";
import { useEffect, useRef } from "react";
import { CHAR_H, CHAR_W, CHAR_ZOOM, charIdx, registerSprite, type SpriteAnim } from "./spriteEngine";

const useStyles = makeStyles({
  canvas: {
    imageRendering: "pixelated",
    display: "block"
  }
});

export function PixelWorker({ agentId, anim }: { agentId: string; anim: SpriteAnim }) {
  const styles = useStyles();
  const ref = useRef<HTMLCanvasElement>(null);
  const animRef = useRef(anim);
  animRef.current = anim; // anim updates flow through the ref — no re-register

  useEffect(() => {
    if (!ref.current) return;
    return registerSprite(ref.current, charIdx(agentId), () => animRef.current);
  }, [agentId]);

  return (
    <canvas
      ref={ref}
      className={styles.canvas}
      width={CHAR_W * CHAR_ZOOM}
      height={CHAR_H * CHAR_ZOOM}
      aria-hidden="true"
    />
  );
}
