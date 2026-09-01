# ART_DIRECTION.md
## RPG Fantasía Oscura — Dirección artística del vertical slice

**Estado:** especificación visual de referencia  
**Uso:** preproducción, placeholders dirigidos y futura producción de assets  
**Importante:** las imágenes de `references/` son referencias visuales. No deben copiarse, trazarse ni reutilizarse como assets comerciales.

---

# 1. Identidad visual

El juego debe verse inicialmente como una aventura de fantasía clásica atractiva, acogedora y colorida, capaz de evolucionar gradualmente hacia decadencia, guerra, horror corporal y corrupción.

La imagen buscada combina:

- pixel art moderno inspirado en generaciones 16/32-bit;
- escenarios densos y legibles;
- proporciones de personaje suficientes para leer armas, ropa y siluetas;
- iluminación cálida en zonas prósperas;
- contraste fuerte cuando aparece corrupción;
- UI móvil horizontal clara;
- retratos expresivos para narrativa y relaciones;
- combate táctico legible sin romper la estética de exploración.

El mundo NO debe verse permanentemente oscuro.

La oscuridad funciona porque existe contraste con:
- pueblos acogedores;
- mercados;
- vegetación;
- festivales;
- hogares;
- amaneceres;
- arquitectura cuidada.

---

# 2. Referencias conceptuales

Las siguientes obras son referencias de concepto y lenguaje, no objetivos de copia.

## Berserk

Tomar:
- decadencia progresiva;
- guerra;
- horror corporal;
- tragedia humana;
- ambigüedad entre humano y monstruo;
- sensación de que el mundo puede deteriorarse mucho más de lo esperado.

No tomar:
- oscuridad permanente;
- exceso de gore como sustituto de narrativa.

## The Elder Scrolls IV: Oblivion

Tomar:
- fantasía heroica reconocible;
- caminos, bosques, pueblos y castillos que invitan a explorar;
- sensación de aventura clásica;
- belleza de un mundo que vale la pena proteger.

## Life in Adventure

Tomar:
- presentación compacta de decisiones;
- retratos;
- tarjetas narrativas;
- consecuencias visibles;
- interfaz que puede comunicar una situación compleja con pocos elementos.

No copiar su orientación vertical como layout principal.

## Fire Emblem

Tomar:
- legibilidad de personajes;
- retratos;
- relaciones;
- previsión de resultados;
- claridad del combate táctico.

## Albion Online

Tomar:
- lectura móvil de botones;
- claridad de equipamiento;
- acciones accesibles con pulgar;
- economía y recursos fáciles de leer.

## Dofus

Tomar:
- densidad de mapas;
- composición visual por escenas;
- cuadrícula táctica clara;
- siluetas distinguibles.

## Diablo

Tomar:
- sensación de peligro en mazmorras;
- feedback de impacto;
- monstruosidad;
- lectura inmediata de enemigos;
- contraste entre civilización segura y espacios hostiles.

---

# 3. Dirección de exploración

## Perspectiva

Usar:

**3/4 top-down con sensación isométrica ligera.**

No exigir una isometría matemática rígida en toda exploración.

Objetivos:
- buen control ARPG;
- lectura clara en móvil;
- interiores sencillos;
- Y-sort natural;
- mapas densos.

La cuadrícula estricta aparece principalmente en el combate táctico.

## Densidad

Cada pantalla de una ciudad/pueblo debe intentar contener varios elementos de interés:

- arquitectura;
- vegetación;
- NPC;
- carteles;
- mobiliario;
- puestos;
- pequeños props;
- rutas secundarias.

Evitar:
- superficies enormes vacías;
- plazas gigantes sin función;
- repetición obvia de una misma casa.

## Escala

Baseline visual inicial:
- personaje: ~40–48 px visibles de altura dentro de una celda de sprite mayor;
- puertas: ~1.4–1.7 veces la altura visible del personaje;
- casas pequeñas: 3–5 personajes de ancho;
- calles principales: 2.5–4 personajes de ancho;
- caminos secundarios: 1.5–2.5 personajes.

