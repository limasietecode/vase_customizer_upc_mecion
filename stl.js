// ═════════════════════════════════════════════════════════════
//  STL — puerto de Exportar.pde: solido de pared doble + labio + bases.
//  Reconstruye la malla a resolucion de export (independiente de la
//  malla de vista) y escribe un STL binario descargable.
// ═════════════════════════════════════════════════════════════

function writeTriangle(view, pos, a, b, c) {
  const e1 = vsub(b, a);
  const e2 = vsub(c, a);
  const n = vnorm(vcross(e1, e2));
  view.setFloat32(pos, n.x, true); pos += 4;
  view.setFloat32(pos, n.y, true); pos += 4;
  view.setFloat32(pos, n.z, true); pos += 4;
  view.setFloat32(pos, a.x, true); pos += 4;
  view.setFloat32(pos, a.y, true); pos += 4;
  view.setFloat32(pos, a.z, true); pos += 4;
  view.setFloat32(pos, b.x, true); pos += 4;
  view.setFloat32(pos, b.y, true); pos += 4;
  view.setFloat32(pos, b.z, true); pos += 4;
  view.setFloat32(pos, c.x, true); pos += 4;
  view.setFloat32(pos, c.y, true); pos += 4;
  view.setFloat32(pos, c.z, true); pos += 4;
  view.setUint16(pos, 0, true); pos += 2;
  return pos;
}

// Devuelve { blob, filename, triCount }
function buildSolidSTL() {
  const { outer: meshOuter, inner: meshInner } = buildMeshAt(LEVELS_EXPORT, SLICES_EXPORT, 0);
  const L = meshOuter.length;
  const S = meshOuter[0].length;

  const nTri = (L - 1) * S * 4 + S * 4;
  const buf = new ArrayBuffer(80 + 4 + nTri * 50);
  const view = new DataView(buf);
  let pos = 0;

  const header = "Vasija organica generativa - export web con espesor";
  for (let i = 0; i < 80; i++) view.setUint8(pos++, i < header.length ? header.charCodeAt(i) : 0);
  view.setUint32(pos, nTri, true); pos += 4;

  // 1. Cara exterior
  for (let i = 0; i < L - 1; i++) {
    for (let j = 0; j < S; j++) {
      const jn = (j + 1) % S;
      const a = meshOuter[i][j], b = meshOuter[i + 1][j], c = meshOuter[i][jn], d = meshOuter[i + 1][jn];
      pos = writeTriangle(view, pos, a, b, c);
      pos = writeTriangle(view, pos, b, d, c);
    }
  }

  // 2. Cara interior (orden invertido para voltear normales)
  for (let i = 0; i < L - 1; i++) {
    for (let j = 0; j < S; j++) {
      const jn = (j + 1) % S;
      const a = meshInner[i][j], b = meshInner[i + 1][j], c = meshInner[i][jn], d = meshInner[i + 1][jn];
      pos = writeTriangle(view, pos, a, c, b);
      pos = writeTriangle(view, pos, b, c, d);
    }
  }

  // 3. Borde superior (labio)
  for (let j = 0; j < S; j++) {
    const jn = (j + 1) % S;
    const ao = meshOuter[0][j], bo = meshOuter[0][jn], ai = meshInner[0][j], bi = meshInner[0][jn];
    pos = writeTriangle(view, pos, ao, bo, ai);
    pos = writeTriangle(view, pos, bo, bi, ai);
  }

  // 4. Bases (exterior e interior)
  const bot = L - 1;
  const cOuter = { x: 0, y: meshOuter[bot][0].y, z: 0 };
  const cInner = { x: 0, y: meshInner[bot][0].y, z: 0 };
  for (let j = 0; j < S; j++) {
    const jn = (j + 1) % S;
    pos = writeTriangle(view, pos, cOuter, meshOuter[bot][jn], meshOuter[bot][j]);
    pos = writeTriangle(view, pos, cInner, meshInner[bot][j], meshInner[bot][jn]);
  }

  const blob = new Blob([buf], { type: "model/stl" });
  const filename = `vasija_solida_${timestamp()}.stl`;
  return { blob, filename, triCount: nTri };
}

function downloadBlob(blob, filename) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}
