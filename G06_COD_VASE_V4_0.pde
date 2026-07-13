// ═════════════════════════════════════════════════════════════
//  VASIJA ORGANICA — customizador generativo
//  Archivo principal
//
//  v9 — rediseno visual "clean / minimal" para FullHD:
//   - Tarjetas flotantes (panel + viewport) sobre lienzo gris.
//   - Botones pill: primario negro, secundarios gris, acento azul.
//   - Sliders de linea fina con pulgar circular; valor en azul.
//   - Titulo en dos tonos. Modo claro por defecto (toggle: luna/sol).
//   - Layout disenado para 1920x1080. En pantallas de menos de
//     ~1000 px de alto los sliders y botones pueden solaparse.
// ═════════════════════════════════════════════════════════════

void setup() {
  fullScreen(P3D);              // FullHD: ocupa toda la pantalla
  // size(1920, 1000, P3D);     // alternativa en ventana
  smooth(8);
  initFonts();
  aplicarTema();
  initSliders();
  buildMesh();
  saveSnapshot();
}

void draw() {
  procesarPresetPendiente();

  background(UI_BG);

  // ── Pre-pase 2D: tarjeta del viewport (sin tocar el z-buffer)
  camera(); perspective(); noLights();
  hint(DISABLE_DEPTH_TEST);
  hint(DISABLE_DEPTH_MASK);
  drawViewCard();
  hint(ENABLE_DEPTH_MASK);
  hint(ENABLE_DEPTH_TEST);

  // ── Pase 3D
  float ex = camDist * sin(camRotY) * cos(camRotX);
  float ey = camDist * sin(camRotX);
  float ez = camDist * cos(camRotY) * cos(camRotX);

  int vx = viewX();
  int viewW = width - vx - MARGIN;

  camera(ex, -ey, ez, 0, 0, 0, 0, 1, 0);
  perspective(PI/3.0, (float)viewW / (height - MARGIN*2), 10, 5000);
  translate(-(vx - width/2) * 0.5, 0, 0);

  ambientLight(45, 50, 55);
  directionalLight(210, 230, 220,  0.5,  0.7, -0.6);
  directionalLight( 60,  85, 100, -0.7, -0.3,  0.4);
  directionalLight(120, 140, 130,  0.0, -0.8,  0.2);
  lightSpecular(180, 210, 195);

  if (ANIMATE && ANIM_SPEED > 0) {
    animPhase += ANIM_SPEED;
    buildMesh();
  }

  rebuildShapeIfNeeded();
  shape(vaseShape);

  // ── Overlay 2D: panel + feedback
  hint(DISABLE_DEPTH_TEST);
  camera(); noLights(); perspective();
  drawPanel();
  drawFeedback();
  hint(ENABLE_DEPTH_TEST);
}

// ── Perfil axial ─────────────────────────────────────────────
float profileRadius(float zNorm) {
  float zFlip = 1.0 - zNorm;
  float[] pz = { 0.0, BASE_BULGE, WAIST_POS, 1.0 };
  float[] pr = { BASE_RADIUS, BASE_RADIUS, WAIST_RADIUS, TOP_RADIUS };

  int seg = pz.length - 2;
  for (int i = 0; i < pz.length - 1; i++) {
    if (zFlip <= pz[i+1]) { seg = i; break; }
  }
  float t  = constrain((zFlip - pz[seg]) / (pz[seg+1] - pz[seg]), 0, 1);
  float ts = t * t * (3.0 - 2.0 * t);
  return lerp(pr[seg], pr[seg+1], ts);
}

// ── Envolvente lobulos ───────────────────────────────────────
float lobeEnvelope(float zNorm) {
  float zFlip = 1.0 - zNorm;
  if (zFlip < LOBE_START) return 0.0;
  float t = (zFlip - LOBE_START) / (1.0 - LOBE_START);
  return t * t * (3.0 - 2.0 * t);
}

