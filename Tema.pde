// ═════════════════════════════════════════════════════════════
//  Tema — sistema visual "clean / minimal":
//  tarjetas flotantes sobre lienzo gris palido, botones pill,
//  sliders de linea fina, acento azul para valores.
//
//  Modo CLARO por defecto (referencia de diseno).
//  Boton circular con icono dinamico (luna/sol). Tecla: T
//  El material de la vasija NO cambia con el tema.
// ═════════════════════════════════════════════════════════════

boolean DARK_MODE = false;

// Lienzo y tarjetas
color UI_BG, UI_CARD, UI_CARD_BORDER, UI_SHADOW;
// Tipografia
color UI_TITLE, UI_TITLE_ACCENT, UI_SUBTITLE, UI_HEADER, UI_RULE,
      UI_LABEL, UI_LABEL_HOV, UI_VALUE, UI_INFO;
// Sliders
color UI_TRACK, UI_FILL_SL, UI_THUMB, UI_THUMB_HOV;
// Botones
color UI_BTN_PRI, UI_BTN_PRI_TXT,
      UI_BTN_SEC, UI_BTN_SEC_HOV, UI_BTN_SEC_TXT,
      UI_BTN_ACC, UI_BTN_ACC_TXT,
      UI_BTN_DIS, UI_BTN_DIS_TXT;
// Feedback
color UI_FEEDBACK_BG, UI_FEEDBACK_TXT;
// Toggle
color UI_TOGGLE_BG, UI_TOGGLE_ICON;

// Fuentes
PFont F_TITLE, F_SUB, F_HEADER, F_LABEL, F_VALUE, F_BTN, F_INFO;

void initFonts() {
  F_TITLE  = createFont("SansSerif.bold",  21);
  F_SUB    = createFont("SansSerif.plain", 11);
  F_HEADER = createFont("SansSerif.bold",  10);
  F_LABEL  = createFont("SansSerif.plain", 12);
  F_VALUE  = createFont("SansSerif.bold",  12);
  F_BTN    = createFont("SansSerif.bold",  12);
  F_INFO   = createFont("SansSerif.plain", 10);
}

