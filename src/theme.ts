import { createDarkTheme, type BrandVariants, type Theme } from "@fluentui/react-components";

// Brand ramp centred on the legacy dashboard's purple accent, tuned for the
// "dark office" backdrop the pixel workers live in.
const pixelBrand: BrandVariants = {
  10: "#060518",
  20: "#16142f",
  30: "#221d4c",
  40: "#2d2565",
  50: "#392e7f",
  60: "#453799",
  70: "#5240b4",
  80: "#5f4ad0",
  90: "#6c55ec",
  100: "#7f5af0",
  110: "#8f6ef3",
  120: "#9f82f5",
  130: "#af95f7",
  140: "#bfa9f9",
  150: "#cfbdfb",
  160: "#dfd2fc"
};

export const pixelDarkTheme: Theme = {
  ...createDarkTheme(pixelBrand),
  colorNeutralBackground1: "#1e1e2e",
  colorNeutralBackground2: "#181825",
  colorNeutralBackground3: "#11111b",
  colorNeutralBackground1Hover: "#26263a",
  colorNeutralBackground1Pressed: "#2a2a40",
  colorNeutralStroke1: "#31324a",
  colorNeutralStroke2: "#2a2b40"
};

// Retro accent colors shared by the pixel components (HUD, speech bubbles,
// matrix skeleton) — deliberately outside the Fluent token system.
export const retro = {
  green: "#00ff41",
  greenSoft: "#aaffaa",
  sky: "#7dcfff",
  orange: "#ffb86c",
  red: "#ff5555",
  amber: "#f9e2af",
  muted: "#6c7086",
  fontPixel: '"VT323", monospace',
  fontMono: '"Share Tech Mono", monospace'
};
