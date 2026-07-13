// ═════════════════════════════════════════════════════════════
//  Mesh — puerto de las funciones de perfil axial + buildMesh
//  del sketch original (G06_COD_VASE_V4_0.pde).
// ═════════════════════════════════════════════════════════════

// PRNG determinista (mulberry32) — equivalente funcional a
// randomSeed()/random() de Processing: mismo seed -> mismos golpes.
function mulberry32(seed) {
  let a = seed >>> 0;
  return function () {
    a |= 0; a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function smoothstep(t) {
  return t * t * (3.0 - 2.0 * t);
}

function derivedParams() {
  return {
    BASE_RADIUS: state.base_radius,
    WAIST_RADIUS: state.waist_radius,
    TOP_RADIUS: state.top_radius,
    TOTAL_HEIGHT: state.total_height,
    WAIST_POS: state.waist_position,
    BASE_BULGE: state.base_bulge,
    WALL_THICKNESS: state.wall_thickness,
    RIDGE_COUNT: state.ridge_count,
    RIDGE_DEPTH: state.ridge_depth,
    TWIST_TOTAL: state.twist * Math.PI,
    LOBE_COUNT: state.lobe_count,
    LOBE_AMP: state.lobe_amplitude,
    LOBE_START: state.lobe_start,
    DENT_COUNT: state.dent_count,
    DENT_AMP: state.dent_amplitude,
    DENT_WIDTH: state.dent_width,
    DENT_CENTER: state.dent_center,
    DENT_SPREAD: state.dent_spread,
    DENT_SEED: state.dent_seed,
  };
}

function profileRadius(zNorm, p) {
  const zFlip = 1.0 - zNorm;
  const pz = [0.0, p.BASE_BULGE, p.WAIST_POS, 1.0];
  const pr = [p.BASE_RADIUS, p.BASE_RADIUS, p.WAIST_RADIUS, p.TOP_RADIUS];

  let seg = pz.length - 2;
  for (let i = 0; i < pz.length - 1; i++) {
    if (zFlip <= pz[i + 1]) { seg = i; break; }
  }
  const segWidth = pz[seg + 1] - pz[seg];
  // BASE_BULGE y WAIST_POS son sliders independientes: pueden coincidir
  // (segmento de ancho 0), lo que daria una division por cero -> NaN.
  const t = segWidth > 1e-6 ? Math.min(1, Math.max(0, (zFlip - pz[seg]) / segWidth)) : 1;
  const ts = smoothstep(t);
  return pr[seg] + (pr[seg + 1] - pr[seg]) * ts;
}

function lobeEnvelope(zNorm, p) {
  const zFlip = 1.0 - zNorm;
  if (zFlip < p.LOBE_START) return 0.0;
  const t = (zFlip - p.LOBE_START) / (1.0 - p.LOBE_START);
  return smoothstep(t);
}

function dentEnvelope(zNorm, p) {
  const zFlip = 1.0 - zNorm;
  const dist = Math.abs(zFlip - p.DENT_CENTER);
  if (dist > p.DENT_SPREAD * 2.5) return 0.0;
  const t = dist / p.DENT_SPREAD;
  return Math.exp(-t * t * 2.5);
}

// Construye las dos rejillas (exterior/interior) de [levels][slices] { x, y, z }
function buildMeshAt(levels, slices, animPhaseTurns) {
  const p = derivedParams();
  const meshOuter = new Array(levels);
  const meshInner = new Array(levels);

  const phase = animPhaseTurns * Math.PI * 2;
  const dentCount = Math.round(p.DENT_COUNT);
  const rnd = mulberry32(Math.round(p.DENT_SEED) * 2654435761);
  const dentAngles = new Array(dentCount);
  const dentMags = new Array(dentCount);
  for (let d = 0; d < dentCount; d++) {
    dentAngles[d] = rnd() * Math.PI * 2;
    dentMags[d] = 0.6 + rnd() * 0.4;
  }

  const ridgeCount = p.RIDGE_COUNT;
  const lobeCount = p.LOBE_COUNT;

  for (let i = 0; i < levels; i++) {
    meshOuter[i] = new Array(slices);
    meshInner[i] = new Array(slices);

    const zNorm = i / (levels - 1);
    const zOuter = (zNorm - 0.5) * p.TOTAL_HEIGHT;
    const zInner = -p.TOTAL_HEIGHT / 2.0 + zNorm * (p.TOTAL_HEIGHT - p.WALL_THICKNESS);

    const r = profileRadius(zNorm, p);
    const twist = p.TWIST_TOTAL * zNorm;
    const lobEnv = lobeEnvelope(zNorm, p);
    const dentEnv = dentEnvelope(zNorm, p);

    for (let j = 0; j < slices; j++) {
      const theta = ((Math.PI * 2) / slices) * j + twist;

      const ridge = p.RIDGE_DEPTH * Math.cos(ridgeCount * theta + phase * 2.0);
      const lobe = p.LOBE_AMP * lobEnv * Math.cos(lobeCount * (theta - twist * 0.5) + phase);
      let dent = 0;
      for (let d = 0; d < dentCount; d++) {
        const angDist = theta - (dentAngles[d] + phase * 0.35);
        const angEnv = Math.exp(-(angDist * angDist) / (2.0 * p.DENT_WIDTH * p.DENT_WIDTH));
        dent -= p.DENT_AMP * dentMags[d] * angEnv * dentEnv;
      }

      const rFinalOuter = Math.max(r + ridge + lobe + dent, 4.0);
      const rFinalInner = Math.max(rFinalOuter - p.WALL_THICKNESS, 1.0);

      const cosT = Math.cos(theta), sinT = Math.sin(theta);
      meshOuter[i][j] = { x: rFinalOuter * cosT, y: zOuter, z: rFinalOuter * sinT };
      meshInner[i][j] = { x: rFinalInner * cosT, y: zInner, z: rFinalInner * sinT };
    }
  }

  return { outer: meshOuter, inner: meshInner, levels, slices };
}

function vsub(a, b) { return { x: a.x - b.x, y: a.y - b.y, z: a.z - b.z }; }
function vcross(a, b) {
  return {
    x: a.y * b.z - a.z * b.y,
    y: a.z * b.x - a.x * b.z,
    z: a.x * b.y - a.y * b.x,
  };
}
function vnorm(a) {
  const len = Math.sqrt(a.x * a.x + a.y * a.y + a.z * a.z) || 1;
  return { x: a.x / len, y: a.y / len, z: a.z / len };
}

// Calcula las normales por vertice de rejilla (igual criterio que
// rebuildShapeIfNeeded en el sketch original: diferencias hacia adelante).
function buildGridNormals(meshOuter, meshInner) {
  const L = meshOuter.length;
  const S = meshOuter[0].length;
  const nOut = new Array(L);
  const nInn = new Array(L);

  for (let i = 0; i < L; i++) {
    nOut[i] = new Array(S);
    nInn[i] = new Array(S);
    const ii = Math.min(i, L - 2);
    for (let j = 0; j < S; j++) {
      const jn = (j + 1) % S;

      const v0 = meshOuter[ii][j];
      let n = vcross(vsub(meshOuter[ii][jn], v0), vsub(meshOuter[ii + 1][j], v0));
      nOut[i][j] = vnorm(n);

      const w0 = meshInner[ii][j];
      let m = vcross(vsub(meshInner[ii][jn], w0), vsub(meshInner[ii + 1][j], w0));
      m = vnorm(m);
      nInn[i][j] = { x: -m.x, y: -m.y, z: -m.z };
    }
  }
  return { nOut, nInn };
}

// Construye una malla indexada (posiciones + normales + indices)
// lista para cargar en un p5.Geometry con model().
function buildIndexedGeometry(meshOuter, meshInner) {
  const L = meshOuter.length;
  const S = meshOuter[0].length;
  const { nOut, nInn } = buildGridNormals(meshOuter, meshInner);

  const positions = [];
  const normals = [];
  const indices = [];

  const idxOuter = (i, j) => i * S + j;
  const idxInner = (i, j) => L * S + i * S + j;

  for (let i = 0; i < L; i++) {
    for (let j = 0; j < S; j++) {
      const o = meshOuter[i][j], no = nOut[i][j];
      positions.push(o.x, o.y, o.z);
      normals.push(no.x, no.y, no.z);
    }
  }
  for (let i = 0; i < L; i++) {
    for (let j = 0; j < S; j++) {
      const w = meshInner[i][j], ni = nInn[i][j];
      positions.push(w.x, w.y, w.z);
      normals.push(ni.x, ni.y, ni.z);
    }
  }

  for (let i = 0; i < L - 1; i++) {
    for (let j = 0; j < S; j++) {
      const jn = (j + 1) % S;
      const a = idxOuter(i, j), b = idxOuter(i + 1, j), c = idxOuter(i, jn), d = idxOuter(i + 1, jn);
      indices.push(a, b, c, b, d, c);

      const ai = idxInner(i, j), bi = idxInner(i + 1, j), ci = idxInner(i, jn), di = idxInner(i + 1, jn);
      indices.push(ai, bi, ci, bi, di, ci);
    }
  }

  // Labio superior (borde): normal constante (0,-1,0), como en addQuad(..., nUp)
  // del sketch original -> necesita vertices propios (no puede compartir los
  // de la pared, que llevan normales por-vertice distintas).
  const pushVert = (pos, nrm) => {
    const idx = positions.length / 3;
    positions.push(pos.x, pos.y, pos.z);
    normals.push(nrm.x, nrm.y, nrm.z);
    return idx;
  };

  const nUp = { x: 0, y: -1, z: 0 };
  const lipOuter = [], lipInner = [];
  for (let j = 0; j < S; j++) {
    lipOuter.push(pushVert(meshOuter[0][j], nUp));
    lipInner.push(pushVert(meshInner[0][j], nUp));
  }
  for (let j = 0; j < S; j++) {
    const jn = (j + 1) % S;
    // addQuad(outer[0][j], inner[0][j], outer[0][jn], inner[0][jn])
    indices.push(lipOuter[j], lipInner[j], lipOuter[jn], lipInner[jn], lipOuter[jn], lipInner[j]);
  }

  // Bases (fondo): abanico exterior e interior, normales constantes
  const bot = L - 1;
  const nDown = { x: 0, y: 1, z: 0 };
  const nFloor = { x: 0, y: -1, z: 0 };
  const cOuterIdx = pushVert({ x: 0, y: meshOuter[bot][0].y, z: 0 }, nDown);
  const cInnerIdx = pushVert({ x: 0, y: meshInner[bot][0].y, z: 0 }, nFloor);
  const baseOuter = [], baseInner = [];
  for (let j = 0; j < S; j++) {
    baseOuter.push(pushVert(meshOuter[bot][j], nDown));
    baseInner.push(pushVert(meshInner[bot][j], nFloor));
  }
  for (let j = 0; j < S; j++) {
    const jn = (j + 1) % S;
    indices.push(cOuterIdx, baseOuter[jn], baseOuter[j]);
    indices.push(cInnerIdx, baseInner[j], baseInner[jn]);
  }

  return { positions, normals, indices };
}
