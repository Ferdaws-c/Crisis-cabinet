# Crisis Cabinet Codebase Analysis

Repository: `https://github.com/Ferdaws-c/Crisis-cabinet`  
Analyzed commit: `9bc8598`  
Analysis date: `2026-04-22`

## 1. Project Overview

### Engine / framework

- The project is built with **Godot 4.4**.
- Evidence:
  - `project.godot` sets `config/features=PackedStringArray("4.4", "Forward Plus")`.
  - The main scene is configured via `run/main_scene="uid://bsvcxwa1uov5q"` and resolves to the menu scene.

### Programming languages and data formats

- **GDScript** is the primary programming language.
- **Godot scene files** (`.tscn`) define levels, UI, triggers, and reusable prefabs.
- **JSON** is used for scenario content storage in `gppt_crisis_cabinet_v2.json`.
- Asset/config formats also include `.gdshader`, `.cfg`, `.docx`, `.pdf`, `.html`, and imported texture/font metadata.

### Overall structure

Top-level layout:

- `project.godot`: Godot project configuration, input bindings, autoload registration.
- `autoloads/`
  - `GameManager.gd`: central game state, scoring, progression, scenario loading, high-score persistence.
- `scenes/`
  - `levels/`
    - `MainFacility.tscn`: the main playable map containing player, doors, risk rooms, popups, and triggers.
    - `camera2d.gd`: map camera behavior.
  - `player/`
    - `Player.tscn`, `Player.gd`: movement and animation.
  - `environment/`
    - `RiskRoom.tscn`, `RiskRoom.gd`: reusable room that maps pads to scenario IDs.
    - `TuslerPad.gd`: interactable risk pad.
    - `RoomDoor.gd`: phase-locked doors.
    - `InfoTrigger.gd`, `DifficultyTrigger.gd`, `CeoTrigger.gd`, `SuddenTrigger.gd`: trigger zones.
  - `ui/`
    - `MainMenu.gd`: title screen, difficulty selection, username, scoreboard.
    - `GameHUD.gd`: HUD, minimap, project board, risk log.
    - `ScenarioPopup.gd`: the core quiz/decision UI.
    - `InfoPopup.gd`, `DifficultyPopup.gd`, `PauseMenu.gd`, `AuditScreen.gd`, `CeoPopup.gd`, `PerformanceReview.gd`, `Credits.gd`.
- `assets/`: fonts, character sprites, tilesets, menu art, shaders.
- `Readme/`: supporting course/reference materials and extraction utilities.
- `gppt_crisis_cabinet_v2.json`: the scenario dataset with 12 cases.

### Key runtime files

- `autoloads/GameManager.gd`: all persistent gameplay state.
- `scenes/levels/MainFacility.tscn`: actual world layout and progression gates.
- `scenes/environment/RiskRoom.gd`: room-local scenario dispatch.
- `scenes/ui/ScenarioPopup.gd`: where nearly all meaningful gameplay logic happens.
- `gppt_crisis_cabinet_v2.json`: almost all educational scenario content.

## 2. Game Mechanics Analysis

### Current game flow

The game is a **single-map exploratory quiz game** wrapped in a light office/facility traversal layer.

High-level flow:

1. Player opens `MainMenu.tscn`.
2. Player selects difficulty and optionally enters a username.
3. Pressing Play resets state and loads `scenes/levels/MainFacility.tscn`.
4. In the facility, the player must first read the tutorial from `InfoTrigger` / `InfoPopup`.
5. Doors unlock by phase progression, funneling the player into successive `RiskRoom` instances.
6. In each room, the player steps on scenario pads.
7. Each scenario opens `ScenarioPopup`, which runs a fixed 3-step assessment:
   - classify the risk on the Tusler matrix
   - choose a PMBOK response strategy
   - choose a specific mitigation action
8. Completing enough scenarios advances the global phase from `Planning` to `Executing`, `Monitoring`, `Closing`, then `Finished`.
9. After the final phase, the CEO trigger opens `CeoPopup`, which grades performance.
10. The player is then sent to `PerformanceReview.tscn`, then credits, then back to menu.

### Scene transitions and level progression

There are very few real scene transitions:

- `MainMenu.tscn` -> `MainFacility.tscn`
- `MainFacility.tscn` -> `PerformanceReview.tscn`
- `PerformanceReview.tscn` -> `Credits.tscn`
- `Credits.tscn` -> `MainMenu.tscn`

The actual "level progression" happens inside one persistent map using:

- phase-locked doors in `RoomDoor.gd`
- separate `RiskRoom` instances preloaded with different scenario IDs
- minimap waypoint logic in `GameHUD.gd`

