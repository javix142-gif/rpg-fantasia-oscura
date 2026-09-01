# RPG FANTASÍA OSCURA — PREPRODUCCIÓN CONSOLIDADA 01–14
## Documento canónico de sistemas, contenido y preparación de implementación

**Versión:** 1.0  
**Estado:** CANON DE PREPRODUCCIÓN  
**Plataforma inicial:** Android  
**Orientación:** Landscape  
**Motor propuesto:** Godot 4.7.2 Standard  
**Lenguaje:** GDScript  
**Representación:** 2D isométrico / pixel art moderno  
**Objetivo:** consolidar en un solo documento los 14 bloques de diseño preproducción ya definidos.

---

# 0. Principios de alcance

Este documento parte de un canon narrativo ya definido en archivos separados:

- cuatro subreinos;
- Cyrion;
- Imperio de Ilyrion;
- Cinco Divinos;
- origen de la corrupción;
- historia principal y finales.

Este archivo NO sustituye esos documentos. Su función es convertir ese canon en:

- contenido implementable;
- sistemas;
- estructuras de datos;
- alcance real;
- UX móvil;
- arquitectura;
- vertical slice.

Reglas:

1. **Menos superficie, más densidad.**
2. **Todo sistema importante debe interactuar al menos con otro.**
3. **No crear simulaciones excesivas cuando un sistema de estados/flags produce la misma reactividad percibida.**
4. **Contenido data-driven siempre que sea posible.**
5. **Balance numérico definitivo sólo después de playtesting.**
6. **No aumentar alcance antes de validar el vertical slice.**

---

# 1. COMPAÑEROS PRINCIPALES — ELENCO EMOCIONAL

## 1.1 Party

Máximo en combate:

**3 personajes**
- protagonista;
- compañero 1;
- compañero 2.

Los demás reclutados permanecen en:
- campamento;
- posada;
- base;
- Ceniza;
- localización narrativa.

Objetivo total:

**8 compañeros principales reclutables**.

Además:
- 4–6 acompañantes temporales importantes.

## 1.2 Sistema de relación

### Afinidad
`-100 → +100`

Representa cuánto aprecia personalmente al protagonista.

### Confianza
`0 → 3`

Representa cuánto está dispuesto a arriesgar por él.

Afinidad y confianza no son lo mismo.

### Convicciones
Flags internos que definen evolución ideológica.

Ejemplo:

```text
YSARA_FAITH_ORTHODOX
YSARA_FAITH_REFORM
YSARA_FAITH_BROKEN
```

### Líneas rojas
Ciertas decisiones pueden producir:
- discusión;
- caída de afinidad;
- abandono;
- traición;
- combate.

---

## 1.3 Iria Halven

**Origen:** Liria  
**Raza:** humana  
**Edad:** 24  
**Clase:** Arquera  
**Especialización posible:** Ranger / Explorer  
**Rol emocional:** vínculo con la vida anterior del protagonista.

Rasgos:
- práctica;
- sarcástica;
- valiente;
- protectora de Liria;
- desconfiada de nobles.

Conflicto:

> El protagonista puede terminar convirtiéndose en alguien que Iria ya no reconoce.

Puede reaccionar especialmente a:
- poder político;
- riqueza;
- corrupción;
- autoritarismo.

### Reclutamiento
Depende del prólogo:
- puede sobrevivir bien;
- sobrevivir herida;
- en resultados extremos, morir.

### Quest personal
**CQ_IRIA_01 — Lo que dejamos atrás**

Temas:
- supervivientes;
- recuerdos;
- reconstrucción o abandono de Liria.

### Destinos
- reconstruye Liria;
- exploradora;
- permanece con protagonista;
- parte al Nuevo Mundo;
- abandona;
- muere.

---

## 1.4 Hermana Ysara

**Origen:** Aureval  
**Raza:** humana  
**Edad:** 26  
**Clase:** Clérigo  
**Especializaciones:** Priest / Paladin / Apostate  
**Rol:** fe frente a institución.

Rasgos:
- compasiva;
- disciplinada;
- idealista;
- serena.

Conflicto:

> Descubrir que Aureon fue humano sin que eso necesariamente destruya su fe.

Evoluciones:
- ortodoxa;
- reformista;
- apóstata.

Línea roja:
- sacrificio deliberado de civiles;
- uso de personas como recursos;
- ciertas formas extremas de NEXUS.

Puede tolerar:
- corrupción;
- magia oscura;
si existen razones suficientes.

### Quest personal
**CQ_YSARA_01 — La fe que permanece**

---

## 1.5 Lyra Serrat

**Origen:** Vesperia  
**Edad:** 32  
**Clase:** Espadachín  
**Especialización:** Duelista  
**Rol:** deber contractual frente a moral personal.

Principio:

> “Un contrato firmado se cumple.”

Rasgos:
- directa;
- profesional;
- inteligente;
- humor seco.

### Reclutamiento
Durante Gran Almacén IX si el jugador demuestra:
- competencia;
- respeto contractual;
- o prueba que sus empleadores incumplieron primero.

### Quest personal
**CQ_LYRA_01 — La última cláusula**

Tema:
- legalidad;
- contrato;
- responsabilidad moral.

Destino predeterminado fuera de reclutamiento:
- Puente de las Tres Grúas.

Como compañera puede:
- sobrevivir;
- morir;
- fundar compañía ética;
- volverse general;
- abandonar mercenarismo.

---

## 1.6 Neris Vael

**Origen:** extranjera residente en Vesperia  
**Raza:** elfa  
**Edad aparente:** 31  
**Clase:** Arquera  
**Especialización:** Explorer / Ranger  
**Rol:** mundo exterior y posibilidad de huir.

Conexión:
- Compañía del Horizonte;
- rutas marítimas;
- Nuevo Mundo.

Rasgos:
- curiosa;
- irónica;
- independiente.

Su perspectiva:

> Salvar el continente no es una obligación automática del protagonista.

Es quien mantiene abierta desde temprano la opción:

**“Podemos irnos.”**

### Quest personal
**CQ_NERIS_01 — Donde termina el mapa**

---

## 1.7 Sor Elira Veyn

**Origen:** Serath  
**Edad:** 29  
**Clase:** Hechicero  
**Especialización:** Arcanista  
**Ruta alternativa:** magia prohibida controlada  
**Rol:** curiosidad y verdad.

Rasgos:
- inteligente;
- educada;
- socialmente torpe;
- creyente al inicio;
- necesita saber.

### Mecánica especial
Su lente permite detectar:
- pigmentos;
- tintas;
- símbolos;
- mecanismos;
- textos borrados.

No es obligatoria para completar el juego, pero abre:
- secretos;
- loot;
- lore.

### Quest personal
**CQ_ELIRA_01 — La página que falta**

Puede:
- publicar;
- ocultar;
- conservar;
- destruir información.

Destino predeterminado:
**La Cronista Sin Orden.**

---

## 1.8 Eirik Brenn

**Origen:** Keldran  
**Edad:** 27  
**Clase:** Guerrero  
**Estado:** MOR  
**Especialización inicial:** Monster Hunter / Warrior  
**Ruta:** Consciente  
**Rol:** humanidad de los demonios.

Rasgos:
- reservado;
- leal;
- humor seco;
- miedo a perder control.

### Apariencia dinámica
Tres etapas visuales:
- casi humano;
- alterado;
- integrado.

### Recurso especial
**Tensión MOR**

Aumenta:
- fuerza;
- regeneración;
- habilidades;
pero eleva riesgo de pérdida de control.

### Quest personal
**CQ_EIRIK_01 — Todavía soy yo**

Posibles resultados:
- tratamiento;
- Integración;
- Ruptura;
- Ascensión;
- ejecución.

---

## 1.9 Bramm Karhold

**Origen:** Keldran  
**Raza:** enano  
**Edad:** 46  
**Clase:** Guerrero  
**Especialización:** Guardián / Maestro de Armas  
**Rol:** pragmatismo, trabajo y culpa.

Era supervisor de una mina de Karhold.

Firmó una orden que contribuyó a abrir sectores profundos antes del Gran Brote.

Rasgos:
- brusco;
- trabajador;
- protector;
- desconfiado de académicos.

### Quest personal
**CQ_BRAMM_01 — Bajo la piedra**

Decisiones:
- revelar;
- asumir culpa;
- responsabilizar a autoridades;
- destruir evidencia.