void aplicarTema() {
  if (!DARK_MODE) {
    // ── CLARO (por defecto) ──
    UI_BG           = color(238, 240, 243);
    UI_CARD         = color(255, 255, 255);
    UI_CARD_BORDER  = color(228, 231, 235);
    UI_SHADOW       = color(20, 25, 35, 14);

    UI_TITLE        = color(17, 17, 20);
    UI_TITLE_ACCENT = color(28, 95, 240);
    UI_SUBTITLE     = color(150, 156, 165);
    UI_HEADER       = color(120, 127, 137);
    UI_RULE         = color(233, 236, 240);
    UI_LABEL        = color(45, 48, 54);
    UI_LABEL_HOV    = color(10, 12, 15);
    UI_VALUE        = color(28, 95, 240);
    UI_INFO         = color(150, 156, 165);

    UI_TRACK        = color(224, 228, 233);
    UI_FILL_SL      = color(17, 17, 20);
    UI_THUMB        = color(17, 17, 20);
    UI_THUMB_HOV    = color(28, 95, 240);

    UI_BTN_PRI      = color(17, 17, 20);
    UI_BTN_PRI_TXT  = color(255, 255, 255);
    UI_BTN_SEC      = color(238, 240, 243);
    UI_BTN_SEC_HOV  = color(228, 231, 236);
    UI_BTN_SEC_TXT  = color(30, 33, 38);
    UI_BTN_ACC      = color(28, 95, 240);
    UI_BTN_ACC_TXT  = color(255, 255, 255);
    UI_BTN_DIS      = color(244, 246, 248);
    UI_BTN_DIS_TXT  = color(185, 190, 197);

    UI_FEEDBACK_BG  = color(255, 255, 255);
    UI_FEEDBACK_TXT = color(30, 33, 38);

    UI_TOGGLE_BG    = color(238, 240, 243);
    UI_TOGGLE_ICON  = color(60, 65, 72);
  } else {
    // ── OSCURO (mismo lenguaje, invertido) ──
    UI_BG           = color(17, 19, 23);
    UI_CARD         = color(28, 31, 37);
    UI_CARD_BORDER  = color(40, 44, 51);
    UI_SHADOW       = color(0, 0, 0, 60);

    UI_TITLE        = color(238, 240, 243);
    UI_TITLE_ACCENT = color(95, 150, 255);
    UI_SUBTITLE     = color(122, 128, 138);
    UI_HEADER       = color(122, 128, 138);
    UI_RULE         = color(42, 46, 53);
    UI_LABEL        = color(198, 203, 210);
    UI_LABEL_HOV    = color(245, 247, 250);
    UI_VALUE        = color(95, 150, 255);
    UI_INFO         = color(112, 118, 128);

    UI_TRACK        = color(48, 53, 61);
    UI_FILL_SL      = color(238, 240, 243);
    UI_THUMB        = color(238, 240, 243);
    UI_THUMB_HOV    = color(95, 150, 255);

    UI_BTN_PRI      = color(238, 240, 243);
    UI_BTN_PRI_TXT  = color(17, 19, 23);
    UI_BTN_SEC      = color(40, 44, 52);
    UI_BTN_SEC_HOV  = color(50, 55, 64);
    UI_BTN_SEC_TXT  = color(220, 224, 230);
    UI_BTN_ACC      = color(60, 115, 235);
    UI_BTN_ACC_TXT  = color(255, 255, 255);
    UI_BTN_DIS      = color(33, 36, 42);
    UI_BTN_DIS_TXT  = color(88, 94, 103);

    UI_FEEDBACK_BG  = color(28, 31, 37);
    UI_FEEDBACK_TXT = color(220, 224, 230);

    UI_TOGGLE_BG    = color(40, 44, 52);
    UI_TOGGLE_ICON  = color(215, 220, 226);
  }
}

void toggleTema() {
  DARK_MODE = !DARK_MODE;
  aplicarTema();
  showFeedback(DARK_MODE ? "Modo oscuro" : "Modo claro");
}

// ── Boton circular con icono dinamico ────────────────────────
final int THEME_BTN_R = 15;
int themeBtnX() { return PANEL_X + PANEL_W - PANEL_PAD - THEME_BTN_R; }
int themeBtnY() { return PANEL_Y + PANEL_PAD + 12; }

boolean overThemeButton(int mx, int my) {
  return dist(mx, my, themeBtnX(), themeBtnY()) <= THEME_BTN_R + 3;
}

void drawThemeButton() {
  int cx = themeBtnX();
  int cy = themeBtnY();
  boolean hov = overThemeButton(mouseX, mouseY);

  color bgc = hov
    ? lerpColor(UI_TOGGLE_BG, DARK_MODE ? color(255) : color(0), 0.08)
    : UI_TOGGLE_BG;

  noStroke();
  fill(bgc);
  ellipse(cx, cy, THEME_BTN_R * 2, THEME_BTN_R * 2);

  if (DARK_MODE) {
    // luna creciente
    fill(UI_TOGGLE_ICON);
    ellipse(cx, cy, 14, 14);
    fill(bgc);
    ellipse(cx + 4.5, cy - 3, 12, 12);
  } else {
    // sol
    fill(UI_TOGGLE_ICON);
    ellipse(cx, cy, 9, 9);
    stroke(UI_TOGGLE_ICON); strokeWeight(1.6);
    for (int k = 0; k < 8; k++) {
      float a = TWO_PI * k / 8.0;
      line(cx + cos(a) * 6.5, cy + sin(a) * 6.5,
           cx + cos(a) * 9.5, cy + sin(a) * 9.5);
    }
    noStroke();
  }
}