Estos valores deben validarse en el primer prototipo.

---

# 4. Liria

Liria debe parecer un lugar en el que alguien realmente querría vivir antes del ataque.

## Rasgos

- piedra y madera;
- techos rojizos y algunos azul pizarra;
- abundante vegetación;
- flores;
- árboles maduros;
- pequeñas huertas;
- herrería;
- mercado modesto;
- fuente/estatua/plaza como hito;
- iluminación cálida;
- arquitectura medieval europea sin lujo aristocrático.

## Paleta conceptual

Predominio:
- verdes naturales;
- marrones cálidos;
- piedra beige/gris;
- teja roja;
- madera tostada;
- azul apagado;
- dorados de luz.

Acentos:
- flores;
- pendones;
- frutas;
- ropa de NPC.

## Estado de ataque

No convertir todo inmediatamente en negro/gris.

Cambiar mediante:
- fuego;
- humo;
- rojos;
- pérdida de luz cálida;
- props rotos;
- caminos bloqueados;
- cuerpos/objetos abandonados;
- fachadas dañadas.

El jugador debe reconocer exactamente el mismo pueblo.

---

# 5. Cyrion

Contraste con Liria.

Materiales:
- piedra blanca antigua;
- metal negro;
- bronce pálido;
- cristal;
- canales de luz.

Colores activos:
- azul blanco;
- violeta tenue;
- oro pálido.

Regla:
- nunca cyberpunk;
- tecnología incomprensible pero físicamente integrada en arquitectura antigua.

---

# 6. Corrupción

La corrupción no aplica un filtro morado global.

Debe aparecer localizada en:

- piel;
- ojos;
- tejido;
- suelo;
- magia;
- sombras;
- reflejos;
- arquitectura activada.

Colores frecuentes:
- violeta profundo;
- rojo oscuro;
- negro cálido;
- magenta controlado;
- azul eléctrico en Resonancia antigua.

El mundo no pierde sus colores naturales hasta estados extremadamente avanzados.

---

# 7. Personajes

Evitar chibi extremo.

Necesitamos leer:
- arma;
- peinado;
- armadura;
- capa;
- clase;
- corrupción.

La cabeza puede ser ligeramente mayor que en anatomía real para mejorar expresividad pixel art, pero el cuerpo debe conservar sensación aventurera y no infantil.

---

# 8. Retratos

Retratos deben:
- mostrar rostro y hombros;
- tener alto contraste facial;
- conservar rasgos del sprite;
- admitir versiones emocionales.

Estados mínimos por NPC principal:
- neutral;
- preocupado;
- enfadado;
- herido/corrupto cuando aplique.

---

# 9. Interfaz

La UI no debe intentar parecer un pergamino medieval pesado.

Dirección:
- panel oscuro;
- borde metálico/bronce/dorado;
- iconografía clara;
- tipografía legible;
- acentos regionales;
- información jerarquizada.

El mundo puede ser medieval.
La interfaz debe seguir siendo cómoda.

---

# 10. Prohibiciones visuales

No:
- copiar composiciones exactas de las referencias;
- utilizar personajes de referencias;
- extraer sprites;
- trazar assets;
- mezclar cinco estilos de pixel art incompatibles;
- usar UI de juego móvil genérica tipo gacha;
- llenar cada borde con decoración;
- aplicar bloom/neón excesivo;
- usar assets 3D prerenderizados que rompan la coherencia del pixel art;
- cambiar la escala de sprites entre regiones sin motivo.

---

# 11. Regla de placeholders

Los placeholders deben respetar desde el principio:

- escala aproximada final;
- orientación;
- hitbox;
- pivot;
- silueta;
- arma;
- volumen arquitectónico;
- distribución UI.

Pueden carecer de:
- detalle;
- animación completa;
- sombreado final;
- VFX final.

Esto permite reemplazar arte sin rehacer gameplay.