---

## 1.10 Tavia “Sable” Meret

**Origen:** Ceniza  
**Raza:** humana  
**Edad:** 28  
**Clase:** Espadachín  
**Especialización:** Assassin  
**Rol:** supervivencia urbana y pragmatismo.

Vinculada ocasionalmente a:
- Sin Firma;
- buscarruinas.

Rasgos:
- rápida;
- cínica;
- divertida;
- oportunista;
- muy observadora.

### Función jugable
- críticos;
- debuffs;
- rutas alternativas;
- checks contextuales.

No se crea un sistema stealth completo.

### Quest personal
**CQ_SABLE_01 — Todo tiene dueño**

---

## 1.11 Acompañantes temporales

Posibles:
- Astrid Harken;
- Malrec Thane;
- Maera Hroven;
- Sir Corvin Halbrecht;
- Mael Varos;
- NPC específicos.

---

## 1.12 Cobertura de roles

| Compañero | Función |
|---|---|
| Iria | rango / exploración |
| Ysara | curación / soporte |
| Lyra | daño individual |
| Neris | rango / movilidad |
| Elira | magia / control |
| Eirik | bruiser / riesgo |
| Bramm | tanque / control |
| Sable | críticos / debuffs |

---

# 2. MAPA MUNDIAL LÓGICO — TAMAÑO REAL DEL JUEGO

## 2.1 Filosofía

No mundo abierto completo.

Sí:
- regiones conectadas;
- nodos;
- zonas densas;
- backtracking significativo;
- fast travel progresivo.

Objetivo:

**34–38 nodos macro.**

---

## 2.2 Volumen objetivo

| Tipo | Cantidad |
|---|---:|
| Capitales/hubs grandes | 5 |
| Ciudades/pueblos secundarios | 9–11 |
| Fortalezas/campamentos | 5–7 |
| Zonas naturales | 10–12 |
| Mazmorras principales | 8–9 |
| Mazmorras menores | 8–12 |
| POI secretos | 20–30 |

---

## 2.3 Estructura continental

```text
                    KELDRAN
                       │
                  Paso Imperial
                       │
AUREVAL ─────── CYRION / CENIZA ─────── SERATH
                       │
                  Camino del Sur
                       │
                   VESPERIA
```

Liria:
- cercana a Cyrion;
- ligeramente al sudoeste;
- conectada por antigua ruta imperial.

---

## 2.4 Región central

- `N00` Liria
- `N01` Camino Prohibido
- `N02` Ceniza
- `N03` Anillo de las Ruinas
- `N04` Anillo Interior
- `N05` Concordia
- `N06` Profundidades

---

## 2.5 Aureval

- `A01` Valdoren
- `A02` Llanuras de Ceyra
- `A03` Aldea del Surco
- `A04` Bosque de Orvel
- `A05` Villa Orvel
- `A06` Marca de Brannic
- `A07` Cripta de las Coronas
- `A08` Ruinas del Bosque

---

## 2.6 Vesperia

- `V01` Vespera
- `V02` Merova
- `V03` Calenne
- `V04` Marismas de Salver
- `V05` Calle Sin Nombre
- `V06` Gran Almacén IX
- `V07` Astilleros del Horizonte

---

## 2.7 Serath

- `S01` Caelium
- `S02` Valle de Eiren
- `S03` Altos de Mirath
- `S04` Minas de Argen
- `S05` Jardines del Alivio
- `S06` Archivo de la Quinta Lámpara
- `S07` Catacumbas de Mirath

---

## 2.8 Keldran

- `K01` Brann-Keld
- `K02` Valle de Brenn
- `K03` Bosque de Hroven
- `K04` Karhold
- `K05` Paso de Vard
- `K06` Fuerte Harken
- `K07` Mina sin Eco
- `K08` Campamento de las Brasas

---

## 2.9 Viajes

Tres modos:
1. overworld corto;
2. viaje automático una vez descubierta la ruta;
3. fast travel mediante caminos, caravanas, barcos y nodos imperiales.

Viajes pueden activar:
- encuentros;
- eventos;
- cambios de estado;
sin spam de batallas aleatorias.

---

## 2.10 Estados de mapa

Modelo base:

```text
STATE_0_NORMAL
STATE_1_TENSION
STATE_2_CRISIS
STATE_3_COLLAPSE
STATE_4_POST
```

No todos los nodos requieren cinco estados.

Cambian:
- NPC;
- tiendas;
- enemigos;
- música;
- iluminación;
- accesos.

---

# 3. MAIN QUESTS — HISTORIA IMPLEMENTABLE

## 3.1 Cantidad

Objetivo:

**aprox. 38 Main Quests**.

Formato técnico base:

```text
PRECONDITIONS
OBJECTIVES
OPTIONAL_OBJECTIVES
FAIL_STATES
FLAGS_SET
WORLD_STATE_CHANGES
REWARDS
NEXT_QUESTS
```

---

## 3.2 Prólogo

| ID | Quest |
|---|---|
| MQ00_01 | Un día cualquiera |
| MQ00_02 | La última noche de Liria |
| MQ00_03 | El estuche de Halven |

### MQ00_01
- clase inicial;
- movimiento;
- NPC;
- interacción;
- tutorial.

### MQ00_02
Decisiones:
- defender plaza;
- salvar familia;
- perseguir atacantes.

Boss:
- Radan Korr.

Flags:
```text
LIRIA_PLAZA_RESULT
LIRIA_FAMILY_RESULT
LIRIA_PURSUIT_RESULT
IRIA_STATUS
```

### MQ00_03
- Collar;
- activación inicial;
- respuesta de Cyrion.

---

## 3.3 Capítulo 1

| ID | Quest |
|---|---|
| MQ01_01 | Lo que quedó |
| MQ01_02 | Aquello que buscan |
| MQ01_03 | La carretera prohibida |

---

## 3.4 Capítulo 2

| ID | Quest |
|---|---|
| MQ02_01 | Ceniza |
| MQ02_02 | Cuatro banderas |
| MQ02_03 | El historiador |
| MQ02_04 | La puerta que respondió |

---

## 3.5 Capítulo 3

| ID | Quest |
|---|---|
| MQ03_01 | Cinco espacios |
| MQ03_02 | Las cuatro llaves |

Final:
- apertura regional;
- soft gating.

---

## 3.6 Aureval

| ID | Quest |
|---|---|
| MQ_AUR_01 | Camino a Valdoren |
| MQ_AUR_02 | La cosecha dorada |
| MQ_AUR_03 | Sangre en palacio |
| MQ_AUR_04 | El Círculo Blanco |
| MQ_AUR_05 | Cripta de las Coronas |

Resultado:
- revelación AUREA;
- decisión sobre verdad;
- `KEY_AUREVAL`.

---

## 3.7 Vesperia

| ID | Quest |
|---|---|
| MQ_VES_01 | Las Mil Voces |
| MQ_VES_02 | Un reino a crédito |
| MQ_VES_03 | Sangre embotellada |
| MQ_VES_04 | Gran Almacén IX |
| MQ_VES_05 | El precio del contrato |

Resultado:
- revelación Vitae;
- decisión sobre producción;
- `KEY_VESPERIA`.

---

## 3.8 Serath

| ID | Quest |
|---|---|
| MQ_SER_01 | Ciudad de las Campanas |
| MQ_SER_02 | Los pacientes |
| MQ_SER_03 | El verso ausente |
| MQ_SER_04 | Quinta Lámpara |
| MQ_SER_05 | El peso de la verdad |

Resultado:
- revelación de humanos alterados;
- LUX;
- decisión sobre documentos;
- `KEY_SERATH`.

---

## 3.9 Keldran

| ID | Quest |
|---|---|
| MQ_KEL_01 | Las Marcas |
| MQ_KEL_02 | Los que regresaron |
| MQ_KEL_03 | Todavía habla |
| MQ_KEL_04 | Mina sin Eco |
| MQ_KEL_05 | Nadie sobrevivirá por ti |

Resultado:
- MOR;
- Conscientes;
- política de infectados;
- `KEY_KELDRAN`.

---

## 3.10 Cyrion final

