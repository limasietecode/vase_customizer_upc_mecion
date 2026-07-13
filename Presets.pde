// ═════════════════════════════════════════════════════════════
//  Presets — guardar / cargar el estado completo como JSON.
//
//  Formato (clave-valor, robusto ante reordenar o agregar
//  sliders en versiones futuras):
//  {
//    "app": "vasija_organica",
//    "version": 1,
//    "fecha": "20260703_153000",
//    "parametros": { "base_radius": 140.0, "waist_radius": 70.0, ... }
//  }
//
//  Nota Android: selectInput/selectOutput son dialogos de
//  escritorio. Para la version tablet, reemplazar por guardado
//  directo en sketchPath("presets/") + una lista en pantalla.
//  Las funciones escribirPresetJSON / aplicarPresetJSON ya
//  estan separadas para reutilizarlas tal cual en Android.
// ═════════════════════════════════════════════════════════════

import java.io.File;

File pendingPresetLoad = null;   // se aplica en draw(), no en el hilo del dialogo

String marcaTiempo() {
  return year() + nf(month(), 2) + nf(day(), 2)
       + "_" + nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2);
}

// ── Guardar ──────────────────────────────────────────────────
void guardarPreset() {
  File dir = new File(sketchPath("presets"));
  if (!dir.exists()) dir.mkdirs();
  File sugerido = new File(dir, "vasija_" + marcaTiempo() + ".json");
  selectOutput("Guardar preset (JSON)...", "presetGuardarCallback", sugerido);
}

void presetGuardarCallback(File f) {
  if (f == null) { showFeedback("Guardado de preset cancelado"); return; }
  String path = f.getAbsolutePath();
  if (!path.toLowerCase().endsWith(".json")) path += ".json";
  try {
    escribirPresetJSON(path);
    showFeedback("Preset guardado: " + new File(path).getName());
  } catch (Exception e) {
    showFeedback("Error al guardar preset: " + e.getMessage());
  }
}

void escribirPresetJSON(String path) {
  JSONObject root = new JSONObject();
  root.setString("app", "vasija_organica");
  root.setInt("version", 1);
  root.setString("fecha", marcaTiempo());

  JSONObject p = new JSONObject();
  for (Slider s : sliders) p.setFloat(s.key, s.val);
  root.setJSONObject("parametros", p);

  saveJSONObject(root, path);
}

// ── Cargar ───────────────────────────────────────────────────
void cargarPreset() {
  File dir = new File(sketchPath("presets"));
  selectInput("Cargar preset (JSON)...", "presetCargarCallback",
              dir.exists() ? dir : null);
}

void presetCargarCallback(File f) {
  if (f == null) { showFeedback("Carga de preset cancelada"); return; }
  // El callback corre en otro hilo: no tocar el mesh aqui.
  pendingPresetLoad = f;
}

// Llamado al inicio de draw() para aplicar en el hilo de render
void procesarPresetPendiente() {
  if (pendingPresetLoad == null) return;
  File f = pendingPresetLoad;
  pendingPresetLoad = null;
  try {
    int aplicados = aplicarPresetJSON(f.getAbsolutePath());
    if (aplicados == 0) {
      showFeedback("El JSON no contiene parametros reconocidos");
    } else {
      applySliders();
      buildMesh();
      saveSnapshot();   // el preset entra al historial -> DESHACER funciona
      showFeedback("Preset cargado: " + f.getName() + " (" + aplicados + " parametros)");
    }
  } catch (Exception e) {
    showFeedback("Error al leer JSON: " + e.getMessage());
  }
}

// Devuelve cuantos parametros reconocidos se aplicaron.
// Claves desconocidas se ignoran; claves ausentes conservan
// su valor actual; todo valor se restringe al rango del slider.
int aplicarPresetJSON(String path) {
  JSONObject root = loadJSONObject(path);
  JSONObject p = root.hasKey("parametros")
               ? root.getJSONObject("parametros")
               : root;   // tolera un JSON "plano" hecho a mano

  int aplicados = 0;
  for (Slider s : sliders) {
    if (p.hasKey(s.key)) {
      s.setValue(p.getFloat(s.key));
      aplicados++;
    }
  }
  return aplicados;
}
