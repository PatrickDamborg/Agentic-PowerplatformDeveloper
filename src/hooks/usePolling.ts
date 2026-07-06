import { useCallback, useEffect, useRef, useState } from "react";

/**
 * Generic polling hook: runs `fn` immediately and then every `intervalMs`,
 * pausing while the tab is hidden (same behavior as the legacy 1-second
 * countdown loop). `enabled=false` stops polling entirely.
 */
export function usePolling<T>(
  fn: () => Promise<T>,
  intervalMs: number,
  enabled = true,
  deps: unknown[] = []
) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(enabled);
  const [error, setError] = useState<Error | null>(null);
  const fnRef = useRef(fn);
  fnRef.current = fn;
  const inFlight = useRef(false);
  const [tick, setTick] = useState(0);

  const refresh = useCallback(() => setTick((t) => t + 1), []);

  useEffect(() => {
    if (!enabled) return;
    let cancelled = false;

    const run = async () => {
      if (inFlight.current || document.hidden) return;
      inFlight.current = true;
      try {
        const result = await fnRef.current();
        if (!cancelled) {
          setData(result);
          setError(null);
        }
      } catch (e) {
        if (!cancelled) setError(e as Error);
      } finally {
        inFlight.current = false;
        if (!cancelled) setLoading(false);
      }
    };

    run();
    const id = setInterval(run, intervalMs);
    return () => {
      cancelled = true;
      clearInterval(id);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [enabled, intervalMs, tick, ...deps]);

  return { data, loading, error, refresh };
}