Phase thresholds are controlled by `GameManager.mark_scenario_complete()`:

- Easy: 4 scenarios total
- Medium: 8 scenarios total
- Hard: 12 scenarios total

Phase mapping by completion count:

- early progress -> `Planning`
- 25% complete -> `Executing`
- 50% complete -> `Monitoring`
- 75% complete -> `Closing`
- max complete -> `Finished`

### Interactive elements

Implemented interactions include:

- Main menu buttons:
  - Play
  - difficulty selection
  - scoreboard view / clear
- In-world interactions:
  - `Space` to interact with tutorial, difficulty zone, CEO trigger, pads, locked doors
  - WASD / arrow movement
  - `E` to play a coffee-drink animation
- Scenario popup buttons:
  - classification choices
  - strategy choices
  - mitigation choices
  - continue buttons between stages
- Pause menu buttons:
  - resume
  - restart map
  - main menu
  - quit
  - timer toggle
  - budget adjust cheat buttons
- Endgame buttons:
  - CEO popup continue
  - performance review continue
  - credits exit

### Scoring, feedback, and consequence systems

There is a consequence layer, but it is mostly **quiz scoring with resource deductions**, not a simulated project management system.

Implemented systems:

- **Budget**:
  - starts at difficulty-specific values (`200000`, `150000`, `100000`)
  - scenario entry costs `ASSESSMENT_FEE = 5000`
  - wrong answers and timeouts further reduce budget
  - low budget can lock some strategy options
- **Schedule days**:
  - starts at `120`
  - correct and incorrect answers subtract days
  - lateness affects final evaluation
- **Point score**:
  - increased by correct answers
  - streak multiplier applies after streak >= 3
- **XP score**:
  - awarded after scenario completion
  - used as a rough progression currency, though door logic actually maps XP thresholds to phases, not true XP accumulation rules
- **Streak / best streak**:
  - rewards repeated correct mitigation outcomes
- **Decision log**:
  - stores per-scenario classify/strategy/mitigate correctness
- **Tusler accuracy stats**:
  - tracks correct/total classifications by category
- **Leaderboard persistence**:
  - saved to `user://scoreboard.json`

Feedback systems:

- immediate correct/incorrect labels
- budget/day penalties shown in text
- PMBOK teaching tips shown after answers
- end-of-game grading in `CeoPopup.gd`
- post-game review screen with per-scenario correctness table

### How scenarios are structured and stored

Scenarios are stored in **JSON**, not hardcoded in script.

Each scenario object currently includes:

- `id`
- `title`
- `prob`
- `impact`
- `urgency`
- `lesson_text`
- `setup`
- `objective`
- `winCondition`

However, the scripts still parse these fields in brittle ways:

- correct Tusler category is inferred from the scenario title string containing `Tiger`, `Puppy`, `Alligator`, or `Kitten`
- correct mitigation action is extracted from a quoted substring inside `winCondition`
- correct strategy is inferred by substring-matching against `objective`

So the content is in JSON, but the game logic still depends on fragile text conventions rather than structured data keys like `correct_category`, `correct_strategy`, or `mitigation_options`.

## 3. Current Logic Assessment

### Decision tree / player flow from start to finish

The current player journey is essentially:

1. Menu
   - choose username
   - choose difficulty
   - press Play
2. Facility intro
   - walk to tutorial area
   - press interact
   - page through four tutorial panels
3. Planning room
   - enter room once intro is read
   - activate available pads based on difficulty
   - each pad launches a scenario popup
4. For each scenario
   - optional lesson text page
   - Step 1: classify risk
   - Step 2: choose strategy
   - Step 3: choose mitigation
   - receive feedback
   - scenario completes
5. Enough completions advance phase
   - doors unlock to next room
6. Repeat through `RiskRoom`, `RiskRoom2`, `RiskRoom3`, `RiskRoom4`
7. After final completion, phase becomes `Finished`
8. CEO room becomes reachable
9. CEO popup computes ending grade from budget, days, streak, score, XP
10. Performance review shows results log
11. Credits

### Where the game is "click and read" with low agency

The project is strongly educational, but most gameplay is still **guided quiz delivery** rather than interactive risk management.

Main low-agency areas:

- The world map is mostly a **spatial wrapper** around popup quizzes.
- Room progression is linear and phase-gated.
- Scenario order is largely predetermined by room assignment.
- The player never builds a strategy over time; they answer isolated prompts.
- No answer creates a persistent world-state change except number adjustments and unlocking later rooms.
- The "mitigation" choice never changes future scenarios, only score/budget/days.
- No scenario outcome creates new downstream scenarios, dependencies, or altered room conditions.
- The tutorial is mandatory paging with no interactivity.
- Final evaluation is based on aggregate counters, not on a causally linked project history.

