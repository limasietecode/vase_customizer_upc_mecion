// ═════════════════════════════════════════════════════════════
//  UI — panel DOM (sliders, botones, tema, feedback). Puerto de
//  la parte de interfaz de G06_COD_VASE_V4_0.pde, Slider.pde y
//  Tema.pde, usando controles HTML reales en vez de dibujo custom.
// ═════════════════════════════════════════════════════════════

const FEEDBACK_MS = 2000;
let meshDirty = true;
let animating = false;

function markMeshDirty() { meshDirty = true; }

// ── Construccion de sliders agrupados por categoria ─────────────
const sliderInputs = {};
const sliderValueEls = {};

function buildSliderDOM() {
  const host = document.getElementById("sliderHost");
  host.innerHTML = "";
  let lastCat = "";

  for (const d of SLIDER_DEFS) {
    if (d.cat !== lastCat) {
      if (lastCat !== "") host.appendChild(document.createElement("hr")).className = "rule";
      const h = document.createElement("div");
      h.className = "cat-header";
      h.textContent = d.cat;
      host.appendChild(h);
      lastCat = d.cat;
    }

    const row = document.createElement("div");
    row.className = "slider-row";

    const label = document.createElement("label");
    label.className = "slider-label";
    label.textContent = d.label;
    label.setAttribute("for", `sl_${d.key}`);

    const input = document.createElement("input");
    input.type = "range";
    input.id = `sl_${d.key}`;
    input.min = d.min;
    input.max = d.max;
    input.step = d.isInt ? 1 : (d.max - d.min) / 500;
    input.value = state[d.key];

    const valueEl = document.createElement("span");
    valueEl.className = "slider-value";
    valueEl.textContent = formatValue(d, state[d.key]);

    input.addEventListener("input", () => {
      state[d.key] = clampToSlider(d, parseFloat(input.value));
      valueEl.textContent = formatValue(d, state[d.key]);
      markMeshDirty();
    });
    input.addEventListener("dblclick", () => {
      state[d.key] = d.def;
      input.value = d.def;
      valueEl.textContent = formatValue(d, state[d.key]);
      markMeshDirty();
      showFeedback(`${d.label} -> ${formatValue(d, d.def)} (default)`);
    });

    row.appendChild(label);
    row.appendChild(input);
    row.appendChild(valueEl);
    host.appendChild(row);

    sliderInputs[d.key] = input;
    sliderValueEls[d.key] = valueEl;
  }
}

function formatValue(def, v) {
  return def.isInt ? String(Math.round(v)) : v.toFixed(2);
}

function refreshSliderDOM() {
  for (const d of SLIDER_DEFS) {
    sliderInputs[d.key].value = state[d.key];
    sliderValueEls[d.key].textContent = formatValue(d, state[d.key]);
  }
}

// Llamado tras cualquier cambio de estado que no venga de arrastrar
// un slider a mano (undo, carga de preset): refresca DOM + malla.
function onStateChanged() {
  refreshSliderDOM();
  markMeshDirty();
  updateHistorialText();
}

// ── Feedback flotante ────────────────────────────────────────
let feedbackTimer = null;
function showFeedback(msg) {
  const el = document.getElementById("feedback");
  el.textContent = msg;
  el.classList.add("show");
  if (feedbackTimer) clearTimeout(feedbackTimer);
  feedbackTimer = setTimeout(() => el.classList.remove("show"), FEEDBACK_MS);
}

// ── Info row (historial / fps) ──────────────────────────────────
function updateHistorialText() {
  document.getElementById("infoHistorial").textContent = `historial: ${snapIndex} / ${snapshots.length - 1}`;
  document.getElementById("btnDeshacer").disabled = snapIndex <= 0;
}
function updateFpsText(fps) {
  document.getElementById("infoFps").textContent = `${fps.toFixed(0)} fps`;
}

// ── Tema claro/oscuro ────────────────────────────────────────
let darkMode = false;
function aplicarTema() {
  document.body.classList.toggle("dark", darkMode);
  document.getElementById("themeBtn").textContent = darkMode ? "\u{1F319}" : "☀️";
}
function toggleTema() {
  darkMode = !darkMode;
  aplicarTema();
  showFeedback(darkMode ? "Modo oscuro" : "Modo claro");
}

// ── Botones del panel ────────────────────────────────────────
function initButtons() {
  const btnAnimar = document.getElementById("btnAnimar");
  btnAnimar.addEventListener("click", () => {
    animating = !animating;
    btnAnimar.classList.toggle("btn-acc", animating);
    btnAnimar.classList.toggle("btn-sec", !animating);
  });

  document.getElementById("btnGuardar").addEventListener("click", saveSnapshot);
  document.getElementById("btnDeshacer").addEventListener("click", undoSnapshot);
  document.getElementById("btnPresetSave").addEventListener("click", guardarPreset);

  const fileInput = document.getElementById("presetFileInput");
  document.getElementById("btnPresetLoad").addEventListener("click", () => fileInput.click());
  fileInput.addEventListener("change", () => {
    if (fileInput.files && fileInput.files[0]) cargarPresetDesdeArchivo(fileInput.files[0]);
    fileInput.value = "";
  });

  const btnExport = document.getElementById("btnExport");
  btnExport.addEventListener("click", () => {
    showFeedback("Exportando STL...");
    btnExport.disabled = true;
    setTimeout(() => {
      const { blob, filename, triCount } = buildSolidSTL();
      downloadBlob(blob, filename);
      btnExport.disabled = false;
      btnExport.classList.add("flash");
      setTimeout(() => btnExport.classList.remove("flash"), 300);
      showFeedback(`STL solido guardado (${triCount} tris):  ${filename}`);
    }, 20);
  });

  document.getElementById("themeBtn").addEventListener("click", toggleTema);
}

// ── Atajos de teclado (iguales a keyPressed() del sketch original) ──
function initKeyboardShortcuts(resetCamera) {
  window.addEventListener("keydown", (e) => {
    const k = e.key.toLowerCase();
    if (k === "r") resetCamera();
    else if (k === "s") saveSnapshot();
    else if (k === "z") undoSnapshot();
    else if (k === "e") document.getElementById("btnExport").click();
    else if (k === "p") guardarPreset();
    else if (k === "o") document.getElementById("presetFileInput").click();
    else if (k === "t") toggleTema();
  });
}

function initUI(resetCamera) {
  buildSliderDOM();
  initButtons();
  aplicarTema();
  updateHistorialText();
  initKeyboardShortcuts(resetCamera);
}