| ID | Quest |
|---|---|
| MQ_CYR_01 | Los cuatro regresan |
| MQ_CYR_02 | El hombre detrás del ataque |
| MQ_CYR_03 | Pentarca |
| MQ_CYR_04 | Quinta Puerta |
| MQ_CYR_05 | La ciudad que recuerda |
| MQ_CYR_06 | El que permaneció |
| MQ_CYR_07 | Las Cinco Luces |
| MQ_CYR_08 | Última Concordia |

---

## 3.11 Final

| ID | Quest |
|---|---|
| MQ_FIN_01 | Antes del último descenso |
| MQ_FIN_02 | El corazón de Ilyrion |
| MQ_FIN_03 | La respuesta |

---

# 4. SECUNDARIAS — CONTENIDO REGIONAL

## 4.1 Alcance

Objetivo:
- 30 secundarias regionales principales;
- 8 quests personales;
- contratos reutilizables.

Total escrito objetivo:
**~38 quests secundarias.**

---

## 4.2 Liria / Cyrion

- `SQ_CYR_01` Cinco velas
- `SQ_CYR_02` Nadie reclama a los muertos
- `SQ_CYR_03` El objeto que no debería venderse
- `SQ_CYR_04` La casa que no estaba
- `SQ_CYR_05` Devolver un nombre
- `SQ_CYR_06` Ninguna bandera

---

## 4.3 Aureval

- `SQ_AUR_01` Pan para tres días
- `SQ_AUR_02` El caballo sin jinete
- `SQ_AUR_03` Sangre limpia
- `SQ_AUR_04` Las viñas de Edevane
- `SQ_AUR_05` Un juramento roto
- `SQ_AUR_06` León de Mármol

---

## 4.4 Vesperia

- `SQ_VES_01` El precio del hambre
- `SQ_VES_02` Contrato imposible
- `SQ_VES_03` Monedas negras
- `SQ_VES_04` Huelga del muelle
- `SQ_VES_05` Calle Sin Nombre
- `SQ_VES_06` El último barco de Calenne

---

## 4.5 Serath

- `SQ_SER_01` El verso ausente
- `SQ_SER_02` Paciente 47
- `SQ_SER_03` El libro que no existe
- `SQ_SER_04` La campana cerrada
- `SQ_SER_05` Caridad y doctrina
- `SQ_SER_06` El Bibliotecario

---

## 4.6 Keldran

- `SQ_KEL_01` Lo que volvió del bosque
- `SQ_KEL_02` Un lugar junto al fuego
- `SQ_KEL_03` Sangre en la nieve
- `SQ_KEL_04` Sin Clan
- `SQ_KEL_05` El niño de ojos negros
- `SQ_KEL_06` Madre de Astas

---

## 4.7 Quests de compañeros

```text
CQ_IRIA_01     Lo que dejamos atrás
CQ_YSARA_01    La fe que permanece
CQ_LYRA_01     La última cláusula
CQ_NERIS_01    Donde termina el mapa
CQ_ELIRA_01    La página que falta
CQ_EIRIK_01    Todavía soy yo
CQ_BRAMM_01    Bajo la piedra
CQ_SABLE_01    Todo tiene dueño
```

Cada una:
- altera evolución;
- desbloquea skill/passiva;
- modifica epílogo.

---

## 4.8 Contratos reutilizables

Templates:
- cacería;
- búsqueda;
- escolta;
- entrega con riesgo real;
- bounty.

No usar contenido vacío tipo:
> “mata 10 lobos”

salvo que exista contexto significativo.

---

# 5. CLASES / BUILDS — PROGRESIÓN

## 5.1 Nivel

Baseline:
**nivel máximo 30**.

Postgame opcional:
**35**.

No diseñar nivel 100.

---

## 5.2 Atributos

| Atributo | Función |
|---|---|
| FUE | daño físico |
| VIT | HP / resistencia física |
| DES | precisión / rango / críticos |
| INT | magia ofensiva |
| VOL | MP / resistencia mágica / soporte |
| AGI | iniciativa / evasión / movilidad |

Derivados:
- HP;
- MP;
- ataque;
- defensa;
- poder mágico;
- resistencia mágica;
- precisión;
- crítico;
- evasión;
- iniciativa;
- movimiento.

---

## 5.3 Progresión por nivel

Cada nivel:
- crecimiento automático de clase;
- 1 punto de atributo libre;
- 1 punto de habilidad.

Cada 5 niveles:
- punto de talento adicional.

---

## 5.4 Especializaciones

No se desbloquean sólo por nivel.

Requieren:
- maestro;
- academia;
- libro;
- misión;
- facción;
- corrupción;
- evento.

Nivel mínimo recomendado:
**8**.

Se pueden descubrir varias, pero sólo una está activa a la vez.

Cambio:
- campamento;
- posada;
- maestro.

---

## 5.5 Guerrero

Recurso:
**Impulso**

Base:
- Golpe Pesado;
- Guardia;
- Provocar;
- Barrido;
- Avance;
- Segundo Aliento.

Especializaciones:
- Caballero;
- Berserker;
- Guardián;
- Warlord;
- Veterano Soldado como mastery track.

---

## 5.6 Espadachín

Recurso:
**Enfoque**

Base:
- Corte Rápido;
- Estocada;
- Parada;
- Paso Lateral;
- Corte Ascendente;
- Remate.

Especializaciones:
- Duelista;
- Maestro de Armas;
- Runeblade;
- Assassin;
- Cursed Blade.

---

## 5.7 Arquero

Recurso:
**Concentración**

Base:
- Disparo Preciso;
- Disparo Rápido;
- Retroceso;
- Marca;
- Flecha Perforante;
- Trampa Simple.

Especializaciones:
- Hunter;
- Marksman;
- Ranger;
- Monster Hunter;
- Explorer como mastery track.

---

## 5.8 Hechicero

Recursos:
- MP;
- Canalización.

Base:
- Proyectil Arcano;
- Barrera;
- Chispa;
- Llama;
- Escarcha;
- Canalizar.

Especializaciones:
- Elementalist;
- Arcanist;
- Warlock;
- Necromancer;
- Blood Mage.

---

## 5.9 Clérigo

Recurso:
**Fervor**

Base:
- Curación;
- Luz;
- Bendición;
- Purificar;
- Escudo de Fe;
- Reanimar.

Especializaciones:
- Priest;
- Paladin;
- Inquisitor;
- Healer;
- Apostate.

---

## 5.10 Loadout móvil

Cada personaje equipa:
- 4 activas;
- 1 habilidad de clase;
- 1 ultimate;
- 3 pasivas.

No mostrar 18 botones simultáneamente.

---

## 5.11 Respec

Disponible por:
- entrenador;
- pago.

Resetea:
- atributos libres;
- skill points.

No cambia:
- clase base;
- historia.

---

# 6. COMBATE — MECÁNICA CENTRAL CERRADA

## 6.1 Dos modos, un núcleo

### Exploración
ARPG rápido.

### Encuentros importantes
Combate táctico CT/timeline.

Ambos usan:

```text
Actor
Stats
Equipment
Ability
StatusEffect
Damage
Element
Resistance
```

---

## 6.2 ARPG

Controles:
- joystick;
- ataque;
- dodge;
- skill 1–4;
- consumible;
- habilidad contextual/clase.

Companions:
- IA.

Ataque básico:
- siempre relevante;
- genera recursos;
- daño consistente.

Dodge:
- ventana moderada;
- no soulslike.

---

## 6.3 IA de compañeros

Perfiles:
- Agresivo;
- Equilibrado;
- Defensivo.

Reglas:
- mantener distancia;
- priorizar curación;
- ahorrar MP;
- atacar objetivo marcado.

---

## 6.4 Transición táctico

Se activa en:
- bosses;
- elites narrativos;
- duelos;
- encuentros importantes.

Conserva aproximadamente:
- posición inicial.

Emboscada/sorpresa:
- modifica CT/posición.

---

## 6.5 Grid

Baseline:
**8 × 6**

Arenas especiales:
**10 × 8**

Isométrico visual, lógica ortogonal.

---

## 6.6 CT Timeline

Cada actor acumula:
`CT`

Al llegar a:
`100`

obtiene turno.

AGI afecta carga.

Acciones rápidas:
- menor retraso.

Acciones pesadas:
- mayor coste CT.

Timeline visible:
- próximos 8–10 turnos.

---

## 6.7 Turno

Permite:
- movimiento;
- acción.

Orden flexible si la habilidad lo permite.

Movimiento base:
- pesado: 3;
- normal: 4;
- ligero: 5.