// ── Envolvente golpes cintura ────────────────────────────────
float dentEnvelope(float zNorm) {
  float zFlip = 1.0 - zNorm;
  float dist  = abs(zFlip - DENT_CENTER);
  if (dist > DENT_SPREAD * 2.5) return 0.0;
  float t = dist / DENT_SPREAD;
  return exp(-t * t * 2.5);
}

// ── buildMesh ────────────────────────────────────────────────
void buildMesh() {
  buildMeshAt(LEVELS_VIEW, SLICES_VIEW);
}

void buildMeshAt(int levels, int slices) {
  meshOuter = new PVector[levels][slices];
  meshInner = new PVector[levels][slices];

  float phase = animPhase * TWO_PI;

  float[] dentAngles = new float[(int)DENT_COUNT];
  float[] dentMags   = new float[(int)DENT_COUNT];
  randomSeed((int)DENT_SEED);
  for (int d = 0; d < (int)DENT_COUNT; d++) {
    dentAngles[d] = random(TWO_PI);
    dentMags[d]   = random(0.6, 1.0);
  }

  for (int i = 0; i < levels; i++) {
    float zNorm   = (float)i / (levels - 1);
    float zOuter  = (zNorm - 0.5) * TOTAL_HEIGHT;
    float zInner  = map(zNorm, 0, 1, -TOTAL_HEIGHT/2.0, TOTAL_HEIGHT/2.0 - WALL_THICKNESS);

    float r       = profileRadius(zNorm);
    float twist   = TWIST_TOTAL * zNorm;
    float lobEnv  = lobeEnvelope(zNorm);
    float dentEnv = dentEnvelope(zNorm);

    for (int j = 0; j < slices; j++) {
      float theta = (TWO_PI / slices) * j + twist;

      float ridge = RIDGE_DEPTH * cos(RIDGE_COUNT * theta + phase * 2.0);
      float lobe  = LOBE_AMP * lobEnv * cos(LOBE_COUNT * (theta - twist * 0.5) + phase);
      float dent  = 0;
      for (int d = 0; d < (int)DENT_COUNT; d++) {
        float angDist = theta - (dentAngles[d] + phase * 0.35);
        float angEnv  = exp(-angDist * angDist / (2.0 * DENT_WIDTH * DENT_WIDTH));
        dent -= DENT_AMP * dentMags[d] * angEnv * dentEnv;
      }

      float rFinalOuter = max(r + ridge + lobe + dent, 4.0);
      float rFinalInner = max(rFinalOuter - WALL_THICKNESS, 1.0);

      meshOuter[i][j] = new PVector(rFinalOuter * cos(theta), zOuter, rFinalOuter * sin(theta));
      meshInner[i][j] = new PVector(rFinalInner * cos(theta), zInner, rFinalInner * sin(theta));
    }
  }
  meshDirty = true;
}

