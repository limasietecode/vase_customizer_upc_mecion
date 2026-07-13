// ═════════════════════════════════════════════════════════════
//  Slider — UNICA fuente de verdad de cada parametro:
//  categoria (encabezado del panel), clave JSON (presets),
//  valor por defecto (doble click = reset), rango y tipo.
//
//  v8: applySliders() ahora asigna por CLAVE, no por indice:
//  agregar o reordenar sliders ya no rompe nada en silencio.
//  Nuevo parametro: wall_thickness (grosor de pared).
// ═════════════════════════════════════════════════════════════

Slider[] sliders;

class Slider {
  String  cat;      // encabezado de seccion en el panel
  String  key;      // clave estable para el preset JSON
  String  label;
  float   val, def, minV, maxV;
  int     x, y, w;
  boolean isInt;

  Slider(String category, String jsonKey, String lbl,
         float v, float mn, float mx, boolean integer) {
    cat = category; key = jsonKey; label = lbl;
    val = v; def = v; minV = mn; maxV = mx; isInt = integer;
  }

  void setPos(int px, int py, int pw) { x = px; y = py; w = pw; }

  void reset() { val = def; }

  void setValue(float v) {
    val = constrain(v, minV, maxV);
    if (isInt) val = round(val);
  }

  void updateFromMouse(int mx) {
    val = map(constrain(mx, x, x + w), x, x + w, minV, maxV);
    if (isInt) val = round(val);
  }

  boolean isOver(int mx, int my) {
    return mx >= x - 6 && mx <= x + w + 6 &&
           my >= y - 2 && my <= y + SLIDER_H + 2;
  }

  String displayValue() {
    return isInt ? str((int)val) : nf(val, 1, 2);
  }

  void draw() {
    boolean hov = isOver(mouseX, mouseY) || activeSlider == indexOf(this);

    // pista fina
    noStroke();
    fill(UI_TRACK);
    rect(x, y + SLIDER_H/2 - 2, w, 4, 2);

    // progreso
    float fillW = map(val, minV, maxV, 0, w);
    fill(UI_FILL_SL);
    rect(x, y + SLIDER_H/2 - 2, fillW, 4, 2);

    // pulgar circular
    float tx = map(val, minV, maxV, x, x + w);
    fill(hov ? UI_THUMB_HOV : UI_THUMB);
    ellipse(tx, y + SLIDER_H/2, hov ? 13 : 11, hov ? 13 : 11);

    // etiqueta
    textFont(F_LABEL);
    fill(hov ? UI_LABEL_HOV : UI_LABEL);
    textAlign(LEFT, CENTER);
    text(label, PANEL_X + PANEL_PAD, y + SLIDER_H/2);

    // valor en azul, alineado al borde derecho del contenido
    textFont(F_VALUE);
    fill(UI_VALUE);
    textAlign(RIGHT, CENTER);
    text(displayValue(), PANEL_X + PANEL_W - PANEL_PAD, y + SLIDER_H/2);
  }
}

