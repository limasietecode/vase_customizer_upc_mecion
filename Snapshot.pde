// ═════════════════════════════════════════════════════════════
//  Snapshots — historial de estados en memoria (DESHACER)
//  (Los presets JSON en disco viven en Presets.pde)
// ═════════════════════════════════════════════════════════════

int MAX_SNAPSHOTS            = 20;
ArrayList<float[]> snapshots = new ArrayList<float[]>();
int  snapIndex               = -1;
String  feedbackMsg          = "";
int     feedbackTime         = 0;
int     FEEDBACK_MS          = 2000;
boolean stlFlash             = false;
int     stlFlashTime         = 0;

float[] packState() {
  float[] s = new float[sliders.length];
  for (int i = 0; i < sliders.length; i++) s[i] = sliders[i].val;
  return s;
}

void unpackState(float[] s) {
  for (int i = 0; i < sliders.length; i++) sliders[i].val = s[i];
  applySliders();
  buildMesh();
}

void saveSnapshot() {
  while (snapshots.size() > snapIndex + 1)
    snapshots.remove(snapshots.size() - 1);
  snapshots.add(packState());
  snapIndex = snapshots.size() - 1;
  if (snapshots.size() > MAX_SNAPSHOTS) {
    snapshots.remove(0);
    snapIndex = snapshots.size() - 1;
  }
  showFeedback("Estado guardado  (" + snapIndex + ")");
}

void undoSnapshot() {
  if (snapIndex <= 0) {
    showFeedback("No hay estados anteriores");
    return;
  }
  snapIndex--;
  unpackState(snapshots.get(snapIndex));
  showFeedback("Deshecho  ->  estado " + snapIndex);
}

void showFeedback(String msg) {
  feedbackMsg  = msg;
  feedbackTime = millis();
}

void drawFeedback() {
  if (feedbackMsg.equals("")) return;
  int elapsed = millis() - feedbackTime;
  if (elapsed > FEEDBACK_MS) { feedbackMsg = ""; return; }
  float alpha = constrain(map(elapsed, FEEDBACK_MS - 400, FEEDBACK_MS, 235, 0), 0, 235);
  int tx0 = viewX() + 24;
  int ty0 = height - MARGIN - 24 - 40;
  noStroke();
  fill(red(UI_FEEDBACK_BG), green(UI_FEEDBACK_BG), blue(UI_FEEDBACK_BG), (int)alpha);
  rect(tx0, ty0, 460, 40, 20);
  stroke(red(UI_CARD_BORDER), green(UI_CARD_BORDER), blue(UI_CARD_BORDER), (int)alpha);
  strokeWeight(1); noFill();
  rect(tx0, ty0, 460, 40, 20);
  noStroke();
  fill(red(UI_FEEDBACK_TXT), green(UI_FEEDBACK_TXT), blue(UI_FEEDBACK_TXT), (int)alpha);
  textFont(F_LABEL); textAlign(LEFT, CENTER);
  text(feedbackMsg, tx0 + 20, ty0 + 19);
}