// ── PShape retenido ──────────────────────────────────────────
void rebuildShapeIfNeeded() {
  if (!meshDirty) return;
  meshDirty = false;

  int L = meshOuter.length;
  int S = meshOuter[0].length;

  PVector[][] nOut = new PVector[L][S];
  PVector[][] nInn = new PVector[L][S];
  for (int i = 0; i < L; i++) {
    int ii = min(i, L - 2);
    for (int j = 0; j < S; j++) {
      int jn = (j + 1) % S;

      PVector v0 = meshOuter[ii][j];
      PVector n  = PVector.sub(meshOuter[ii][jn], v0)
                          .cross(PVector.sub(meshOuter[ii+1][j], v0));
      n.normalize();
      nOut[i][j] = n;

      PVector w0 = meshInner[ii][j];
      PVector m  = PVector.sub(meshInner[ii][jn], w0)
                          .cross(PVector.sub(meshInner[ii+1][j], w0));
      m.normalize();
      m.mult(-1);
      nInn[i][j] = m;
    }
  }

  vaseShape = createShape();
  vaseShape.beginShape(TRIANGLES);
  vaseShape.noStroke();
  vaseShape.fill(COL_FILL);
  vaseShape.specular(COL_SPEC);
  vaseShape.shininess(SHININESS);

  for (int i = 0; i < L - 1; i++) {
    for (int j = 0; j < S; j++) {
      int jn = (j + 1) % S;
      addQuad(meshOuter[i][j],   nOut[i][j],
              meshOuter[i+1][j], nOut[i+1][j],
              meshOuter[i][jn],  nOut[i][jn],
              meshOuter[i+1][jn], nOut[i+1][jn]);
      addQuad(meshInner[i][j],   nInn[i][j],
              meshInner[i+1][j], nInn[i+1][j],
              meshInner[i][jn],  nInn[i][jn],
              meshInner[i+1][jn], nInn[i+1][jn]);
    }
  }

  PVector nUp = new PVector(0, -1, 0);
  for (int j = 0; j < S; j++) {
    int jn = (j + 1) % S;
    addQuad(meshOuter[0][j],  nUp,
            meshInner[0][j],  nUp,
            meshOuter[0][jn], nUp,
            meshInner[0][jn], nUp);
  }

  int bot = L - 1;
  PVector cOuter = new PVector(0, meshOuter[bot][0].y, 0);
  PVector cInner = new PVector(0, meshInner[bot][0].y, 0);
  PVector nDown  = new PVector(0,  1, 0);
  PVector nFloor = new PVector(0, -1, 0);
  for (int j = 0; j < S; j++) {
    int jn = (j + 1) % S;
    addTri(cOuter, meshOuter[bot][jn], meshOuter[bot][j], nDown);
    addTri(cInner, meshInner[bot][j],  meshInner[bot][jn], nFloor);
  }

  vaseShape.endShape();
}

void addQuad(PVector a, PVector na, PVector b, PVector nb,
             PVector c, PVector nc, PVector d, PVector nd) {
  vtx(a, na); vtx(b, nb); vtx(c, nc);
  vtx(b, nb); vtx(d, nd); vtx(c, nc);
}

void addTri(PVector a, PVector b, PVector c, PVector n) {
  vtx(a, n); vtx(b, n); vtx(c, n);
}

void vtx(PVector v, PVector n) {
  vaseShape.normal(n.x, n.y, n.z);
  vaseShape.vertex(v.x, v.y, v.z);
}

// ── Tarjeta del viewport 3D ──────────────────────────────────
void drawViewCard() {
  int vx = viewX();
  int vw = width - vx - MARGIN;
  int vh = height - MARGIN * 2;
  noStroke();
  fill(UI_SHADOW);
  rect(vx, MARGIN + 3, vw, vh, CARD_R);
  stroke(UI_CARD_BORDER); strokeWeight(1);
  fill(UI_CARD);
  rect(vx, MARGIN, vw, vh, CARD_R);
  noStroke();
}

// ── Panel ────────────────────────────────────────────────────
void drawPanel() {
  int panelH = height - MARGIN * 2;

  // tarjeta con sombra sutil
  noStroke();
  fill(UI_SHADOW);
  rect(PANEL_X, PANEL_Y + 3, PANEL_W, panelH, CARD_R);
  stroke(UI_CARD_BORDER); strokeWeight(1);
  fill(UI_CARD);
  rect(PANEL_X, PANEL_Y, PANEL_W, panelH, CARD_R);
  noStroke();

  // titulo en dos tonos
  textFont(F_TITLE); textAlign(LEFT, TOP);
  fill(UI_TITLE);
  text("VASIJA ", PANEL_X + PANEL_PAD, PANEL_Y + PANEL_PAD - 4);
  float tw = textWidth("VASIJA ");
  fill(UI_TITLE_ACCENT);
  text("ORGANICA", PANEL_X + PANEL_PAD + tw, PANEL_Y + PANEL_PAD - 4);

  textFont(F_SUB); fill(UI_SUBTITLE);
  text("parametros generativos", PANEL_X + PANEL_PAD, PANEL_Y + PANEL_PAD + 24);

  drawThemeButton();

  // secciones + sliders
  String lastCat = "";
  for (int i = 0; i < sliders.length; i++) {
    if (!sliders[i].cat.equals(lastCat)) {
      boolean first = lastCat.equals("");
      lastCat = sliders[i].cat;
      int hy = sliders[i].y - 14;
      if (!first) {
        stroke(UI_RULE); strokeWeight(1);
        line(PANEL_X + PANEL_PAD, hy - 12,
             PANEL_X + PANEL_W - PANEL_PAD, hy - 12);
        noStroke();
      }
      textFont(F_HEADER); fill(UI_HEADER); textAlign(LEFT, CENTER);
      text(lastCat, PANEL_X + PANEL_PAD, hy);
    }
    sliders[i].draw();
  }

  drawPanelButtons();
}

