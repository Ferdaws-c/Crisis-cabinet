# Crisis Cabinet - IT Risk Management Game

A 2D educational game built in Godot 4.4 that teaches IT project risk management through interactive gameplay. Instead of reading about risk management, players **practice** it - identifying risks, assessing probability and impact, classifying severity, choosing response strategies, and living with the consequences of their decisions.

## Game Overview

The player takes the role of a project manager for **SecurePay** - a mobile banking app with a 4-month deadline and $200K budget. They must manage risks across the entire project lifecycle.

The game is structured in **three layers**, each building on the previous:

### Layer 1 - The Training Wing (Built)
Six interactive teaching stations that introduce risk management concepts one at a time:

| Station | Concept | What the Player Does |
|---------|---------|---------------------|
| 1. What Is a Risk? | Risk identification | Classify statements as project risks or not, see cause->event->effect chains |
| 2. Probability | Likelihood assessment | Place risks on a Low/Medium/High scale, review supporting evidence |
| 3. Impact & Client Priorities | Impact dimensions + stakeholder context | Talk to the client (Dana), build her priority profile, assess multi-dimensional impact |
| 4. Risk Matrix | Severity classification | Place risks on a 2x2 matrix using fire metaphors (Wildfire/Volcano/Campfire/Spark) |
| 5. Response Strategies | PMBOK strategies (Avoid/Mitigate/Transfer/Accept) | Investigate with NPCs, explore all four strategies, see consequences of each |
| 6. Full Cycle | Complete risk assessment | Run through the entire process independently with hints available |

**Key teaching mechanic:** The player experiences consequences first, then the concept is explained - not the other way around.

### Layer 2 - The Project Simulation (Designed, not yet built)
A four-phase simulation (Planning -> Execution -> Monitoring -> Closing) where the player manages SecurePay with real constraints:
- **Risk Register:** A persistent tool the player builds and maintains
- **Resource Allocation:** Limited budget and team capacity force prioritization
- **Probabilistic Outcomes:** Risks trigger based on probability rolls modified by the player's strategy choices
- **Cascading Consequences:** Triggered risks spawn new risks and modify existing ones
- **Project Health Dashboard:** Four dimensions (Budget, Schedule, Quality, Stakeholder Trust) replace the old XP system
- **NPC Conversations:** Investigate risks by talking to team members before deciding

### Layer 3 - The Proving Ground (Designed, not yet built)
Post-launch management during an acquisition, introducing:
- **Conflicting stakeholder priorities** (Dana's priorities shift under acquisition pressure)
- **Ambiguous risks** (NPCs disagree, player must use judgment)
- **Ethical dimensions** (some decisions involve professional responsibility beyond the numbers)
- **Reduced scaffolding** (no hints, shorter debriefs, player operates independently)

## Architecture Overview

The game uses a component-based architecture with three autoload singletons:

- **GameManager** - All game state (health, budget, risk register, progression flags)
- **DataManager** - Loads scenario and dialogue data from JSON files
- **SignalBus** - Central event system for cross-scene communication
- **StyleConstants** - Colors, fonts, and visual constants

### Reusable UI Components
Interactive overlays used across all layers:

| Component | Purpose |
|-----------|---------|
| CauseEventEffectChain | Animated 3-panel explanation (Cause -> Event -> Effect) |
| EvidenceColumns | Two-column evidence comparison for probability assessment |
| RippleEffect | Sequential consequence cascade with dimension impacts |
| RiskMatrix | 2x2 interactive matrix with fire metaphor categories |
| ClientProfileCard | Strategy-game-style stakeholder card with stat bars |
| NPCDialogue | Branching conversation system |
| ResourceAllocationUI | Strategy selection with cost/affordability display |
| PhaseResolution | End-of-phase probability rolls and consequence resolution |

### HUD System
Persistent dashboard with:
- Health Dashboard (4 dimensions with color-coded states)
- Resource Bar (budget + team capacity)
- Risk Register Panel (toggleable side panel)
- Risk Matrix Minimap (toggleable)

## Visual Style

- **Pixel art** aesthetic matching the game's 2D sprite world
- **Dark theme** with teal/cyan accents for UI elements
- **Fire metaphor colors** for risk severity (Red=Wildfire, Orange=Volcano, Yellow=Campfire, Gray=Spark)
- **Semi-transparent overlays** so the game world remains dimly visible behind UI
- Font: Press Start 2P (pixel font)

## Project Structure

```text
Crisis-cabinet/
|- assets/              # Sprites, fonts, audio
|- data/
|  |- scenarios/       # JSON scenario data per layer/phase
|  |- npc_dialogues/   # JSON dialogue trees per NPC
|  |- client_profiles.json
|  `- config.json
|- docs/                # Design documents
|- scenes/
|  |- components/      # Reusable UI components
|  |- hud/             # HUD system
|  |- layer1/          # Training Wing + 6 stations
|  |- layer2/          # (future) Phase rooms
|  |- layer3/          # (future) Phase rooms
|  `- main/            # Main menu, game world
|- scripts/
|  |- autoload/        # Singletons (GameManager, DataManager, SignalBus, StyleConstants)
|  |- components/      # Component scripts
|  |- hud/             # HUD scripts
|  |- layer1/          # Station scripts
|  `- ...
`- themes/              # Godot theme resources
```

## How to Run

1. Install **Godot 4.4** from [godotengine.org](https://godotengine.org/download)
2. Clone this branch: `git clone -b feature/layer1-foundation <repo-url>`
3. Open the project in Godot (Project -> Import -> select `project.godot`)
4. Press **F5** to run (or Play button)
5. The game starts at the Main Menu -> enters the Training Wing

## How to Test

- **Full playthrough:** Start from the main menu, walk through all 6 stations in the Training Wing
- **Individual stations:** Open any `scenes/layer1/StationX_*.tscn` in the editor, press **F6** to run that scene standalone
- **Individual components:** Open any `scenes/components/*.tscn`, press **F6** (note: components need `setup()` data to display content, so they may appear empty in standalone mode)

## Known Issues

See [docs/KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md) for the full list of known issues and planned improvements.

## Design Documents

Full game design documentation is in the `docs/` folder:

- [Layer 1 Design](docs/layer1-design-document.md) - Teaching stations, explanation mechanics, fire metaphor system
- [Layer 2 Design](docs/layer2-design-document.md) - Project simulation, risk register, resource system, cascading consequences
- [Layer 3 Design](docs/layer3-design-document.md) - Ambiguity, conflicting stakeholders, ethical dimensions
- [Architecture & Implementation Plan](docs/master-architecture-implementation-plan.md) - Technical spec, scene architecture, data schemas, task breakdown
