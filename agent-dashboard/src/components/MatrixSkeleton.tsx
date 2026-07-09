import { makeStyles } from "@fluentui/react-components";
import { useEffect, useRef } from "react";

// Port of the legacy matrix-rain loading skeleton (lines 1004-1032).

const useStyles = makeStyles({
  grid: {
    display: "grid",
    gridTemplateColumns: "repeat(auto-fill, minmax(240px, 1fr))",
    gap: "16px"
  },
  card: {
    height: "280px",
    overflow: "hidden",
    borderRadius: "8px",
    backgroundColor: "#181825",
    border: "1px solid #2a2b40"
  }
});

function MatrixCanvas() {
  const ref = useRef<HTMLCanvasElement>(null);
  useEffect(() => {
    const canvas = ref.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d")!;
    const cols = Math.floor(canvas.width / 12);
    const drops = Array(cols).fill(1);
    const id = setInterval(() => {
      ctx.fillStyle = "rgba(30,30,46,0.12)";
      ctx.fillRect(0, 0, canvas.width, canvas.height);
      drops.forEach((y, x) => {
        const bright = y < 2;
        ctx.fillStyle = bright ? "#aaffaa" : "#00FF41";
        ctx.globalAlpha = bright ? 0.9 : 0.35;
        ctx.font = "12px monospace";
        ctx.fillText(String.fromCharCode(65 + Math.floor(Math.random() * 26)), x * 12, y * 14);
        ctx.globalAlpha = 1;
        if (y * 14 > canvas.height && Math.random() > 0.975) drops[x] = 0;
        drops[x]++;
      });
    }, 80);
    return () => clearInterval(id);
  }, []);
  return <canvas ref={ref} width={260} height={270} />;
}

export function MatrixSkeleton() {
  const styles = useStyles();
  return (
    <div className={styles.grid} data-testid="matrix-skeleton">
      {Array.from({ length: 4 }, (_, i) => (
        <div key={i} className={styles.card}>
          <MatrixCanvas />
        </div>
      ))}
    </div>
  );
}