// ── Botones pill ─────────────────────────────────────────────
final int BTN_ANIMAR      = 0;
final int BTN_GUARDAR     = 1;
final int BTN_DESHACER    = 2;
final int BTN_PRESET_SAVE = 3;
final int BTN_PRESET_LOAD = 4;
final int BTN_EXPORT      = 5;
int[][] btnRects = new int[6][4];

final int ST_PRI = 0;   // negro (accion principal)
final int ST_SEC = 1;   // gris claro
final int ST_ACC = 2;   // azul (estado activo)

void layoutButtons() {
  int full = PANEL_W - PANEL_PAD * 2;
  int half = (full - 10) / 2;
  int bottom = PANEL_Y + (height - MARGIN * 2) - PANEL_PAD;
  int y = bottom - 24 - (BTN_H * 4 + 10 * 3);

  setRect(BTN_ANIMAR,      PANEL_X + PANEL_PAD,             y, full, BTN_H); y += BTN_H + 10;
  setRect(BTN_GUARDAR,     PANEL_X + PANEL_PAD,             y, half, BTN_H);
  setRect(BTN_DESHACER,    PANEL_X + PANEL_PAD + half + 10, y, half, BTN_H); y += BTN_H + 10;
  setRect(BTN_PRESET_SAVE, PANEL_X + PANEL_PAD,             y, half, BTN_H);
  setRect(BTN_PRESET_LOAD, PANEL_X + PANEL_PAD + half + 10, y, half, BTN_H); y += BTN_H + 10;
  setRect(BTN_EXPORT,      PANEL_X + PANEL_PAD,             y, full, BTN_H);
}

void setRect(int id, int x, int y, int w, int h) {
  btnRects[id][0] = x; btnRects[id][1] = y;
  btnRects[id][2] = w; btnRects[id][3] = h;
}

void drawPanelButtons() {
  layoutButtons();
  boolean stlActive = stlFlash && (millis() - stlFlashTime < 300);

  drawButton("ANIMAR",        BTN_ANIMAR, ANIMATE ? ST_ACC : ST_SEC, false);
  drawButton("GUARDAR",       BTN_GUARDAR, ST_SEC, false);
  drawButton("DESHACER",      BTN_DESHACER, ST_SEC, snapIndex <= 0);
  drawButton("GUARDAR JSON",  BTN_PRESET_SAVE, ST_SEC, false);
  drawButton("CARGAR JSON",   BTN_PRESET_LOAD, ST_SEC, false);
  drawButton("EXPORTAR STL",  BTN_EXPORT, stlActive ? ST_ACC : ST_PRI, false);

  int infoY = btnRects[BTN_EXPORT][1] + BTN_H + 16;
  textFont(F_INFO); fill(UI_INFO);
  textAlign(LEFT, CENTER);
  text("historial: " + snapIndex + " / " + (snapshots.size() - 1),
       PANEL_X + PANEL_PAD, infoY);
  textAlign(RIGHT, CENTER);
  text(nf(frameRate, 2, 0) + " fps", PANEL_X + PANEL_W - PANEL_PAD, infoY);
}

