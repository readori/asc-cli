# App Icon Design — asc

## Concept

The icon visualizes the **Command Center as the nerve of a Terran base** — a
massive, industrial structure that coordinates every operation. `asc` is that
command center for App Store Connect: all builds, versions, users, and
submissions flow through it. Heavy steel construction, orange reactor glow, and
cold blue scanner light — pure Terran military engineering. No device frame,
no lettermark.

**Color palette:**

| Role       | Color              | Hex       |
|------------|--------------------|-----------|
| Background | Deep space black   | `#0A0F18` |
| Structure  | Gunmetal steel     | `#1E2D3D` |
| Reactor    | Terran orange      | `#E87C2A` |
| Scanner    | Cold cyan          | `#4FC3F7` |
| Highlight  | Pale steel white   | `#C8D8E8` |

---

## AI Generation Prompt

### Primary prompt

```
macOS app icon for "asc", a command-line developer tool for App Store Connect.
A stylized Terran Command Center from StarCraft — viewed from a slight isometric
angle, monolithic industrial structure with thick steel plating and riveted panels.
A glowing orange reactor core pulses at the center of the building, casting warm
light across the hull. A rotating blue scanner dish sits on top, emitting a cold
cyan sweep of light. The background is deep space black with a faint star field.
The structure feels massive and authoritative — the headquarters of all operations.
Flat panel surfaces with subtle weathering and mechanical detail lines. The overall
composition fits inside a rounded square (macOS icon format). No text. Cinematic
lighting, matte metal materials, subtle bloom on the reactor and scanner glow.
Color palette: #0A0F18 (deep space), #1E2D3D (gunmetal), #E87C2A (reactor orange),
#4FC3F7 (scanner cyan), #C8D8E8 (steel highlight). Style: polished macOS app icon,
professional, 1024x1024.
```

### Negative prompt

```
no text, no lettermark, no Zerg, no Protoss, no realistic photography,
no cheap gradients, no flat cartoon, no generic building silhouette,
no futuristic sleek design — must feel industrial and heavy
```

---

## Design Rationale

| Element           | Decision                              | Reason                                                                                     |
|-------------------|---------------------------------------|--------------------------------------------------------------------------------------------|
| **Shape**         | Isometric Command Center structure    | Directly references the StarCraft Terran naming — instantly legible to the target audience |
| **Central motif** | Orange reactor core                   | The reactor = the source of all power; asc is the power source for ASC workflows           |
| **Scanner dish**  | Rotating cyan scanner on top          | Signals "monitoring / checking" — mirrors `asc versions check-readiness`                   |
| **Texture**       | Riveted steel panels, weathered hull  | Terran aesthetic: industrial, military, functional — not pretty, just effective             |
| **Color**         | Deep space + gunmetal + reactor glow  | Terran palette; cold-dark with warm energy contrast — distinctive in the Dev Tools category |
| **Format**        | Rounded square, no text               | macOS icon standard, works at all sizes (16px–1024px)                                      |

---

## Product Family Consistency

`asc` belongs to the **StarCraft building naming** family shared across the
developer tool suite:

| App      | SC Race  | Building        | Icon direction                        |
|----------|----------|-----------------|---------------------------------------|
| AppNexus | Protoss  | Nexus           | Crystalline blue/gold, geometric      |
| AppHive  | Zerg     | Hive            | Organic purple/amber, hexagonal       |
| asc      | Terran   | Command Center  | Industrial steel/orange, architectural |

The three icons should feel like opposite corners of the same universe — one
crystalline, one organic, one mechanical. Together they form a coherent product
family rooted in the StarCraft lore.

---

## Sizes Required

Use the `apple-icon-generator` skill to produce all sizes from a 1024×1024 source:

| Platform | Sizes                                    |
|----------|------------------------------------------|
| macOS    | 16, 32, 64, 128, 256, 512, 1024         |
| iOS      | 20, 29, 40, 60, 76, 83.5, 1024          |