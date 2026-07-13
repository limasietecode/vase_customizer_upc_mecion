// ═════════════════════════════════════════════════════════════
//  Presets + Snapshots — puerto de Presets.pde y Snapshot.pde.
//  Guardar/cargar JSON usa descarga/subida de archivo en vez de
//  dialogos de escritorio; el resto de la logica es igual.
// ═════════════════════════════════════════════════════════════

function timestamp() {
  const d = new Date();
  const p = (n, w = 2) => String(n).padStart(w, "0");
  return `${d.getFullYear()}${p(d.getMonth() + 1)}${p(d.getDate())}_${p(d.getHours())}${p(d.getMinutes())}${p(d.getSeconds())}`;
}

// ── Snapshots (historial en memoria / DESHACER) ────────────────
const snapshots = [];
let snapIndex = -1;

function packState() {
  const s = {};
  for (const d of SLIDER_DEFS) s[d.key] = state[d.key];
  return s;
}

function unpackState(s) {
  for (const d of SLIDER_DEFS) state[d.key] = s[d.key];
}

function saveSnapshot() {
  while (snapshots.length > snapIndex + 1) snapshots.pop();
  snapshots.push(packState());
  snapIndex = snapshots.length - 1;
  if (snapshots.length > MAX_SNAPSHOTS) {
    snapshots.shift();
    snapIndex = snapshots.length - 1;
  }
  showFeedback(`Estado guardado  (${snapIndex})`);
  onStateChanged();
}

function undoSnapshot() {
  if (snapIndex <= 0) {
    showFeedback("No hay estados anteriores");
    return;
  }
  snapIndex--;
  unpackState(snapshots[snapIndex]);
  showFeedback(`Deshecho  ->  estado ${snapIndex}`);
  onStateChanged();
}

// ── Presets JSON (guardar / cargar) ─────────────────────────────
function presetToObject() {
  const parametros = {};
  for (const d of SLIDER_DEFS) parametros[d.key] = state[d.key];
  return { app: "vasija_organica", version: 1, fecha: timestamp(), parametros };
}

function guardarPreset() {
  const obj = presetToObject();
  const blob = new Blob([JSON.stringify(obj, null, 2)], { type: "application/json" });
  const filename = `vasija_${timestamp()}.json`;
  downloadBlob(blob, filename);
  showFeedback(`Preset guardado: ${filename}`);
}

// Aplica un objeto de preset ya parseado. Claves desconocidas se
// ignoran; claves ausentes conservan su valor actual; todo valor
// se restringe al rango del slider. Devuelve cuantas se aplicaron.
function aplicarPresetObjeto(root) {
  const p = root && typeof root === "object" && root.parametros ? root.parametros : root;
  let aplicados = 0;
  if (!p) return aplicados;
  for (const d of SLIDER_DEFS) {
    if (Object.prototype.hasOwnProperty.call(p, d.key)) {
      state[d.key] = clampToSlider(d, Number(p[d.key]));
      aplicados++;
    }
  }
  return aplicados;
}

function cargarPresetDesdeArchivo(file) {
  const reader = new FileReader();
  reader.onload = () => {
    try {
      const root = JSON.parse(reader.result);
      const aplicados = aplicarPresetObjeto(root);
      if (aplicados === 0) {
        showFeedback("El JSON no contiene parametros reconocidos");
      } else {
        onStateChanged();
        saveSnapshot();
        showFeedback(`Preset cargado: ${file.name} (${aplicados} parametros)`);
      }
    } catch (e) {
      showFeedback("Error al leer JSON: " + e.message);
    }
  };
  reader.onerror = () => showFeedback("Error al leer el archivo");
  reader.readAsText(file);
}
