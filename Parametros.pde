// ═════════════════════════════════════════════════════════════
//  Parametros globales
// ═════════════════════════════════════════════════════════════

// 1. FORMA
float BASE_RADIUS   = 140.0;
float WAIST_RADIUS  =  70.0;
float TOP_RADIUS    = 120.0;
float TOTAL_HEIGHT  = 340.0;
float WAIST_POS     =  0.45;
float BASE_BULGE    =  0.22;

// 2. SUPERFICIE
float RIDGE_COUNT   =  80.0;
float RIDGE_DEPTH   =   4.5;

// 3. TRANSFORMACION
float TWIST_TOTAL   =  1.727;

// 4. BORDE
float LOBE_COUNT    =   4.0;
float LOBE_AMP      =  28.0;
float LOBE_START    =  0.72;

// 5. GOLPES EN CINTURA
float DENT_COUNT    =   5.0;
float DENT_AMP      =  18.0;
float DENT_WIDTH    =  0.12;
float DENT_CENTER   =  0.45;
float DENT_SPREAD   =  0.18;
float DENT_SEED     =   7.0;

// 6. RESOLUCION
//    Vista interactiva reducida (fluida); export STL completo.
int   LEVELS_VIEW    = 160;
int   SLICES_VIEW    = 240;
int   LEVELS_EXPORT  = 320;
int   SLICES_EXPORT  = 480;

// 7. COMPORTAMIENTO
boolean ANIMATE     = false;
float   ANIM_SPEED  = 0.004;
float   SHININESS   = 80.0;
float   camDist     = 700;
float   camRotY     = 0.5;
float   camRotX     = 0.25;

// MATERIAL DE LA VASIJA (independiente del tema de UI)
color   COL_FILL    = color(52, 100, 82);
color   COL_SPEC    = color(160, 200, 180);

// ── LAYOUT (disenado para FullHD 1920x1080) ──────────────────
int   MARGIN       =  20;   // margen del lienzo a las tarjetas
int   CARD_R       =  18;   // radio de esquinas de tarjeta
int   PANEL_X      =  20;   // tarjeta panel: esquina
int   PANEL_Y      =  20;
int   PANEL_W      = 400;   // ancho de la tarjeta panel
int   PANEL_PAD    =  26;   // padding interno de la tarjeta
int   LABEL_W      = 140;
int   SLIDER_H     =  16;
int   SLIDER_GAP   =   8;
int   VALUE_W      =  56;   // columna de valor (azul, derecha)
int   BTN_H        =  38;

// borde izquierdo de la tarjeta 3D / limite del arrastre orbital
int viewX() { return PANEL_X + PANEL_W + MARGIN; }

// INTERNAS
float WALL_THICKNESS = 8.0;   // radial; controlado por slider (FORMA)
PVector[][] meshOuter;
PVector[][] meshInner;

PShape  vaseShape;            // geometria retenida en GPU
boolean meshDirty  = true;    // true -> reconstruir PShape

float   animPhase  = 0;
float   prevMouseX, prevMouseY;
boolean dragging3D = false;
int     activeSlider = -1;