### Branching paths, randomness, or dynamic systems

There is only **very light dynamism**:

- `RiskRoom.gd` shuffles which pads remain active by difficulty.
- mitigation option order is randomized with `options.shuffle()`.
- some strategy choices become disabled when budget is low.
- minimap target changes with phase.

What is not present:

- no scenario branching tree
- no alternate scenario outcomes that spawn future events
- no random event generation
- no probability rolls
- no simulation of project state dependencies
- no adaptive scenario sequencing based on past decisions
- no persistent risk register that changes future choices
- no resource tradeoff model beyond subtracting budget/days

### Meaningful player agency assessment

Agency is currently limited to:

- choosing the answer Godot expects
- choosing difficulty
- deciding when to walk to the next trigger
- optionally toggling the timer or cheating budget in pause menu

The game does not yet support:

- multiple valid strategies with tradeoffs
- partial success outcomes
- strategic planning across the whole project
- choosing between competing risks under scarce resources
- committing to a risk response plan and living with downstream consequences

In practice, the game is best described as:

> a linear Godot-based serious-game quiz with spatial navigation, light resource penalties, and a PMBOK/Tusler teaching wrapper.

## 4. Architecture & Extensibility

### Modularity assessment

Strengths:

- Scenario content is externalized to JSON.
- `GameManager.gd` centralizes global state.
- `RiskRoom.tscn` is reusable and parameterized by scenario IDs.
- UI concerns are separated into multiple scene/scripts.
- Main facility scene composes reusable sub-scenes rather than embedding everything directly.

Weaknesses:

- `GameManager.gd` is becoming a catch-all state bag.
- `ScenarioPopup.gd` contains most actual gameplay logic and tightly couples:
  - UI rendering
  - answer validation
  - timer logic
  - penalties
  - tutorial delivery
  - PMBOK tip display
  - decision logging
- Important rules are encoded through string parsing instead of typed data.
- Phase progression, door unlocking, and XP are conceptually mixed.
- Several systems exist only as placeholders or dead ends.

### Separation of data and logic

There is **partial separation**, but not clean separation.

Separated:

- scenario narrative text and metadata are in JSON
- scene structure is separated from script logic

Not separated well:

- correctness logic is implicit in strings
- penalties/rewards are hardcoded in popup callbacks
- phase thresholds are hardcoded in `GameManager.mark_scenario_complete()`
- strategy lock rules are hardcoded in `ScenarioPopup.gd`
- endgame evaluation thresholds are hardcoded in `CeoPopup.gd`

This means adding content is possible, but adding **new mechanics** is not yet easy.

### Extensibility for new scenarios

Adding a new scenario is moderately easy if it follows the exact existing schema and naming conventions:

- add an object to JSON
- wire its ID into a `RiskRoom` or new scene instance

But adding scenarios with:

- multiple correct answers
- multiple mitigation options
- conditional follow-up events
- weighted outcomes
- scenario prerequisites
- stateful consequences

would require structural changes, especially inside `ScenarioPopup.gd` and `GameManager.gd`.

### What would need to change to support richer mechanics

#### To support a risk register

Needed changes:

- create a dedicated `RiskRegister` data model instead of just `decision_log`
- store risk lifecycle states such as:
  - identified
  - analyzed
  - response selected
  - owner assigned
  - residual risk
  - status
- let scenario choices create/update register entries
- add UI for viewing and filtering current risks
- connect register state to future scenario generation and final scoring

Best structural move:

- introduce resource/data classes or dictionaries like:
  - `RiskEntry`
  - `ProjectState`
  - `ScenarioDefinition`
  - `OutcomeDefinition`

#### To support resource/budget management

Needed changes:

- split budget into categories:
  - contingency reserve
  - operating budget
  - staffing
  - vendor spend
- let actions cost different resource types
- move penalties out of fixed popup callbacks into scenario-driven outcome definitions
- add decision screens where players choose between options with explicit cost/benefit tradeoffs

Best structural move:

- implement an action-resolution layer:
  - player chooses action
  - system evaluates cost
  - project state mutates
  - follow-up risks are generated or suppressed

#### To support probabilistic outcomes

Needed changes:

- each scenario needs structured probabilities and outcome tables
- action choices need success/failure distributions, not binary right/wrong
- project state modifiers should influence roll weights
  - e.g. stronger staffing reduces probability of delay
  - low budget increases chance of failure
