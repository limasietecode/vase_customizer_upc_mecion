// ═════════════════════════════════════════════════════════════
//  Exportar — STL binario solido (pared doble + labio + bases).
//
//  Cambio v7: la vista interactiva usa resolucion reducida;
//  aqui se reconstruye el mesh a RESOLUCION COMPLETA
//  (LEVELS_EXPORT x SLICES_EXPORT), se escribe el STL y se
//  restaura el mesh de vista.
//
//  Nota: SLICES_EXPORT = 480 para muestrear correctamente hasta
//  RIDGE_COUNT = 180 (min. ~2.6 muestras por periodo). Con 240
//  slices, ridges altos hacian aliasing en el STL.
// ═════════════════════════════════════════════════════════════

void exportSTL() {
  String fname = "vasija_solida_" + marcaTiempo() + ".stl";

  // Reconstruir a resolucion de export
  buildMeshAt(LEVELS_EXPORT, SLICES_EXPORT);

  int L = meshOuter.length;
  int S = meshOuter[0].length;

  // exterior + interior: (L-1)*S*2 tris c/u -> *4
  // labio: S*2  |  bases: S*2  -> S*4
  int nTri = (L - 1) * S * 4 + S * 4;

  byte[] buf = new byte[80 + 4 + nTri * 50];
  int pos = 0;

  String header = "Vasija organica generativa Processing con espesor";
  for (int i = 0; i < 80; i++)
    buf[pos++] = (i < header.length()) ? (byte)header.charAt(i) : 0;

  buf[pos++] = (byte)(nTri & 0xFF);
  buf[pos++] = (byte)((nTri >>  8) & 0xFF);
  buf[pos++] = (byte)((nTri >> 16) & 0xFF);
  buf[pos++] = (byte)((nTri >> 24) & 0xFF);

  // 1. CARA EXTERIOR
  for (int i = 0; i < L - 1; i++) {
    for (int j = 0; j < S; j++) {
      int jn = (j + 1) % S;
      PVector a = meshOuter[i][j];
      PVector b = meshOuter[i+1][j];
      PVector c = meshOuter[i][jn];
      PVector d = meshOuter[i+1][jn];
      pos = writeTriangle(buf, pos, a, b, c);
      pos = writeTriangle(buf, pos, b, d, c);
    }
  }

  // 2. CARA INTERIOR (orden invertido para voltear normales)
  for (int i = 0; i < L - 1; i++) {
    for (int j = 0; j < S; j++) {
      int jn = (j + 1) % S;
      PVector a = meshInner[i][j];
      PVector b = meshInner[i+1][j];
      PVector c = meshInner[i][jn];
      PVector d = meshInner[i+1][jn];
      pos = writeTriangle(buf, pos, a, c, b);
      pos = writeTriangle(buf, pos, b, c, d);
    }
  }

  // 3. BORDE SUPERIOR (labio)
  for (int j = 0; j < S; j++) {
    int jn = (j + 1) % S;
    PVector ao = meshOuter[0][j];
    PVector bo = meshOuter[0][jn];
    PVector ai = meshInner[0][j];
    PVector bi = meshInner[0][jn];
    pos = writeTriangle(buf, pos, ao, bo, ai);
    pos = writeTriangle(buf, pos, bo, bi, ai);
  }

  // 4. BASES (exterior e interior)
  int bot = L - 1;
  PVector cOuter = new PVector(0, meshOuter[bot][0].y, 0);
  PVector cInner = new PVector(0, meshInner[bot][0].y, 0);

  for (int j = 0; j < S; j++) {
    int jn = (j + 1) % S;
    pos = writeTriangle(buf, pos, cOuter, meshOuter[bot][jn], meshOuter[bot][j]);
    pos = writeTriangle(buf, pos, cInner, meshInner[bot][j],  meshInner[bot][jn]);
  }

  saveBytes(fname, buf);

  // Restaurar el mesh de vista interactiva
  buildMesh();

  stlFlash = true;
  stlFlashTime = millis();
  showFeedback("STL solido guardado (" + nTri + " tris):  " + fname);
}

int writeTriangle(byte[] buf, int pos, PVector a, PVector b, PVector c) {
  PVector e1 = PVector.sub(b, a);
  PVector e2 = PVector.sub(c, a);
  PVector n  = e1.cross(e2);
  n.normalize();
  pos = writeFloat(buf, pos, n.x);
  pos = writeFloat(buf, pos, n.y);
  pos = writeFloat(buf, pos, n.z);
  pos = writeFloat(buf, pos, a.x);
  pos = writeFloat(buf, pos, a.y);
  pos = writeFloat(buf, pos, a.z);
  pos = writeFloat(buf, pos, b.x);
  pos = writeFloat(buf, pos, b.y);
  pos = writeFloat(buf, pos, b.z);
  pos = writeFloat(buf, pos, c.x);
  pos = writeFloat(buf, pos, c.y);
  pos = writeFloat(buf, pos, c.z);
  buf[pos++] = 0;
  buf[pos++] = 0;
  return pos;
}

int writeFloat(byte[] buf, int pos, float v) {
  int bits = Float.floatToIntBits(v);
  buf[pos++] = (byte)(bits & 0xFF);
  buf[pos++] = (byte)((bits >>  8) & 0xFF);
  buf[pos++] = (byte)((bits >> 16) & 0xFF);
  buf[pos++] = (byte)((bits >> 24) & 0xFF);
  return pos;
}