---

## 6.8 Posicionamiento

Lateral:
- pequeño bonus crítico.

Espalda:
- bonus de daño/crítico.

Elevación sólo en arenas seleccionadas.

---

## 6.9 Elementos

- fuego;
- hielo;
- rayo;
- viento.

Baseline:

| Estado | Multiplicador |
|---|---:|
| inmune | 0 |
| resistente | 0.5 |
| normal | 1 |
| débil | 1.5 |

---

## 6.10 Daño

Baseline:

```text
BaseDamage =
AbilityPower
× OffensiveStatFactor
× DefenseFactor
× ElementFactor
× CriticalFactor
× Variance
```

```text
DefenseFactor = 100 / (100 + Defense)
```

Crítico:
**x1.5** baseline.

---

## 6.11 Estados

- Veneno.
- Quemadura.
- Congelación.
- Shock.
- Sueño.
- Silencio.
- Sangrado.
- Ceguera.
- Miedo.
- Corrupto.
- Aturdido.

---

## 6.12 Stagger

Bosses tienen:
**Barra de Ruptura**

Se reduce con:
- golpes pesados;
- debilidades;
- partes;
- mecánicas.

Al vaciar:
- estado Vulnerable.

---

## 6.13 Crowd control en bosses

No inmunidad absoluta.

Ejemplos:
- Sleep → contribuye stagger;
- Stun → interrupción breve;
- Silence → bloquea skills concretas.

---

## 6.14 Partes corporales

Sólo bosses seleccionados.

Puede:
- quitar habilidades;
- cambiar fases;
- alterar loot.

---

## 6.15 Ultimate

Una por personaje.

Requiere recurso acumulado.

No uso constante.

---

## 6.16 Consumibles

Consumir objeto:
- usa acción.

---

## 6.17 KO y derrota

0 HP:
- KO.

Puede revivirse.

Todos KO:
- derrota.

---

## 6.18 Escape

Normal:
- basado en AGI y situación.

Boss narrativo:
- puede estar bloqueado.

---

## 6.19 Velocidad

- ×1
- ×2
- ×3

Auto:
- encuentros triviales;
- no bosses complejos.

---

## 6.20 Boss design

Cada boss importante necesita:
1. gimmick;
2. decisión táctica;
3. cambio de fase.

No esponjas de HP.

QTE:
- sólo setpieces;
- desactivables;
- nunca requisito central.

Dificultad:
- Normal;
- Difícil.

Difícil cambia:
- IA;
- composición;
- agresividad;
- recursos;
no sólo HP.

---

# 7. BESTIARIO — CONTENIDO DE COMBATE

## 7.1 Principios

El bestiario debe demostrar:
1. existe fauna fantástica no demoníaca;
2. no todo monstruo es MOR;
3. los demonios conservan rastros humanos.

---

## 7.2 Alcance

| Categoría | Arquetipos |
|---|---:|
| animales/bestias | 10 |
| humanoides | 9 |
| MOR/demonios | 14 |
| constructos imperiales | 8 |
| elites/bosses | 15–20 |

Objetivo artístico:
**~40 familias visuales reales**, reutilizando rigs.

---

## 7.3 Fauna base

- Lobo de Camino.
- Jabalí Negro.
- Araña de Raíz.
- Murciélago de Caverna.
- Ciervo de Bruma.
- Oso Gris.
- Basilisco Menor.
- Serpiente de Cristal.
- Grifo Silvestre.
- Madre de Astas.

---

## 7.4 Humanoides

- Bandido.
- Arquero bandido.
- Mercenario.
- Duelista.
- Mago renegado.
- Clérigo fanático.
- Contrabandista.
- Soldado pesado.
- Cazador.

Se regionalizan mediante:
- ropa;
- armas;
- stats;
- skills.

---

## 7.5 MOR

Todo demonio conserva al menos un rastro de identidad anterior:
- ropa;
- anillo;
- tatuaje;
- herramienta;
- cicatriz;
- armadura;
- voz.

### Etapa II/III
- Febril.
- Ojo Largo.
- Desollado Frío.

### Ruptura
- Corredor.
- Bastión.
- Hambriento.
- Murmurante.
- Resonante.
- Tejedor.
- Hueco.

### Conscientes hostiles
- Exiliado.
- Cazador Invertido.
- Predicador de la Carne.

### Ascendidos
Muy raros.
Ejemplos:
- Sangre Coronada.
- Náufrago.
- Primer Vigía.
- altos agentes de Edran.

---

## 7.6 Constructos imperiales

- Centinela.
- Custodio.
- Esfera de LUX.
- Araña de Mantenimiento.
- Archivista.
- Barrera Móvil.
- Regulador.
- Pentarca.

---

## 7.7 Temas regionales

### Aureval
orden y sangre.

### Vesperia
cuerpos convertidos en producto.

### Serath
purificación y conocimiento.

### Keldran
humanidad e infección.

### Cyrion
tecnología imperial + MOR antiguo + Quinta Concordia.

---

## 7.8 Bestiario narrativo

Las entradas se actualizan según conocimiento.

Ejemplo inicial:

```text
MURMURANTE
Criatura demoníaca encontrada en las Marcas.
Su vocalización parece imitar voces humanas.
```

Después:

```text
MURMURANTE
Forma de Ruptura MOR.
Las palabras no son imitaciones.
Algunos individuos conservan fragmentos de memoria.
```

---

## 7.9 Reutilización de producción

Rigs base:
- humano ligero;
- humano pesado;
- MOR ligero;
- MOR grande;
- constructo pequeño;
- constructo humanoide;
- bestia cuadrúpeda;
- criatura voladora.

Cambiar:
- materiales;
- equipo;
- VFX;
- animaciones secundarias.

---

# 8. ECONOMÍA — COMERCIO Y RECURSOS

## 8.1 Moneda

Nombre:
**Marco / Marcos**

Moneda común heredada del Imperio.

No usar cuatro divisas completas.

---

## 8.2 Categorías

1. alimentos;
2. hierbas/medicina;
3. metales;
4. armas/armaduras;
5. componentes mágicos;
6. lujo;
7. componentes de monstruos;
8. contrabando/Vitae/reliquias.

---

## 8.3 Mercancías principales

12:
- Grano.
- Carne seca.
- Vino.
- Hierro.
- Carbón.
- Madera tratada.
- Hierbas medicinales.
- Sales de Argen.
- Vidrio vesperiano.
- Especias extranjeras.
- Tejidos finos.
- Componentes MOR.

---

## 8.4 Precios regionales base

| Producto | Aureval | Vesperia | Serath | Keldran |
|---|---:|---:|---:|---:|
| Grano | 0.70 | 1.25 | 1.10 | 1.40 |
| Carne | 0.80 | 1.15 | 1.10 | 0.90 |
| Vino | 0.75 | 1.05 | 0.80 | 1.30 |
| Hierro | 1.20 | 1.00 | 1.25 | 0.65 |
| Carbón | 1.15 | 1.00 | 1.20 | 0.70 |
| Madera | 0.90 | 1.10 | 1.20 | 0.75 |
| Hierbas | 1.10 | 1.15 | 0.65 | 1.20 |
| Sales Argen | 1.20 | 1.10 | 0.60 | 1.25 |
| Vidrio | 1.20 | 0.65 | 1.05 | 1.30 |
| Especias | 1.40 | 0.70 | 1.20 | 1.50 |
| Tejidos | 1.15 | 0.75 | 1.05 | 1.30 |
| Componentes MOR | 1.20 | 1.50 | 0.90 | 0.70 |

---

## 8.5 Fórmula

```text
PRECIO_FINAL =
PRECIO_BASE
× MOD_REGION
× MOD_ESTADO_MUNDO
× MOD_OFERTA_LOCAL
× MOD_REPUTACION
× MOD_COMERCIANTE
```

Data-driven.

---

## 8.6 Estados económicos

```text
ECON_NORMAL
ECON_TENSION
ECON_SHORTAGE
ECON_WAR
ECON_COLLAPSE
```

Ejemplo:
- caída de Karhold aumenta hierro global;
- requisiciones de Aureval elevan cereal en Vesperia/Keldran.

---

## 8.7 Tiendas

Perfil:
```text
SHOP_PROFILE
SHOP_TIER
REGION
WORLD_STATE
FACTION
```

