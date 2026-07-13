// ═════════════════════════════════════════════════════════════
//  Sketch principal — puerto de G06_COD_VASE_V4_0.pde (draw loop,
//  camara orbital, luces). El panel 2D ahora es DOM (ui.js); este
//  archivo solo controla el viewport 3D en WEBGL.
// ═════════════════════════════════════════════════════════════

let camDist = 700;
let camRotY = 0.5;
let camRotX = 0.25;
let animPhase = 0;

let prevMouseX = 0, prevMouseY = 0;
let dragging3D = false;

// Datos de la malla actual (posiciones + normales aplanadas, igual
// formato que buildIndexedGeometry). Se recalculan solo cuando hace
// falta; el dibujo en si usa modo inmediato (ver drawVase), asi no
// depende de la cache de buffers retenidos de p5 (model()/gid), que
// en la practica no siempre refresca los datos como cabria esperar.
let currentMesh = null;

function resetCamera() {
  camDist = 700; camRotY = 0.5; camRotX = 0.25;
}

function rebuildGeometryIfNeeded() {
  if (!meshDirty && !animating) return;
  meshDirty = false;

  if (animating) {
    animPhase += state.anim_speed;
  }

  const { outer, inner } = buildMeshAt(LEVELS_VIEW, SLICES_VIEW, animPhase);
  currentMesh = buildIndexedGeometry(outer, inner);
}

function drawVase() {
  if (!currentMesh) return;
  const { positions, normals, indices } = currentMesh;

  beginShape(TRIANGLES);
  noStroke();
  fill(COL_FILL[0], COL_FILL[1], COL_FILL[2]);
  for (let k = 0; k < indices.length; k++) {
    const i = indices[k] * 3;
    normal(normals[i], normals[i + 1], normals[i + 2]);
    vertex(positions[i], positions[i + 1], positions[i + 2]);
  }
  endShape();
}

function setup() {
  const host = document.getElementById("canvasHost");
  const w = host.clientWidth || 100;
  const h = host.clientHeight || 100;
  const cnv = createCanvas(w, h, WEBGL);
  cnv.parent(host);
  smooth();

  rebuildGeometryIfNeeded();
  initUI(resetCamera);
  saveSnapshot();

  // Reacciona a cambios de tamano del host despues del arranque (ej.
  // redimensionar la ventana), mas una correccion inmediata post-layout
  // de respaldo: el disparo inicial de ResizeObserver no es fiable en
  // todos los navegadores.
  new ResizeObserver(windowResized).observe(host);
  requestAnimationFrame(() => requestAnimationFrame(windowResized));

  // Respaldo independiente del loop interno de p5: si algo detiene el
  // requestAnimationFrame nativo (por ejemplo una excepcion no atrapada
  // en algun punto de draw() que impida programar el siguiente frame),
  // este intervalo sigue forzando un redraw() con el estado actual, asi
  // los sliders nunca quedan "congelados" sin reflejarse en el modelo.
  setInterval(() => redraw(), 100);
}

function windowResized() {
  const host = document.getElementById("canvasHost");
  if (!host.clientWidth || !host.clientHeight) return;
  if (host.clientWidth === width && host.clientHeight === height) return;
  resizeCanvas(host.clientWidth, host.clientHeight);
}

function draw() {
  // Toda la funcion queda protegida: p5 programa el SIGUIENTE frame de
  // requestAnimationFrame recien al terminar de ejecutar este draw(), asi
  // que cualquier excepcion no atrapada en cualquier punto de aqui abajo
  // (reconstruccion de malla, camara, luces, dibujo) deja el loop muerto
  // para siempre y el modelo congelado, sin ningun error visible para
  // quien esta usando la pagina. Se atrapa todo y se sigue dibujando el
  // ultimo estado valido en vez de romper el loop.
  try {
    background(darkMode ? 17 : 238, darkMode ? 19 : 240, darkMode ? 23 : 243);

    rebuildGeometryIfNeeded();

    const ex = camDist * Math.sin(camRotY) * Math.cos(camRotX);
    const ey = camDist * Math.sin(camRotX);
    const ez = camDist * Math.cos(camRotY) * Math.cos(camRotX);

    camera(ex, -ey, ez, 0, 0, 0, 0, 1, 0);
    const aspect = height > 0 ? width / height : 1;
    perspective(Math.PI / 3.0, aspect, 10, 5000);

    ambientLight(45, 50, 55);
    directionalLight(210, 230, 220, 0.5, 0.7, -0.6);
    directionalLight(60, 85, 100, -0.7, -0.3, 0.4);
    directionalLight(120, 140, 130, 0.0, -0.8, 0.2);
    specularMaterial(COL_SPEC[0], COL_SPEC[1], COL_SPEC[2]);
    shininess(state.shininess);

    drawVase();

    if (frameCount % 10 === 0) updateFpsText(frameRate());
  } catch (e) {
    console.error("Error en draw(), se mantiene el ultimo frame valido:", e);
    meshDirty = false;
  }
}

function mousePressed() {
  if (mouseX < 0 || mouseX > width || mouseY < 0 || mouseY > height) return;
  dragging3D = true;
  prevMouseX = mouseX; prevMouseY = mouseY;
}

function mouseReleased() { dragging3D = false; }

function mouseDragged() {
  if (!dragging3D) return;
  camRotY += (mouseX - prevMouseX) * 0.01;
  camRotX = Math.min(Math.PI / 2 - 0.05, Math.max(-Math.PI / 2 + 0.05, camRotX + (mouseY - prevMouseY) * 0.01));
  prevMouseX = mouseX; prevMouseY = mouseY;
}

function mouseWheel(e) {
  camDist = Math.min(2000, Math.max(150, camDist + e.delta * 0.6));
  return false;
}