void drawButton(String lbl, int id, int estilo, boolean disabled) {
  int x = btnRects[id][0], y = btnRects[id][1];
  int w = btnRects[id][2], h = btnRects[id][3];
  boolean hov = !disabled &&
                mouseX >= x && mouseX <= x + w &&
                mouseY >= y && mouseY <= y + h;

  color bg, tx;
  if (disabled)            { bg = UI_BTN_DIS; tx = UI_BTN_DIS_TXT; }
  else if (estilo == ST_PRI) {
    bg = hov ? lerpColor(UI_BTN_PRI, UI_BTN_ACC, 0.25) : UI_BTN_PRI;
    tx = UI_BTN_PRI_TXT;
  }
  else if (estilo == ST_ACC) {
    bg = hov ? lerpColor(UI_BTN_ACC, color(0), 0.12) : UI_BTN_ACC;
    tx = UI_BTN_ACC_TXT;
  }
  else                     { bg = hov ? UI_BTN_SEC_HOV : UI_BTN_SEC; tx = UI_BTN_SEC_TXT; }

  noStroke();
  fill(bg);
  rect(x, y, w, h, h / 2);   // pill
  fill(tx);
  textFont(F_BTN); textAlign(CENTER, CENTER);
  text(lbl, x + w/2, y + h/2 - 1);
}

boolean hitBtn(int id, int mx, int my) {
  return mx >= btnRects[id][0] && mx <= btnRects[id][0] + btnRects[id][2] &&
         my >= btnRects[id][1] && my <= btnRects[id][1] + btnRects[id][3];
}

boolean checkButtons(int mx, int my) {
  layoutButtons();
  if (hitBtn(BTN_ANIMAR, mx, my))      { ANIMATE = !ANIMATE; return true; }
  if (hitBtn(BTN_GUARDAR, mx, my))     { saveSnapshot();     return true; }
  if (hitBtn(BTN_DESHACER, mx, my))    { undoSnapshot();     return true; }
  if (hitBtn(BTN_PRESET_SAVE, mx, my)) { guardarPreset();    return true; }
  if (hitBtn(BTN_PRESET_LOAD, mx, my)) { cargarPreset();     return true; }
  if (hitBtn(BTN_EXPORT, mx, my))      { exportSTL();        return true; }
  return false;
}

// ── Interaccion ──────────────────────────────────────────────
int lastClickMs     = 0;
int lastClickSlider = -1;

void mousePressed() {
  if (overThemeButton(mouseX, mouseY)) { toggleTema(); return; }
  if (checkButtons(mouseX, mouseY)) return;

  activeSlider = -1;
  for (int i = 0; i < sliders.length; i++) {
    if (sliders[i].isOver(mouseX, mouseY)) {
      if (i == lastClickSlider && millis() - lastClickMs < 350) {
        sliders[i].reset();
        showFeedback(sliders[i].label + " -> " + sliders[i].displayValue() + " (default)");
      } else {
        sliders[i].updateFromMouse(mouseX);
      }
      lastClickSlider = i;
      lastClickMs = millis();
      activeSlider = i;
      applySliders(); buildMesh(); return;
    }
  }
  if (mouseX > viewX()) {
    dragging3D = true;
    prevMouseX = mouseX; prevMouseY = mouseY;
  }
}

void mouseReleased() { activeSlider = -1; dragging3D = false; }

void mouseDragged() {
  if (activeSlider >= 0) {
    sliders[activeSlider].updateFromMouse(mouseX);
    applySliders(); buildMesh(); return;
  }
  if (dragging3D && mouseX > viewX()) {
    camRotY += (mouseX - prevMouseX) * 0.01;
    camRotX  = constrain(camRotX + (mouseY - prevMouseY) * 0.01,
                         -HALF_PI + 0.05, HALF_PI - 0.05);
    prevMouseX = mouseX; prevMouseY = mouseY;
  }
}

void mouseWheel(MouseEvent e) {
  if (mouseX > viewX())
    camDist = constrain(camDist + e.getCount() * 25, 150, 2000);
}

void keyPressed() {
  if (key == 'r' || key == 'R') { camDist = 700; camRotY = 0.5; camRotX = 0.25; }
  if (key == 's' || key == 'S') saveSnapshot();
  if (key == 'z' || key == 'Z') undoSnapshot();
  if (key == 'e' || key == 'E') exportSTL();
  if (key == 'p' || key == 'P') guardarPreset();
  if (key == 'o' || key == 'O') cargarPreset();
  if (key == 't' || key == 'T') toggleTema();
}