- random resolution should occur in a dedicated simulation module, not in UI code

Best structural move:

- create a resolver such as `ScenarioResolver.gd` or `RiskEngine.gd`
- keep `ScenarioPopup.gd` only as a presenter/controller

#### To support a scoring system with meaningful strategic depth

Needed changes:

- define rubric categories explicitly:
  - project survival
  - efficiency
  - risk coverage
  - stakeholder satisfaction
  - learning accuracy
- score based on consequences over time, not just answer correctness
- attach final grading to accumulated state and unresolved risk exposure

Best structural move:

- replace one-dimensional point accumulation with a score service that evaluates multiple dimensions from project state

## 5. Recommendations Summary

### Top 5 places to inject interactive risk-management mechanics

1. **Scenario resolution in `ScenarioPopup.gd`**
   - This is the highest-leverage insertion point.
   - Replace binary right/wrong handling with multi-option responses that change persistent project state, create residual risks, and spawn follow-up consequences.

2. **Global state in `autoloads/GameManager.gd`**
   - Expand it from a scorekeeper into a real project-state container.
   - Add structured resources, active risks, stakeholder health, technical debt, compliance exposure, and unresolved issue queues.

3. **Scenario data model in `gppt_crisis_cabinet_v2.json`**
   - Evolve the schema so each scenario has:
     - explicit correct/acceptable responses
     - option lists
     - state prerequisites
     - cost deltas
     - probability tables
     - downstream scenario hooks
   - This is the key to making the system content-driven instead of string-driven.

4. **Room/phase progression in `MainFacility.tscn` + `RoomDoor.gd`**
   - Replace pure completion-count progression with state-based progression.
   - Example: a door could unlock only if the player has stabilized critical risks, kept burn within range, or completed required register tasks.

5. **HUD / project board in `GameHUD.gd`**
   - The current HUD is the natural place to surface:
     - active risk register
     - budget categories
     - risk heat map
     - unresolved red flags
     - stakeholder trust
     - contingency reserve
   - This would make decisions feel systemic instead of isolated.

### Technical debt and issues to fix first

1. **Brittle text-driven logic**
   - Correct answers are inferred from title/objective/winCondition strings.
   - This should be replaced with explicit structured fields in JSON.

2. **Overloaded `ScenarioPopup.gd`**
   - It is too responsible for both UI and rules.
   - Split into UI presentation plus scenario evaluation/service logic.

3. **Placeholder / unused systems**
   - `walk_tile()` is empty.
   - `contingency_hp` and `update_health()` exist but are not meaningfully integrated into current gameplay.
   - `dim_scores` appears unused.
   - `SuddenTrigger.gd` exists, but no evidence in the main level suggests it is currently used in the shipped flow.

4. **Progression coupling is conceptually muddy**
   - Doors use `required_xp`, but unlocking is actually determined through phase mapping in `RoomDoor.gd`.
   - This should be refactored to use either real XP or explicit required phases, not both.

5. **Difficulty description mismatch**
   - `DifficultyPopup.gd` says Easy has 4 active scenario pads, but `RiskRoom.gd` only activates 1 pad per room on Easy.
   - The wording is not catastrophic, but it is misleading and hints at design drift.

6. **Pause menu includes cheat controls in production flow**
   - Budget adjustment buttons materially undermine score validity and analysis of player performance.
   - If intentional, they should be clearly debug-only.

7. **Some state updates are inconsistent**
   - Budget color warning in `GameHUD.gd` is only applied in `_build_project_board()` and not cleanly refreshed as budget changes.
   - Several emitted state changes rely on UI discovering them ad hoc rather than a clearer state-update contract.

8. **Binary pedagogy limits replayability**
   - Even where the game teaches useful concepts, the architecture assumes one correct response path.
   - This makes future expansion harder because all systems are built around correctness checks rather than consequences.

## Final Assessment

`Crisis Cabinet` is a solid early-stage **educational serious game prototype** with clear PMBOK/Tusler learning goals, a coherent Godot scene structure, and a functional single-map progression loop. Its strongest current qualities are:

- approachable world navigation
- clean scenario externalization into JSON
- a working assessment loop
- visible educational feedback

Its biggest limitation is that it is still fundamentally a **linear quiz wrapped in movement**, not yet a project-risk simulation.

To evolve it into a richer interactive risk-management game, the next major step is not more content first. The next major step is a **data-model and rules-architecture refactor** so scenario outcomes can mutate a persistent project state and influence future events.

Once that refactor is in place, the existing map, triggers, rooms, and UI shell are good foundations for a much stronger management game.