Restock:
- descanso importante;
- capítulo;
- viaje relevante.

La escasez puede eliminar stock.

---

## 8.8 Mercado negro

Acceso:
- reputación;
- Sable;
- Sin Firma;
- Calle Sin Nombre;
- quests.

Productos:
- Vitae;
- grimorios;
- venenos;
- reliquias;
- materiales prohibidos.

Puede generar:
`FLAG_OWNED_FORBIDDEN_ITEM`.

---

## 8.9 Contrabando

Checks mediante:
- reputación;
- rutas;
- compañeros;
- quest;
- soborno.

No minijuego de aduana complejo.

---

## 8.10 Inversiones

Máximo:
**3 negocios activos**.

Tipos:
- taberna;
- herrería;
- almacén;
- botica;
- caravana;
- barco mercante.

Nivel:
`1..3`

Ingresos al:
- viajar;
- descansar;
- avanzar capítulos.

No idle-income infinito.

---

## 8.11 Propiedades

Funciones:
- descanso;
- almacenamiento;
- party;
- crafting.

Decoración:
- simple.

---

# 9. REPUTACIÓN / FACCIONES — REACTIVIDAD

## 9.1 Cuatro capas

- Fame.
- Reputation.
- Affinity.
- History Flags.

---

## 9.2 Fame

`0–100`

| Fama | Estado |
|---|---|
| 0–9 | desconocido |
| 10–24 | conocido localmente |
| 25–44 | aventurero reconocido |
| 45–64 | figura regional |
| 65–84 | figura continental |
| 85–100 | leyenda |

Afecta:
- reconocimiento;
- acceso;
- rumores;
- intimidación;
- anonimato.

---

## 9.3 Reputation

`-100 → +100`

| Valor | Estado |
|---:|---|
| -100 a -61 | Enemigo |
| -60 a -31 | Hostil |
| -30 a -11 | Desconfiado |
| -10 a +10 | Neutral |
| +11 a +30 | Aceptado |
| +31 a +60 | Respetado |
| +61 a +80 | Honrado |
| +81 a +100 | Aliado |

Afecta:
- precios;
- quests;
- maestros;
- rangos;
- zonas;
- refuerzos;
- finales.

---

## 9.4 Affinity

Sólo NPC importantes/compañeros.

`-100 → +100`

---

## 9.5 History Flags

Representan la verdad real de lo ocurrido.

Ejemplos:
```text
FLAG_SAVED_EIRIK
FLAG_STOLE_AUREVAL_KEY
FLAG_EXPOSED_AUREA
FLAG_VITAE_DESTROYED
FLAG_HELPED_PORTADORES
```

Permiten que:
- alguien te ame;
- sin conocer una acción secreta.

---

## 9.6 Visibilidad

```text
PUBLIC
WITNESSED
SECRET
UNKNOWN
```

La reputación cambia cuando corresponde, no siempre en el momento.

---

## 9.7 Relaciones entre facciones

```text
ALLY
FRIENDLY
NEUTRAL
RIVAL
ENEMY
```

Una acción propaga sólo una fracción del impacto.

---

## 9.8 Facciones principales

### Aureval
- Corona de Valcera;
- Rosenvault;
- Hermandad del Surco;
- Liga de Graneros;
- Círculo Blanco;
- Corona Dorada.

### Vesperia
- Consejo de Gremios;
- Velloren;
- Serrat;
- Hermanos de la Marea;
- Sin Firma;
- Consorcio del Umbral;
- Horizonte.

### Serath
- Corona de Eiren;
- Alto Sínodo;
- Orden de la Lámpara;
- Hermanos del Alivio;
- Desvelados;
- Custodios del Velo.

### Keldran
- Harken;
- Consejo de Clanes;
- Varkas;
- Vigilia;
- Portadores;
- Sin Clan;
- Hermanos del Yunque.

### Cyrion
- Custodia de las Cenizas;
- Quinta Concordia;
- delegaciones;
- buscarruinas.

---

## 9.9 Rangos

No todas las facciones.

Ejemplo Vigilia:
1. Aspirante.
2. Cazador.
3. Veterano.
4. Maestro.

Rango ≠ reputación.

---

## 9.10 HEAT

Crimen regional:
`0–5`

- 0 normal.
- 1 sospecha.
- 2 controles.
- 3 guardias hostiles.
- 4 cazarrecompensas.
- 5 enemigo regional.

Reducir por:
- multa;
- soborno;
- favores;
- quests;
- tiempo narrativo;
- cambio político.

---

# 10. CORRUPCIÓN — SISTEMA CENTRAL

## 10.1 Tres variables separadas

1. Corrupción.
2. Infección MOR.
3. Saturación Vitae.

---

## 10.2 Corrupción

`0–100`

Persistente.

Fuentes:
- magia oscura;
- artefactos;
- Resonancia;
- Vitae;
- pactos;
- decisiones;
- NEXUS.

---

## 10.3 Tiers

### 0–19 — Latente
Normal.

### 20–39 — Susurros
- anomalías;
- sueños;
- magia oscura inicial.

### 40–59 — Resonante
- Ecos más claros;
- resistencia parcial;
- interacción con artefactos;
- cambios sutiles.

### 60–79 — Integrado
- gran compatibilidad;
- comunicación con Conscientes;
- rutas nuevas;
- reacciones sociales.

### 80–94 — Alterado
- poderes fuertes;
- acceso profundo;
- cambios visibles.

### 95–100 — Umbral
Posibilidad de:
- Ascensión;
- Ruptura.

No transformación automática.

---

## 10.4 MOR

Separado de Corrupción.

```text
MOR_STAGE = 0..5
MOR_STABILITY = 0..100
```

Etapas:
- 0 no infectado;
- 1 Latencia;
- 2 Alteración;
- 3 Divergencia;
- 4 Resonancia;
- 5 resolución.

Resolución:
```text
INTEGRATION
RUPTURE
ASCENSION
```

---

## 10.5 MOR Stability

Aumenta con:
- VOL;
- LUX;
- tratamientos;
- apoyo;
- control de Resonancia.

Disminuye con:
- Saturación Vitae;
- heridas;
- exposición;
- decisiones.

---

## 10.6 Saturación Vitae

`0–100`

- 0–24 estable;
- 25–49 baja;
- 50–74 alta;
- 75–99 crítica;
- 100 Crisis Vitae.

Crisis puede:
- dañar;
- debuff;
- pérdida de control;
- subir corrupción;
- avanzar MOR.

---

## 10.7 Reducir Corrupción

Métodos:
- Rito de Claridad;
- sanadores;
- reliquias;
- abstinencia;
- quests;
- tratamientos.

Más difícil a tiers altos.

Corrupción alta no debe ser sólo castigo:
- habilidades;
- rutas;
- lore;
- acceso;
- Edran;
- demonios.

---

## 10.8 Visual

Retrato y sprite:
- cambios sutiles;
- overlays;
- ojos;
- venas;
- VFX.

MOR fuerte sí puede requerir sprite alternativo.

---

## 10.9 Corrupción y facciones

Cada facción tiene:
`CORRUPTION_TOLERANCE`.

Ejemplos:
- Serath ortodoxo: baja.
- Umbral: alta.
- Portadores: alta.
- Vigilia: depende de conducta.

---

## 10.10 Poderes de Resonancia

Un slot adicional:

**1 slot de Resonancia**

Ejemplos:
- Percibir;
- Llamada;
- Regeneración;
- Paso Resonante;
- Dominio Parcial.

---

## 10.11 Ascensión

Requiere:
- corrupción alta;
- trigger;
- elección.

No por llegar a 100 automáticamente.

---

# 11. LOOT / CRAFTING — PROGRESIÓN MATERIAL

## 11.1 Filosofía

Loot principalmente manual/diseñado.

No Diablo.

No lluvia constante de armas con diferencias mínimas.

---

## 11.2 Rarezas

- Común.
- Raro.
- Épico.
- Legendario.

Rareza ≠ nivel.

---

## 11.3 Slots de equipo

1. arma principal;
2. mano secundaria;
3. cabeza;
4. torso;
5. manos;
6. botas;
7. amuleto;
8. anillo.

Armadura:
- ligera;
- media;
- pesada.

---

## 11.4 Inventario

Baseline:
- 40 stacks;
- ampliable a 60.

No ocupan inventario principal:
- quest items;
- documentos;
- dinero;
- materiales clave.

