# vase_customizer_upc_mecion

**Editor de Vasija Paramétrica** — Proyecto Deshumidificador (Diseño y Función, UPC, 2026-10, Grupo 06).

Generador de una vasija organica cuya geometria completa (perfil, textura,
torsion, lobulos y "golpes" en la cintura) se controla mediante parametros
ajustables en tiempo real. Pensado como cuerpo ceramico/impreso para un
deshumidificador, permite explorar formas y exportarlas como solido STL
para impresion 3D.

**Demo en vivo (navegador, sin instalar nada):**
https://limasietecode.github.io/vase_customizer_upc_mecion/

## Dos versiones en este repositorio

| | Version | Archivos | Donde corre |
|---|---|---|---|
| 1 | **Processing / Android** (original) | `G06_COD_VASE_V4_0.pde`, `Parametros.pde`, `Slider.pde`, `Presets.pde`, `Snapshot.pde`, `Tema.pde`, `Exportar.pde`, `AndroidManifest.xml` | [Processing IDE](https://processing.org/) en modo Android, o exportada como app a un tablet/celular |
| 2 | **Web (p5.js)** — puerto de la anterior | `index.html`, `style.css`, `params.js`, `mesh.js`, `stl.js`, `presets.js`, `ui.js`, `sketch.js` | Cualquier navegador, via GitHub Pages (link arriba) o abriendo `index.html` con un servidor local |

Ambas comparten la misma logica generativa (perfil axial, ridges, lobulos,
golpes, twist) y el mismo set de parametros/rangos, para que un preset JSON
guardado en una version se pueda cargar en la otra.

La version web reemplaza el panel dibujado a mano de Processing por
controles HTML nativos (`<input type="range">`) — mas robusto y usable en
mobile/touch — pero mantiene el mismo lenguaje visual (tarjetas, botones
pill, acento azul, modo claro/oscuro).

## Controles

- **Arrastrar sobre el visor 3D**: orbita la camara alrededor de la vasija.
- **Rueda del mouse / pellizcar (touch)**: acerca / aleja la camara.
- **Doble click en un slider**: lo resetea a su valor por defecto.
- **Boton de tema** (circulo arriba a la derecha del panel): alterna modo
  claro/oscuro. El material de la vasija no cambia con el tema.

### Botones del panel

| Boton | Accion |
|---|---|
| ANIMAR | Activa/desactiva la animacion continua (rotacion de ridges, lobulos y golpes segun ANIM SPEED) |
| GUARDAR | Guarda el estado actual en el historial en memoria (para DESHACER) |
| DESHACER | Vuelve al estado anterior del historial |
| GUARDAR JSON | Descarga los parametros actuales como archivo `.json` (preset) |
| CARGAR JSON | Abre un archivo `.json` de preset y aplica los parametros reconocidos |
| EXPORTAR STL | Reconstruye la malla a resolucion completa y descarga un STL binario solido (pared doble + labio + bases), listo para impresion 3D |

### Atajos de teclado (version web y Processing)

`R` reset de camara · `S` guardar snapshot · `Z` deshacer · `E` exportar STL
· `P` guardar preset JSON · `O` cargar preset JSON · `T` cambiar tema

## Parametros generativos

La forma se construye sobre un **perfil axial** (radio segun la altura,
`profileRadius`) al que se le suman, en cada punto de la malla, tres capas
de detalle: **ridges** (textura fina), **lobulos** (ondulacion del borde
superior) y **golpes** (abolladuras localizadas cerca de la cintura). Todo
se calcula en un espacio normalizado de altura `0..1` (0 = base, 1 = borde
superior).

### FORMA — el perfil base de la vasija

| Parametro | Rango | Que controla |
|---|---|---|
| **BASE RADIUS** | 30 – 260 | Radio de la vasija en la base (parte inferior). |
| **WAIST RADIUS** | 10 – 200 | Radio en el punto mas angosto ("cintura"). |
| **TOP RADIUS** | 20 – 260 | Radio en el borde superior (boca de la vasija). |
| **TOTAL HEIGHT** | 100 – 600 | Altura total, de la base al borde. |
| **WAIST POSITION** | 0.2 – 0.8 | Posicion normalizada (0=base, 1=borde) donde se ubica la cintura. Valores bajos acercan la cintura a la base; altos, al borde. |
| **BASE BULGE** | 0.05 – 0.45 | Hasta que altura (normalizada) el radio se mantiene igual al de la base antes de empezar a angostarse hacia la cintura. Mas alto = "panza" mas alta y pronunciada. |
| **WALL THICKNESS** | 2 – 24 | Espesor radial de la pared (diferencia entre la superficie exterior e interior). Define el solido de doble pared usado en el STL. |

El perfil interpola (con suavizado tipo *smoothstep*) entre 4 puntos de
control: base → fin de la panza (`BASE_BULGE`) → cintura (`WAIST_POSITION`)
→ borde (`TOP_RADIUS`). Si `BASE_BULGE` y `WAIST_POSITION` coinciden, ese
tramo del perfil se colapsa a un salto directo (caso limite ya contemplado,
sin dividir por cero).

### SUPERFICIE — textura fina (ridges)

| Parametro | Rango | Que controla |
|---|---|---|
| **RIDGE COUNT** | 4 – 180 | Cantidad de estrias/canaletas finas repetidas alrededor de la circunferencia (patron tipo acanalado). |
| **RIDGE DEPTH** | 0 – 20 | Profundidad de esas estrias. En 0, la superficie queda lisa. |

### TRANSFORMACION — torsion

| Parametro | Rango | Que controla |
|---|---|---|
| **TWIST** | 0 – 3.0 (× π rad) | Rotacion helicoidal total aplicada desde la base hasta el borde: gira las estrias, lobulos y golpes en espiral alrededor del eje vertical. |

### BORDE — lobulos del borde superior

| Parametro | Rango | Que controla |
|---|---|---|
| **LOBE COUNT** | 1 – 10 | Cantidad de lobulos (ondas) alrededor del borde superior, como un borde festoneado o de flor. |
| **LOBE AMPLITUDE** | 0 – 80 | Cuanto se proyectan esos lobulos hacia afuera respecto al perfil base. |
| **LOBE START** | 0.3 – 0.95 | Altura normalizada desde la cual empiezan a aparecer los lobulos (con transicion suave). Mas alto = lobulos concentrados solo cerca del borde. |

### GOLPES — abolladuras en la cintura

Simulan "golpes" o abolladuras organicas distribuidas al azar (segun
`DENT_SEED`) alrededor de la cintura de la vasija.

| Parametro | Rango | Que controla |
|---|---|---|
| **DENT COUNT** | 1 – 12 | Cantidad de abolladuras distribuidas alrededor de la circunferencia. |
| **DENT AMPLITUDE** | 0 – 60 | Que tan profundo se hunde la superficie en cada abolladura. |
| **DENT WIDTH** | 0.02 – 0.4 | Ancho angular de cada abolladura (que tan concentrada o extendida es alrededor de su centro). |
| **DENT CENTER** | 0.2 – 0.8 | Altura normalizada donde se centra verticalmente la banda de abolladuras. |
| **DENT SPREAD** | 0.05 – 0.4 | Que tanto se extiende verticalmente esa banda alrededor de DENT CENTER (mas alto = banda mas ancha). |
| **DENT SEED** | 1 – 20 | Semilla aleatoria: fija los angulos y la magnitud relativa de cada abolladura. La misma semilla siempre da el mismo patron, para poder reproducir un resultado. |

### COMPORTAMIENTO

| Parametro | Rango | Que controla |
|---|---|---|
| **ANIM SPEED** | 0 – 0.03 | Con ANIMAR activado, que tan rapido rotan/pulsan ridges, lobulos y golpes en el tiempo. En 0, ANIMAR no produce movimiento visible. |
| **SHININESS** | 5 – 150 | Tamano/nitidez del brillo especular del material (mas alto = brillo mas chico y definido). |

## Presets JSON

`GUARDAR JSON` descarga un archivo con esta forma:

```json
{
  "app": "vasija_organica",
  "version": 1,
  "fecha": "20260713_153000",
  "parametros": { "base_radius": 140, "waist_radius": 70, "...": "..." }
}
```

Al cargar un preset, las claves reconocidas se aplican (ajustadas al rango
valido de cada slider); las claves desconocidas se ignoran y los
parametros ausentes conservan su valor actual — asi un preset viejo sigue
funcionando aunque se agreguen parametros nuevos mas adelante.

## Correr la version web en local

No requiere instalar dependencias (p5.js se carga desde un CDN). Como los
navegadores bloquean `fetch`/modulos al abrir un `index.html` directamente
con `file://`, sirve la carpeta con cualquier servidor estatico simple:

```bash
python -m http.server 8000
# luego abrir http://localhost:8000/index.html
```

## Estructura del repositorio

```
G06_COD_VASE_V4_0.pde   \
Parametros.pde           \
Slider.pde                 Sketch Processing / Android (version original)
Presets.pde                 (abrir con Processing IDE, modo Android)
Snapshot.pde              /
Tema.pde                 /
Exportar.pde             /
AndroidManifest.xml     /

index.html              \
style.css                \
params.js                  Puerto web (p5.js) — se publica automaticamente
mesh.js                     en GitHub Pages desde la raiz del repo
stl.js                    /
presets.js               /
ui.js                    /
sketch.js               /
```