void initSliders() {
  sliders = new Slider[] {
    // cat                 clave JSON        etiqueta            val    min    max   int
    new Slider("FORMA",          "base_radius",    "BASE RADIUS",     140,    30,   260, false),
    new Slider("FORMA",          "waist_radius",   "WAIST RADIUS",     70,    10,   200, false),
    new Slider("FORMA",          "top_radius",     "TOP RADIUS",      120,    20,   260, false),
    new Slider("FORMA",          "total_height",   "TOTAL HEIGHT",    340,   100,   600, false),
    new Slider("FORMA",          "waist_position", "WAIST POSITION", 0.45,   0.2,   0.8, false),
    new Slider("FORMA",          "base_bulge",     "BASE BULGE",     0.22,  0.05,  0.45, false),
    new Slider("FORMA",          "wall_thickness", "WALL THICKNESS",    8,     2,    24, false),
    new Slider("SUPERFICIE",     "ridge_count",    "RIDGE COUNT",      80,     4,   180, true),
    new Slider("SUPERFICIE",     "ridge_depth",    "RIDGE DEPTH",     4.5,     0,    20, false),
    new Slider("TRANSFORMACION", "twist",          "TWIST",          0.55,     0,   3.0, false),
    new Slider("BORDE",          "lobe_count",     "LOBE COUNT",        4,     1,    10, true),
    new Slider("BORDE",          "lobe_amplitude", "LOBE AMPLITUDE",   28,     0,    80, false),
    new Slider("BORDE",          "lobe_start",     "LOBE START",     0.72,   0.3,  0.95, false),
    new Slider("GOLPES",         "dent_count",     "DENT COUNT",        5,     1,    12, true),
    new Slider("GOLPES",         "dent_amplitude", "DENT AMPLITUDE",   18,     0,    60, false),
    new Slider("GOLPES",         "dent_width",     "DENT WIDTH",     0.12,  0.02,   0.4, false),
    new Slider("GOLPES",         "dent_center",    "DENT CENTER",    0.45,   0.2,   0.8, false),
    new Slider("GOLPES",         "dent_spread",    "DENT SPREAD",    0.18,  0.05,   0.4, false),
    new Slider("GOLPES",         "dent_seed",      "DENT SEED",         7,     1,    20, true),
    new Slider("COMPORTAMIENTO", "anim_speed",     "ANIM SPEED",    0.004,     0,  0.03, false),
    new Slider("COMPORTAMIENTO", "shininess",      "SHININESS",        80,     5,   150, false),
  };
  repositionSliders();
}

void repositionSliders() {
  int sx     = PANEL_X + PANEL_PAD + LABEL_W + 10;
  int trackW = PANEL_W - PANEL_PAD * 2 - LABEL_W - VALUE_W - 20;
  int curY   = PANEL_Y + PANEL_PAD + 58;   // debajo de titulo + subtitulo

  String lastCat = "";
  for (int i = 0; i < sliders.length; i++) {
    if (!sliders[i].cat.equals(lastCat)) {
      if (!lastCat.equals("")) curY += 12;   // espacio para la regla
      curY += 24;                            // espacio para el encabezado
      lastCat = sliders[i].cat;
    }
    sliders[i].setPos(sx, curY, trackW);
    curY += SLIDER_H + SLIDER_GAP;
  }
}

// util para hover persistente durante arrastre
int indexOf(Slider s) {
  for (int i = 0; i < sliders.length; i++) if (sliders[i] == s) return i;
  return -1;
}

// Asignacion por clave: robusta ante reordenar / insertar sliders
void applySliders() {
  for (Slider s : sliders) {
    String k = s.key;
    if      (k.equals("base_radius"))    BASE_RADIUS    = s.val;
    else if (k.equals("waist_radius"))   WAIST_RADIUS   = s.val;
    else if (k.equals("top_radius"))     TOP_RADIUS     = s.val;
    else if (k.equals("total_height"))   TOTAL_HEIGHT   = s.val;
    else if (k.equals("waist_position")) WAIST_POS      = s.val;
    else if (k.equals("base_bulge"))     BASE_BULGE     = s.val;
    else if (k.equals("wall_thickness")) WALL_THICKNESS = s.val;
    else if (k.equals("ridge_count"))    RIDGE_COUNT    = s.val;
    else if (k.equals("ridge_depth"))    RIDGE_DEPTH    = s.val;
    else if (k.equals("twist"))          TWIST_TOTAL    = s.val * PI;
    else if (k.equals("lobe_count"))     LOBE_COUNT     = s.val;
    else if (k.equals("lobe_amplitude")) LOBE_AMP       = s.val;
    else if (k.equals("lobe_start"))     LOBE_START     = s.val;
    else if (k.equals("dent_count"))     DENT_COUNT     = s.val;
    else if (k.equals("dent_amplitude")) DENT_AMP       = s.val;
    else if (k.equals("dent_width"))     DENT_WIDTH     = s.val;
    else if (k.equals("dent_center"))    DENT_CENTER    = s.val;
    else if (k.equals("dent_spread"))    DENT_SPREAD    = s.val;
    else if (k.equals("dent_seed"))      DENT_SEED      = s.val;
    else if (k.equals("anim_speed"))     ANIM_SPEED     = s.val;
    else if (k.equals("shininess"))      SHININESS      = s.val;
  }
}