Almacén:
- Ceniza;
- casas;
- posadas.

---

## 11.5 Durabilidad

Estados:
- Bien 100–51%.
- Gastado 50–21%.
- Dañado 20–1%.
- Roto 0%.

Roto:
- no desaparece;
- pierde bonificaciones.

Desgaste principal:
- KO;
- ataques concretos;
- eventos;
- zonas.

No cada golpe.

---

## 11.6 Mejora

`+0 → +10`

Nunca:
- falla;
- destruye;
- baja nivel.

Tiers:
- +1 a +3 materiales comunes;
- +4 a +6 refinados;
- +7 a +9 raros;
- +10 componente especial.

Milestones:
- +4;
- +7;
- +10.

---

## 11.7 Runas

Máximo:
**2 sockets**.

Familias:
- elementales;
- físicas;
- vitales;
- arcanas;
- resonantes.

No sistema de gemas separado.
Una gema puede ser visualmente una runa/cristal, pero técnicamente:
`SocketModifier`.

---

## 11.8 Crafting

Cuatro categorías:
1. Herrería.
2. Alquimia.
3. Inscripción.
4. Cocina.

### Herrería
- reparar;
- mejorar;
- fabricar selectivamente;
- sockets.

### Alquimia
- pociones;
- antídotos;
- buffs;
- tratamientos;
- Vitae.

### Inscripción
- runas;
- pergaminos;
- componentes mágicos.

### Cocina
12–16 recetas.
Buff hasta siguiente descanso/evento relevante.

---

## 11.9 Materiales

### Comunes
- hierro;
- madera;
- cuero;
- tela.

### Refinados
- acero;
- cuero tratado;
- cristal.

### Mágicos
- esencia elemental;
- polvo arcano.

### MOR
- tejido;
- núcleo;
- sangre estabilizada.

### Únicos
- bosses;
- artefactos.

---

## 11.10 Drops

Enemigos comunes:
- materiales;
- consumibles;
- dinero.

Humanoides:
- equipo ocasional.

Boss:
- 1 drop distintivo.

Resolver sin matar:
- recompensa alternativa equivalente.

---

## 11.11 Legendarios

Objetivo:
**20–30**.

Cada uno:
- nombre;
- historia;
- efecto único;
- adquisición definida.

---

## 11.12 Salvage

Equipo no usado:
- vender → dinero;
- desmontar → materiales.

---

## 11.13 Progresión por actos

### Tier I
Liria/Ceniza:
- equipo simple.

### Tier II
primeros reinos:
- raro;
- +4.

### Tier III
crisis:
- épico;
- +7.

### Tier IV
Cyrion:
- legendario;
- imperial;
- +10.

---

# 12. UI/UX MÓVIL

## 12.1 Plataforma

- Android.
- Landscape.
- Teléfonos/tablets.
- Gamepad opcional.

Prioridades:
- legibilidad;
- pocos controles;
- información contextual;
- safe area;
- accesibilidad;
- no depender del color.

---

## 12.2 Resolución lógica

Baseline:
**640 × 360**

Configuración propuesta:
```text
Base Resolution: 640 × 360
Stretch Mode: viewport
Stretch Aspect: expand
Stretch Scale Mode: integer
Orientation: landscape
```

Objetivo:
- pixel art nítido;
- aprovechar teléfonos anchos;
- no deformar.

---

## 12.3 Safe Area

Usar:
```text
DisplayServer.get_display_safe_area()
DisplayServer.get_display_cutouts()
```

Root UI:
`SafeAreaContainer`.

---

## 12.4 HUD exploración

Izquierda:
- joystick;
- party compacta.

Centro superior:
- objetivo activo breve.

Derecha:
- ataque;
- dodge;
- skills;
- ultimate/clase;
- botón contextual.

---

## 12.5 Botón contextual

Sólo aparece cuando aplica:
- HABLAR;
- ABRIR;
- RECOGER;
- LEER;
- INVESTIGAR.

---

## 12.6 Menú

Pestañas:
- Personaje.
- Equipo.
- Habilidades.
- Inventario.
- Grupo.
- Mapa.
- Diario.
- Facciones.
- Corrupción.
- Configuración.

Algunas se desbloquean narrativamente.

---

## 12.7 Inventario

Tres columnas:
- categoría;
- lista;
- detalle.

Funciones:
- filtros;
- ordenar;
- favoritos;
- comparar;
- desmontaje múltiple.

---

## 12.8 Habilidades

Árbol compacto.

Loadout:
```text
[1] [2] [3] [4] [CLASS] [ULT]
```

No drag&drop obligatorio.

---

## 12.9 Party

```text
ACTIVOS
[P] [C1] [C2]

RESERVA
[C3] [C4]...
```

IA:
- agresivo;
- equilibrado;
- defensivo;
con reglas simples.

---

## 12.10 Diario

Pestañas:
- principal;
- secundarias;
- contratos.

Muestra:
- resumen;
- objetivo;
- región;
- pistas.

No siempre waypoint exacto.

---

## 12.11 Mapas

Dos niveles:
- mundial;
- local.

Iconos:
- quest;
- tienda;
- herrero;
- posada;
- fast travel;
- peligro;
- descubrimiento.

---

## 12.12 Reputación

Mostrar niveles humanos:
- Hostil;
- Neutral;
- Respetado;
- etc.

Valor exacto opcional en modo avanzado.

---

## 12.13 Corrupción UI

Nunca “maldad”.

Pantalla separa:
- Corrupción;
- MOR;
- Saturación Vitae.

Muestra beneficios y costes.

---

## 12.14 Tiendas y crafting

Mostrar transparentemente:
- precio base;
- reputación;
- escasez;
- total.

Crafting:
- materiales disponibles;
- coste;
- resultado.

Sin fallo aleatorio.

---

## 12.15 Combate táctico UI

Timeline superior.

Grid central.

Barra inferior:
- mover;
- atacar;
- skills;
- item;
- esperar.

Preview:
- daño;
- crítico;
- debilidad;
- área.

Velocidad:
- ×1;
- ×2;
- ×3.

---

## 12.16 Accesibilidad

- tamaño de texto;
- escala UI;
- vibración;
- screen shake;
- flashes reducidos;
- velocidad de texto;
- autoavance;
- QTE desactivable;
- números de daño ON/OFF;
- modo zurdo;
- joystick fijo/flotante;
- transparencia de controles;
- asistencia de objetivo;
- dificultad.

---

## 12.17 Guardado UX

- 3 slots manuales;
- autosave;
- backup.

Autosave:
- región;
- boss;
- decisión crítica;
- descanso;
- quest.

---

# 13. ARQUITECTURA TÉCNICA

## 13.1 Stack base

- **Godot 4.7.2 Standard**
- **GDScript**
- renderer **Compatibility**
- Android landscape
- 2D isométrico.

No C# como baseline.

---

## 13.2 Representación gráfica

Componentes:
- `TileMapLayer`;
- `Sprite2D`;
- `AnimatedSprite2D`;
- `CharacterBody2D`;
- `Area2D`;
- `CollisionShape2D`;
- `PointLight2D`;
- `CanvasModulate`.

Tiles:
**64 × 32**

Personajes:
aprox. **32×48 / 48×64**.

Animaciones:
- 8 direcciones;
- 4–8 frames.

---

## 13.3 Capas de mapa

```text
Ground
GroundDetails
Walls
PropsBelow
Actors
PropsAbove
Effects
Collision
Navigation
```

Y-sort para profundidad.

Sombras dinámicas:
- sólo luces importantes.

---

## 13.4 Android baseline

```text
minSdk: API 28 / Android 9
targetSdk: API 36 / Android 16
Orientation: landscape
Architecture QA: arm64-v8a
```

Builds:
- APK para testing/sideload;
- AAB para Google Play.

Toolchain:
- OpenJDK 17;
- Android SDK;
- Godot export templates;
- adb.

---

## 13.5 Carpetas

```text
rpg/
├── project.godot
├── docs/
├── autoload/
├── core/
├── data/
├── actors/
├── exploration/
├── combat/
├── quests/
├── factions/
├── economy/
├── corruption/
├── inventory/
├── crafting/
├── dialogue/
├── saves/
├── ui/
├── maps/
├── art/
├── audio/
├── shaders/
├── tests/
└── tools/
```

---

