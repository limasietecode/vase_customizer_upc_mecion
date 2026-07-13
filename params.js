// ═════════════════════════════════════════════════════════════
//  Parametros globales — puerto web de Parametros.pde + Slider.pde
//  Unica fuente de verdad: SLIDER_DEFS. state[] guarda los valores
//  actuales por clave (igual que Slider.val en la version Processing).
// ═════════════════════════════════════════════════════════════

const SLIDER_DEFS = [
  { cat: "FORMA",          key: "base_radius",    label: "BASE RADIUS",     def: 140,   min: 30,   max: 260,  isInt: false },
  { cat: "FORMA",          key: "waist_radius",   label: "WAIST RADIUS",    def: 70,    min: 10,   max: 200,  isInt: false },
  { cat: "FORMA",          key: "top_radius",     label: "TOP RADIUS",      def: 120,   min: 20,   max: 260,  isInt: false },
  { cat: "FORMA",          key: "total_height",   label: "TOTAL HEIGHT",    def: 340,   min: 100,  max: 600,  isInt: false },
  { cat: "FORMA",          key: "waist_position", label: "WAIST POSITION",  def: 0.45,  min: 0.2,  max: 0.8,  isInt: false },
  { cat: "FORMA",          key: "base_bulge",     label: "BASE BULGE",      def: 0.22,  min: 0.05, max: 0.45, isInt: false },
  { cat: "FORMA",          key: "wall_thickness", label: "WALL THICKNESS",  def: 8,     min: 2,    max: 24,   isInt: false },
  { cat: "SUPERFICIE",     key: "ridge_count",    label: "RIDGE COUNT",     def: 80,    min: 4,    max: 180,  isInt: true },
  { cat: "SUPERFICIE",     key: "ridge_depth",    label: "RIDGE DEPTH",     def: 4.5,   min: 0,    max: 20,   isInt: false },
  { cat: "TRANSFORMACION", key: "twist",          label: "TWIST",          def: 0.55,  min: 0,    max: 3.0,  isInt: false },
  { cat: "BORDE",          key: "lobe_count",     label: "LOBE COUNT",      def: 4,     min: 1,    max: 10,   isInt: true },
  { cat: "BORDE",          key: "lobe_amplitude", label: "LOBE AMPLITUDE",  def: 28,    min: 0,    max: 80,   isInt: false },
  { cat: "BORDE",          key: "lobe_start",     label: "LOBE START",      def: 0.72,  min: 0.3,  max: 0.95, isInt: false },
  { cat: "GOLPES",         key: "dent_count",     label: "DENT COUNT",      def: 5,     min: 1,    max: 12,   isInt: true },
  { cat: "GOLPES",         key: "dent_amplitude", label: "DENT AMPLITUDE",  def: 18,    min: 0,    max: 60,   isInt: false },
  { cat: "GOLPES",         key: "dent_width",     label: "DENT WIDTH",      def: 0.12,  min: 0.02, max: 0.4,  isInt: false },
  { cat: "GOLPES",         key: "dent_center",    label: "DENT CENTER",     def: 0.45,  min: 0.2,  max: 0.8,  isInt: false },
  { cat: "GOLPES",         key: "dent_spread",    label: "DENT SPREAD",     def: 0.18,  min: 0.05, max: 0.4,  isInt: false },
  { cat: "GOLPES",         key: "dent_seed",      label: "DENT SEED",       def: 7,     min: 1,    max: 20,   isInt: true },
  { cat: "COMPORTAMIENTO", key: "anim_speed",     label: "ANIM SPEED",      def: 0.004, min: 0,    max: 0.03, isInt: false },
  { cat: "COMPORTAMIENTO", key: "shininess",      label: "SHININESS",       def: 80,    min: 5,    max: 150,  isInt: false },
];

// Resolucion: reducida para vista interactiva fluida en navegador,
// completa para export STL (igual proposito que en Processing, pero
// los numeros de la vista se bajaron para que WebGL/JS rindan bien).
const LEVELS_VIEW   = 70;
const SLICES_VIEW   = 100;
const LEVELS_EXPORT = 320;
const SLICES_EXPORT = 480;

const MAX_SNAPSHOTS = 20;

// Material de la vasija (independiente del tema de UI)
const COL_FILL = [52, 100, 82];
const COL_SPEC = [160, 200, 180];

function makeDefaultState() {
  const s = {};
  for (const d of SLIDER_DEFS) s[d.key] = d.def;
  return s;
}

const state = makeDefaultState();

function clampToSlider(def, v) {
  v = Math.min(def.max, Math.max(def.min, v));
  if (def.isInt) v = Math.round(v);
  return v;
}

function sliderDef(key) {
  return SLIDER_DEFS.find((d) => d.key === key);
}