## 13.6 Autoloads

Pocos:
- `GameState`
- `SaveService`
- `SceneRouter`
- `EventBus`
- `SettingsService`
- `AudioManager`

---

## 13.7 Data-driven

Definiciones:
```text
ActorDefinition
AbilityDefinition
ItemDefinition
EnemyDefinition
QuestDefinition
FactionDefinition
RegionDefinition
EncounterDefinition
RecipeDefinition
SpecializationDefinition
```

Preferencia:
- `.tres` tipados para datos internos;
- JSON validado para diálogos/narrativa cuando convenga.

---

## 13.8 IDs estables

Ejemplos:
```text
MQ00_01
SQ_AUR_03
ITEM_SWORD_001
ABILITY_WARRIOR_HEAVY_STRIKE
NPC_IRIA
FACTION_SURCO
REGION_LIRIA
```

Saves almacenan IDs, no referencias a nodos.

---

## 13.9 GameState

```text
GameState
├── PlayerState
├── PartyState
├── WorldState
├── QuestState
├── FactionState
├── EconomyState
├── CorruptionState
└── InventoryState
```

---

## 13.10 Conditions

```text
HasFlag
NotFlag
ReputationAtLeast
AffinityAtLeast
HasItem
QuestCompleted
WorldStateAtLeast
CorruptionAtLeast
MorStageEquals
ClassEquals
CompanionPresent
```

---

## 13.11 Effects

```text
SetFlag
AddReputation
AddAffinity
GiveItem
RemoveItem
SetWorldState
StartQuest
CompleteQuest
AddCorruption
AddMoney
UnlockRegion
```

---

## 13.12 Quest Engine

```text
QuestDefinition
├── id
├── title
├── description
├── prerequisites
├── stages[]
└── completion_effects[]
```

Stage:
```text
QuestStage
├── objectives[]
├── conditions
├── optional_objectives[]
└── effects[]
```

---

## 13.13 Dialogue Engine

```text
DialogueNode
├── speaker
├── text
├── conditions
├── choices[]
└── effects
```

Choice:
```text
Choice
├── text
├── conditions
├── effects
└── next_node
```

---

## 13.14 Actor architecture

Separar:
- Definition;
- Runtime.

Combat shared core:
```text
CombatActor
Stats
Equipment
Ability
StatusEffect
DamageResolver
ElementResolver
ResourcePool
```

Exploración:
`ExplorationActor → CombatActorRuntime`

Táctico:
`TacticalUnit → CombatActorRuntime`

---

## 13.15 AbilityResolver

Una skill define:
```text
cost
target_type
range
area
damage_formula
element
status_effects
movement
ct_cost
```

Evitar un script por skill.

---

## 13.16 IA

```text
AIController
├── evaluate_targets()
├── evaluate_actions()
├── score_action()
└── execute_best_action()
```

Perfiles:
- aggressive;
- balanced;
- defensive;
- ranged;
- healer;
- boss.

Bosses:
- state machine por fases.

---

## 13.17 Save

JSON versionado:

```json
{
  "save_version": 1,
  "game_version": "0.1.0",
  "player": {},
  "party": {},
  "world": {},
  "quests": {},
  "factions": {},
  "inventory": {}
}
```

Archivos:
```text
slot_01.save
slot_02.save
slot_03.save
autosave.save
autosave.backup
```

Proceso seguro:
1. serializar;
2. temporal;
3. validar;
4. reemplazar;
5. backup.

Migraciones por `save_version`.

---

## 13.18 Offline y seguridad

Versión inicial:
- sin backend;
- sin cuenta;
- sin login;
- sin telemetría obligatoria.

No almacenar:
- API keys;
- secretos;
- credenciales.

Keystore:
- fuera del repo.

---

## 13.19 Git y documentos persistentes

Repo desde primer día.

Ramas:
```text
main
develop
feature/*
fix/*
```

Documentos:
```text
AGENTS.md
PROJECT_STATE.md
TECH_SPEC.md
VERTICAL_SLICE.md
docs/canon/
```

---

## 13.20 Dependencias

Baseline:
**0 plugins obligatorios**.

No instalar frameworks/addons sin justificar.

---

## 13.21 ContentValidator

Debe detectar:
- IDs duplicados;
- referencias inexistentes;
- quests rotas;
- items inexistentes;
- skills inexistentes;
- factions inexistentes;
- diálogos rotos.

Crítico para contenido generado con IA.

---

## 13.22 Performance

Objetivo:
**60 FPS**

Fallback:
**30 FPS**

QA baseline:
- Android 9+;
- 4 GB RAM;
- ARM64.

Objetivos internos del slice:
```text
RAM pico < 500 MB
escena habitual < 300 MB
APK release < 150 MB
frame 60 FPS < 16.6 ms
frame 30 FPS < 33.3 ms
```

---

## 13.23 Loading

No mantener mapas completos simultáneamente.

Flujo:
1. transición;
2. liberar escena;
3. background load;
4. instanciar;
5. aplicar WorldState;
6. spawn;
7. fade in.

---

## 13.24 Audio

Buses:
```text
Master
Music
SFX
Ambient
UI
Voice
```

---

## 13.25 Testing

### Unitario
- daño;
- precios;
- conditions;
- reputación;
- corrupción;
- save.

### Integración
- quest → flag → mundo;
- combate → loot;
- decisión → reputación;
- save/load.

### E2E
- vertical slice completo.

Headless baseline:
```text
godot --headless --path . --script res://tests/run_tests.gd
```

---

# 14. VERTICAL SLICE

## 14.1 Objetivo

No demo visual aislada.

Debe validar realmente:
- controles;
- pixel art;
- ARPG;
- táctico;
- diálogo;
- quest;
- inventario;
- equipo;
- economía;
- reputación;
- corrupción;
- loot;
- crafting;
- party;
- save;
- WorldState;
- Android.

---

## 14.2 Alcance narrativo

**Liria → ataque → consecuencias → Camino Prohibido → primera llegada a Ceniza → pequeña expedición al Anillo de las Ruinas.**

No:
- Aureval completo;
- Vesperia;
- Serath;
- Keldran;
- Edran revelado;
- Quinta Puerta final.

Duración:
- primera partida 35–50 min;
- replay 20–30 min.

---

## 14.3 Mapas

- Liria día.
- Liria ataque.
- Liria aftermath.
- Camino Prohibido.
- Entrada de Ceniza.
- Ruina Cyrion 01.
- Arena táctica Radan.

Puede inicialmente usarse escenas separadas y después consolidar estados.

---

## 14.4 NPC Liria

Mínimos:
- protagonista;
- Iria;
- Halven;
- familiar/amigo;
- comerciante;
- herrero;
- 5–8 ambientales.

---

## 14.5 Quests slice

### MQ00_01 — Un día cualquiera
Valida:
- movimiento;
- diálogo;
- interacción;
- inventario;
- quest.

### MQ00_02 — La última noche de Liria
Valida:
- ARPG;
- enemigos;
- decisiones;
- triggers;
- WorldState.

Decisiones:
```text
DEFENDER_PLAZA
SAVE_FAMILY
PURSUE_ATTACKERS
```

### MQ00_03 — El estuche de Halven
Valida:
- Collar;
- flag;
- escena;
- reacción de Cyrion.

### SQ_CYR_02 — Nadie reclama a los muertos
Valida:
- secundaria;
- reputación;
- recompensa alternativa.

---

## 14.6 Enemigos slice

- Mercenario melee.
- Arquero mercenario.
- Febril MOR.
- Radan Korr.
- Centinela imperial.

---

## 14.7 ARPG slice

Debe incluir:
- ataque;
- dodge;
- 2 skills iniciales;
- consumible;
- IA compañera.

No hace falta 4 skills completas aún.

---

## 14.8 Boss Radan Korr

Grid:
**8 × 6**

### Fase 1
Mercenario:
- espada;
- carga;
- guardia.

### Fase 2
Corrupción parcial:
- ataque Resonante;
- movilidad;
- Barra de Ruptura.

Enseña:
- timeline;
- movimiento;
- skills;
- stagger;
- debilidad.

---

## 14.9 WorldState

La misma Liria debe cambiar por:
```text
WORLD_LIRIA = ATTACKED
```

Cambios:
- tiles;
- props;
- NPC;
- música;
- diálogos.

---

## 14.10 Economía/crafting del slice

Comerciante/herrero.

Después del ataque:
- stock;
- precios.

Loot mínimo:
- 3 armas;
- 2 armaduras;
- 3 consumibles;
- 4 materiales;
- 1 raro;
- 1 runa.

Crafting:
- reparar;
- +1/+2;
- colocar runa;
- una poción.

---

## 14.11 Reputación del slice

Sólo:
```text
REP_LIRIA
REP_CUSTODIA
REP_QUINTA_CONCORDIA_HIDDEN
```

Afinidad:
- Iria.

---

## 14.12 Primer evento de corrupción

Dispositivo imperial.

Opciones:
- retirarse;
- mantener contacto.

Mantener:
```text
CORRUPTION +10
```

Desbloquea:
- símbolo oculto.

Demuestra:
**poder con coste**.

---

## 14.13 Ceniza slice

Sólo:
**Distrito de Entrada**

NPC:
- guardia Custodia;
- Mael Varos;
- comerciante;
- posadero;
- buscarruinas;
- 6–10 ambientales.

Varos:
- investigador amable;
- no revelar Quinta Concordia.

---

## 14.14 Ruina Cyrion 01

4–6 salas.

Incluye:
- Centinela;
- puzzle;
- loot;
- puerta de cinco espacios.

Final:
- Collar reacciona;
- una luz distante responde;
- título.

---

## 14.15 Sistemas reales, no mocks

Deben ser el mismo núcleo que escalará al juego:
- movimiento;
- combate;
- quest;
- diálogo;
- inventory;
- save;
- reputación;
- corrupción;
- loot.

Pueden tener contenido mínimo, pero arquitectura real.

---

## 14.16 Sistemas diferibles

Todavía simulables/no implementados:
- negocios;
- grandes facciones;
- Ascensión;
- Nuevo Mundo;
- mapa continental completo;
- política global.

---

## 14.17 Orden de implementación

1. `VS-01` Project Foundation.
2. `VS-02` Player Controller.
3. `VS-03` Interaction.
4. `VS-04` Dialogue.
5. `VS-05` GameState + Save.
6. `VS-06` Quest Engine.
7. `VS-07` Inventory / Items.
8. `VS-08` ARPG Combat.
9. `VS-09` Tactical Core.
10. `VS-10` Radan.
11. `VS-11` WorldState.
12. `VS-12` Reputation / Affinity.
13. `VS-13` Economy / Crafting.
14. `VS-14` Corruption.
15. `VS-15` Ceniza / Cyrion.
16. `VS-16` Android Polish.

---

## 14.18 Criterios funcionales

### Inicio
- nueva partida;
- nombre;
- clase;
- tutorial.

### Exploración
- joystick;
- cámara;
- colisiones;
- interacción.

### ARPG
- IA;
- daño;
- dodge;
- skills;
- loot.

### Táctico
- transición;
- grid;
- timeline;
- Radan completado.

### Narrativa
- decisiones → flags;
- Iria reacciona;
- Liria cambia.

### Sistemas
- inventory;
- shop;
- crafting;
- reputación;
- corrupción.

### Persistencia
- guardar;
- cerrar;
- abrir;
- continuar.

### Android
- APK instala;
- abre offline;
- landscape;
- sin cuenta.

---

## 14.19 Criterios técnicos

```text
0 errores bloqueantes
0 IDs duplicados
0 referencias rotas
0 saves corruptos en suite normal
```

Performance:
- 60 FPS objetivo;
- 30 FPS fallback.

---

## 14.20 Pruebas mínimas

Automáticas:
- DamageResolver;
- QuestCondition;
- Economy;
- Corruption;
- Save;
- IDs.

Manual Android:
- instalación limpia;
- abrir/cerrar;
- background;
- bloqueo;
- notificación/llamada;
- save/load;
- ARPG;
- táctico;
- 30/60 FPS;
- 16:9 / 20:9;
- notch;
- modo zurdo.

---

## 14.21 Prohibiciones del slice

No:
- implementar reinos completos;
- 40 enemigos;
- todas las especializaciones;
- multiplayer;
- backend;
- login;
- ads;
- procedural generation;
- Nuevo Mundo;
- todas las quests;
- addons no justificados;
- optimización prematura.

---

## 14.22 Gate de salida

No avanzar a producción completa hasta responder sí a:

1. ¿Moverse se siente bien?
2. ¿ARPG y táctico se sienten como el mismo juego?
3. ¿La UI funciona realmente en teléfono?
4. ¿Liria → ataque → Cyrion genera interés?

Si falla alguno:
- corregir antes de producir los cuatro reinos.

---

# 15. RESUMEN CUANTITATIVO DE PREPRODUCCIÓN

| Área | Baseline |
|---|---:|
| Compañeros permanentes | 8 |
| Party activa | 3 |
| Macrozonas | 34–38 |
| Hubs/capitales | 5 |
| Main quests | ~38 |
| Secundarias escritas | ~38 |
| Clases base | 5 |
| Especializaciones estándar | ~20 |
| Nivel máximo | 30 |
| Familias visuales de enemigos | ~40 |
| Bosses/elites | 15–20 |
| Mercancías comerciales | 12 |
| Negocios activos | máx. 3 |
| Corrupción | 0–100 |
| Inventario | 40→60 stacks |
| Mejora equipo | +0→+10 |
| Legendarios | 20–30 |
| Party skills visibles | 4 + clase + ult |
| Grid táctico | 8×6 baseline |
| Vertical slice | 35–50 min |

---

# 16. ARQUITECTURA GLOBAL RESULTANTE

```text
CANON / LORE
      ↓
WORLD STATES
      ↓
QUESTS
      ↓
CONDITIONS / EFFECTS
      ↓
GAME STATE
 ├── PARTY
 ├── FACTIONS
 ├── ECONOMY
 ├── CORRUPTION
 └── INVENTORY
      ↓
SHARED COMBAT MODEL
 ├── ARPG
 └── TACTICAL
      ↓
UI / SAVE / ANDROID
```

---

# 17. DECISIONES BASE PARA PRODUCCIÓN

| Decisión | Base |
|---|---|
| Motor | Godot 4.7.2 |
| Lenguaje | GDScript |
| Plataforma | Android |
| Orientación | Landscape |
| Renderer | Compatibility |
| Representación | 2D isométrico |
| Resolución lógica | 640×360 |
| Tile | 64×32 |
| Party | 3 |
| Combate | ARPG + CT táctico |
| Grid | 8×6 |
| Arquitectura | data-driven |
| Save | JSON versionado |
| Backend | ninguno |
| Online | no |
| Ads | no |
| Cuenta | no |
| APK | QA / sideload |
| AAB | publicación |
| target Android | API 36 |
| Vertical slice | Liria → Ceniza/Cyrion |

---

# 18. QUÉ YA ESTÁ CERRADO

Con los puntos 1–14 existe definición suficiente de:

- elenco;
- party;
- mapa;
- volumen;
- historia implementable;
- secundarias;
- builds;
- combate;
- enemigos;
- economía;
- facciones;
- reactividad;
- corrupción;
- loot;
- crafting;
- UI;
- controles;
- arquitectura;
- saves;
- Android;
- testing;
- vertical slice.

---

# 19. QUÉ DEBE SEGUIR DATA-DRIVEN / ABIERTO A PLAYTEST

No fijar irreversiblemente antes del slice:

- HP exactos;
- daño exacto;
- XP;
- CT exacto;
- economía final;
- drops;
- coste definitivo de mejoras;
- ganancia exacta de reputación;
- velocidad exacta de Corrupción;
- número final de enemigos por mapa;
- duración exacta de cada dungeon.

---

# 20. SIGUIENTE ETAPA FORMAL

La etapa de diseño general se considera completada.

El siguiente trabajo debe denominarse:

# PREPARACIÓN E IMPLEMENTACIÓN DEL VERTICAL SLICE

Primera meta:

> Crear un proyecto Godot limpio que exporte un APK Android, abra Liria y permita mover al protagonista correctamente con controles táctiles.

Después, en orden:
- interacción;
- diálogo;
- GameState/save;
- quests;
- inventario;
- ARPG;
- táctico;
- Radan;
- WorldState;
- reputación;
- economía/crafting;
- corrupción;
- Ceniza/Cyrion;
- Android polish.

No ampliar el mundo antes de superar el gate del vertical slice.
