# Crisis Cabinet — Full Project Documentation
**Version:** 1.0 · **Engine:** Godot 4.4.1 (GL Compatibility)  
**Course:** COM0463 — IT Project Management · **Istanbul Kültür University**  
**Assessment Framework:** GPPT v2.0.10 · **Score:** 601 / 800

---

## Table of Contents
1. [Project Overview](#1-project-overview)
2. [Learning Objectives & PMBOK Alignment](#2-learning-objectives--pmbok-alignment)
3. [Theoretical Framework](#3-theoretical-framework)
4. [Game Architecture & Scene Structure](#4-game-architecture--scene-structure)
5. [Gameplay Mechanics](#5-gameplay-mechanics)
6. [Difficulty System](#6-difficulty-system)
7. [Scenario Library (All 12 Scenarios)](#7-scenario-library-all-12-scenarios)
8. [Phase Progression System](#8-phase-progression-system)
9. [Scoring & Reward System](#9-scoring--reward-system)
10. [HUD & Minimap System](#10-hud--minimap-system)
11. [Functional Requirements](#11-functional-requirements)
12. [Non-Functional Requirements](#12-non-functional-requirements)
13. [Risk Register (Project Risks)](#13-risk-register-project-risks)
14. [KPIs & Assessment Criteria](#14-kpis--assessment-criteria)
15. [Ethical Design & Compassion Model](#15-ethical-design--compassion-model)
16. [Technical Deployment Notes](#16-technical-deployment-notes)

---

## 1. Project Overview

**Crisis Cabinet** is a 2D top-down gamified simulation built in Godot 4.4.1, designed to teach PMBOK 7th Edition **Risk Management (Chapter 11)** to senior IT students who have no prior exposure to formal project management methodology.

The player navigates a corporate facility as a Project Manager avatar, physically walking through four Risk Rooms that correspond to the four PMBOK project lifecycle phases: **Planning → Executing → Monitoring → Closing**. Within each room, Risk Pads present real-world IT crisis scenarios drawn from the **Tusler Risk Classification Matrix**. Players must select the correct PMBOK risk response strategy (Mitigate, Accept, Transfer, Avoid) before resources deplete.

### Core Problem Statement
> Senior IT students (3rd/4th year) can recall risk management theory from lectures but consistently fail to apply it under ambiguous, time-pressured conditions. They cannot distinguish between Mitigation and Avoidance, or correctly identify when Acceptance is the professional choice. Crisis Cabinet creates consequences for wrong decisions, forcing the kinesthetic application of PMBOK §11 in a zero-stakes simulation environment.

### Target Population
- **Primary:** 3rd and 4th-year Computer Engineering students enrolled in COM0463 (IT Project Management)
- **Secondary:** Instructors using the game as a live classroom demonstration tool
- **Platform:** Windows PC (exported binary, no install required)
- **Session Length:** 20–45 minutes depending on difficulty

---

## 2. Learning Objectives & PMBOK Alignment

| # | Learning Outcome | Bloom Level | PMBOK Reference |
|---|---|---|---|
| LO-1 | Classify a real-world IT risk using the Tusler 4-category matrix (Tiger, Alligator, Puppy, Kitten) | **Remember / Understand** | PMBOK §11.2 |
| LO-2 | Select the correct PMBOK risk response strategy given probability and impact data | **Apply** | PMBOK §11.5 |
| LO-3 | Differentiate between Mitigation, Avoidance, Transference, and Acceptance in realistic IT scenarios | **Analyse** | PMBOK §11.5 |
| LO-4 | Evaluate when Risk Acceptance is the professionally superior choice over active intervention | **Evaluate** | PMBOK §11.5.4 |

### Bloom Taxonomy Coverage

```
Remember    ██████████ Tusler Matrix definitions, PMBOK strategy names
Understand  ████████── Scenario setup comprehension, lesson text
Apply       █████████─ Choosing and executing correct strategy per pad
Analyse     ████████── Distinguishing strategies from each other mid-session
Evaluate    ██████──── Judging Accept vs Mitigate under budget pressure
Create      ──────────  (Not targeted in v1.0)
```

---

## 3. Theoretical Framework

### 3.1 Tusler Risk Classification Matrix
The game's entire scenario library is organised around Tusler's 4-category model, which classifies risks on a 2×2 matrix of **Probability** × **Impact**:

| Category | Probability | Impact | Correct Strategy |
|---|---|---|---|
| 🐯 **Tiger** | High (≥70%) | High (≥$15k) | Mitigate or Avoid |
| 🐊 **Alligator** | Low (≤25%) | High (≥$15k) | Transfer or Mitigate |
| 🐶 **Puppy** | High (≥70%) | Low (≤$5k) | Accept or Avoid |
| 🐱 **Kitten** | Low (≤25%) | Low (≤$5k) | Accept (always) |

Each physical Risk Pad in the game world is assigned one of these four categories. The HUD shows the player the category icon alongside probability and impact data before they select a response.

### 3.2 Self-Determination Theory (SDT)
The motivational structure of Crisis Cabinet is grounded in SDT's three core psychological needs:

- **Competence:** Difficulty scaling (Easy/Medium/Hard) and per-phase lesson text ensure players always feel challenged but not overwhelmed. Immediate correct/incorrect feedback reinforces mastery.
- **Autonomy:** Players physically navigate the map, choosing the order of approach within a room. The pause menu allows controlled exit at any time.
- **Relatedness:** The Performance Review screen and Scoreboard contextualise individual performance against a shared benchmark, creating peer comparison without competitive harm.

### 3.3 Octalysis Framework (Chou, 2016)
The 8 core drives are addressed as follows:

| Octalysis Drive | Implementation |
|---|---|
| Epic Meaning & Calling | Player is the sole PM who can save the project; narrative briefing from the CEO sets stakes |
| Development & Accomplishment | XP bar, streak counter, phase unlocks |
| Empowerment of Creativity | Multiple valid response paths; player explores map freely |
| Ownership & Possession | Budget resource is "owned" — every wrong answer costs real dollars |
| Social Influence & Relatedness | Global scoreboard on the main menu |
| Scarcity & Impatience | 120-day schedule timer creates urgency |
| Unpredictability & Curiosity | Randomised scenario order within each room |
| Loss & Avoidance | Budget depletion → Game Over triggers an Audit Report screen |

### 3.4 HEXAD Player Types
The game is designed to engage four primary HEXAD types:

- **Achiever:** XP, streaks, high-score ranking
- **Free Spirit:** Open map navigation, self-paced exploration
- **Philanthropist:** In-game CEO debrief teaches why their decision helps the team
- **Player:** Difficulty selection, score optimisation

### 3.5 MDA Framework (Mechanics → Dynamics → Aesthetics)

| Layer | Description |
|---|---|
| **Mechanics** | Space Bar interaction, Risk Pad confirmation, door phase-locks, budget deduction |
| **Dynamics** | Budget pressure forces prioritisation; streak rewards encourage consecutive correct decisions |
| **Aesthetics** | Sensation (immersive facility), Fantasy (PM role-play), Challenge (timed budget), Discovery (learn PMBOK through exploration) |

---

## 4. Game Architecture & Scene Structure

### 4.1 Engine & Renderer
- **Engine:** Godot 4.4.1 Stable
- **Renderer:** `gl_compatibility` (OpenGL 3.3)
  - Switched from Forward+ (Vulkan) for cross-platform stability on Intel integrated graphics (e.g. Surface Pro 6, university lab machines)
- **Export Target:** Windows x86_64 (PCK embedded)

### 4.2 Scene Tree
```
MainFacility.tscn                  ← Primary game world
├── Player                         ← CharacterBody2D, keyboard-driven
├── GameHUD (CanvasLayer)          ← Live budget/XP/phase display
│   ├── BudgetValue
│   ├── HPValue
│   ├── PhaseValue
│   ├── XPValue
│   └── [Procedural] Minimap
├── InteractionTriggers
│   ├── Doors/
│   │   ├── IntroDoor              ← Locked until InfoTrigger read
│   │   ├── RoomDoor               ← Locked until Executing phase
│   │   ├── RoomDoor2              ← Locked until Monitoring phase
│   │   ├── RoomDoor3              ← Locked until Closing phase
│   │   └── CeoRoomDoor            ← Locked until Finished phase
│   ├── InfoTrigger                ← Mandatory tutorial popup
│   ├── DifficultyZone             ← Difficulty selection kiosk
│   └── CeoTrigger                 ← Triggers CEO debrief
├── RiskRooms/
│   ├── RiskRoom   (Planning)      ← 1 pad Easy / 2 Medium / 3 Hard
│   ├── RiskRoom2  (Executing)
│   ├── RiskRoom3  (Monitoring)
│   └── RiskRoom4  (Closing)
└── UI Layers
    ├── ScenarioPopup              ← Full-screen crisis popup
    ├── PauseMenu
    ├── AuditScreen                ← Game Over debrief
    └── PerformanceReview          ← End-of-game stats
```

### 4.3 Autoload Singleton: GameManager
`GameManager.gd` is registered as an autoload singleton and persists across all scenes.

**Key state variables:**

| Variable | Type | Purpose |
|---|---|---|
| `budget` | int | Current project budget ($200k / $150k / $100k) |
| `contingency_hp` | int | Contingency reserves (100 = full, 0 = game over) |
| `schedule_days` | int | Days remaining in project (starts at 120) |
| `xp_score` | int | Experience points earned from correct decisions |
| `streak` | int | Consecutive correct decisions (multiplies XP) |
| `scenarios_completed` | int | Master counter for phase progression |
| `current_phase` | String | "Planning" / "Executing" / "Monitoring" / "Closing" / "Finished" |
| `current_difficulty` | String | "Easy" / "Medium" / "Hard" |
| `has_read_info` | bool | Tutorial gate — doors locked until true |
| `decision_log` | Array | Full audit trail of every player choice |
| `total_play_time` | float | Elapsed seconds for composite score calculation |

---

## 5. Gameplay Mechanics

### 5.1 Player Movement
- **Input:** Arrow keys or WASD for 4-directional movement
- **Movement cost:** Free — movement does not deduct from the project budget
- **Pause state:** `GameManager.is_movement_paused = true` freezes the player during all popup interactions

### 5.2 Risk Pad Interaction (TuslerPad.gd)
1. Player walks near a Risk Pad (Area2D triggers `body_entered`)
2. A **"PRESS [ SPACE ] TO INTERACT"** HUD prompt appears bottom-right (above minimap)
3. Player presses `Space` → `pad_confirmed` signal emitted
4. `StaticBody2D` collision body is immediately `queue_free()`'d — the pad is permanently passable
5. `ScenarioPopup` scene is shown with the scenario data for this pad's category

### 5.3 Scenario Popup Flow (ScenarioPopup.gd)
1. **Setup Panel:** Displays the scenario title, Tusler category icon, probability %, impact $, urgency level, and problem narrative
2. **Lesson Panel:** PMBOK educational text explaining the relevant risk theory
3. **Decision Panel:** Four strategy buttons — **Mitigate / Accept / Transfer / Avoid**
4. **Feedback Panel:** Correct/incorrect result with explanation; the "Continue" button is **immediately disabled** on press (anti-double-click guard)
5. `GameManager.mark_scenario_complete(passed)` is called once and only once
6. Popup fades out; player movement resumes

### 5.4 Phase-Locked Doors (RoomDoor.gd)
Doors unlock automatically when the game phase progresses. The lock logic is **name-based** (not XP-based), ensuring difficulty-agnostic scaling:

| Node Name | Unlocks When Phase = |
|---|---|
| `IntroDoor` / `required_xp ≤ 0` | `has_read_info == true` |
| `RoomDoor` | Executing |
| `RoomDoor2` | Monitoring |
| `RoomDoor3` | Closing |
| `CeoRoomDoor` | Finished |

A visual "PHASE LOCKED" flash (red Label) fires when the player attempts to open a locked door prematurely.

---

## 6. Difficulty System

Three difficulty presets are available via the **Difficulty Zone** kiosk in the lobby:

| Setting | Easy | Medium | Hard |
|---|---|---|---|
| Starting Budget | $200,000 | $150,000 | $100,000 |
| Pads per Room | 1 | 2 | 3 |
| Total Scenarios | 4 | 8 | 12 |
| Schedule Days | 120 | 120 | 120 |
| Low-Budget Warning | ≤ $40,000 | ≤ $30,000 | ≤ $20,000 |

**Phase thresholds** are computed dynamically:
```gdscript
var quarter = max_s / 4
# Planning:   0 → quarter-1 scenarios
# Executing:  quarter → (quarter*2)-1
# Monitoring: (quarter*2) → (quarter*3)-1
# Closing:    (quarter*3) → max_s-1
# Finished:   max_s completed
```
This ensures each phase contains exactly **25% of the total scenario count** regardless of difficulty.

---

## 7. Scenario Library (All 12 Scenarios)

All scenarios are stored in `gppt_crisis_cabinet_v2.json` and loaded at runtime.

### Phase 1 — Planning (SC-01 to SC-03 on Hard)

| ID | Title | Category | Probability | Impact | Correct Strategy |
|---|---|---|---|---|---|
| SC-01 | Legacy DB Migration | 🐯 Tiger | 85% | -$25,000 | **Mitigate** |
| SC-02 | UI Framework Deprecation | 🐶 Puppy | 80% | -$5,000 | **Accept** |
| SC-03 | Data Center Earthquake | 🐊 Alligator | 5% | -$15,000 | **Transfer** |

**SC-01 Win Condition:** Run parallel shadow databases and perform incremental syncs prior to cutoff  
**SC-02 Win Condition:** Document technical debt; consciously schedule a refactor sprint for Q3  
**SC-03 Win Condition:** Purchase multi-region failover insurance; negotiate SLA uptime penalties

### Phase 2 — Executing (SC-04 to SC-06 on Hard)

| ID | Title | Category | Probability | Impact | Correct Strategy |
|---|---|---|---|---|---|
| SC-04 | Lead Developer Poached | 🐯 Tiger | 90% | -$25,000 | **Mitigate** |
| SC-05 | Scope Creep via Email | 🐶 Puppy | 85% | -$5,000 | **Avoid** |
| SC-06 | Office Coffee Machine | 🐱 Kitten | 15% | -$1,000 | **Accept** |

**SC-04 Win Condition:** Enforce 8 hrs/day mandatory pair programming and documentation until exit  
**SC-05 Win Condition:** Sever direct comms; force all requests through formal Change Control Board  
**SC-06 Win Condition:** Log as low-priority note; approve $50 for local coffee shop fallback

### Phase 3 — Monitoring (SC-07 to SC-09 on Hard)

| ID | Title | Category | Probability | Impact | Correct Strategy |
|---|---|---|---|---|---|
| SC-07 | API Rate Limits Exceeded | 🐯 Tiger | 95% | -$25,000 | **Avoid** |
| SC-08 | New Privacy Legislation | 🐊 Alligator | 15% | -$15,000 | **Mitigate** |
| SC-09 | Minor Server Memory Leak | 🐶 Puppy | 75% | -$5,000 | **Accept** |

**SC-07 Win Condition:** Design a local caching layer to eliminate 80% of live API calls  
**SC-08 Win Condition:** Abstract the encryption layer into an isolated microservice module  
**SC-09 Win Condition:** Schedule an automated nightly reboot script; log Jira ticket for Q4

### Phase 4 — Closing (SC-10 to SC-12 on Hard)

| ID | Title | Category | Probability | Impact | Correct Strategy |
|---|---|---|---|---|---|
| SC-10 | Client Refuses Final Signoff | 🐊 Alligator | 25% | -$15,000 | **Mitigate** |
| SC-11 | Data Corruption on Handover | 🐯 Tiger | 85% | -$25,000 | **Mitigate** |
| SC-12 | Typo in User Manual | 🐱 Kitten | 20% | -$1,000 | **Accept** |

**SC-10 Win Condition:** Produce signed Requirements Traceability Matrix; offer report as Phase 2 CR  
**SC-11 Win Condition:** Execute immediate rollback to pre-handover snapshot; mandate password resets  
**SC-12 Win Condition:** Note error in closure document; patch in next Q2 documentation cycle

### Tusler Coverage Summary

| Category | Total Scenarios | Strategies Demonstrated |
|---|---|---|
| 🐯 Tiger | 5 | Mitigate (×4), Avoid (×1) |
| 🐊 Alligator | 3 | Transfer (×1), Mitigate (×2) |
| 🐶 Puppy | 3 | Accept (×2), Avoid (×1) |
| 🐱 Kitten | 2 | Accept (×2) |

All 4 PMBOK §11.5 response strategies (Mitigate, Accept, Transfer, Avoid) are represented.

---

## 8. Phase Progression System

The game is structured around the 4 PMBOK project lifecycle phases, each corresponding to a physical room in the facility:

```
Lobby → [InfoTrigger] → Planning Room → [Door 1] → Executing Room
                                                     ↓
                              CEO Office ← [CEO Door] ← Closing Room ← [Door 3] ← Monitoring Room
                                                                                    [Door 2]
```

### Phase Transition Logic
```gdscript
func mark_scenario_complete(passed: bool = true) -> void:
    scenarios_completed += 1
    var max_s = 12  # (4 Easy / 8 Medium / 12 Hard)
    var quarter = max_s / 4

    if   scenarios_completed >= max_s:        current_phase = "Finished"
    elif scenarios_completed >= quarter * 3:  current_phase = "Closing"
    elif scenarios_completed >= quarter * 2:  current_phase = "Monitoring"
    elif scenarios_completed >= quarter * 1:  current_phase = "Executing"
    else:                                     current_phase = "Planning"
```

Phase transitions emit `GameManager.state_changed`, which all doors and HUD elements subscribe to via `connect()`.

---

## 9. Scoring & Reward System

### 9.1 XP Score (Primary Learning Metric)
```
Base XP per correct scenario:  110 XP
Streak multiplier:             ×(1.0 + streak × 0.1)
  — 3-streak example:          110 × 1.3 = 143 XP
```
A wrong answer breaks the streak (resets to 0) but does **not** subtract XP (`losePoints = 0`).

### 9.2 Composite Score (Leaderboard)
```
Budget Score  = max(0, budget) / max_budget * 50
Perf Score    = clamp(xp_score / max_expected_xp, 0.0, 1.0) * 50
Time Penalty  = -1 point per negative schedule_day

composite_score = clamp(Budget Score + Perf Score - Time Penalty, 0, 100)
```
This formula evaluates player performance out of a clean **100 points maximum**:
- **Budget conservation** (up to 50 points, prevents negative budget from tanking score below 0)
- **Decision quality** (up to 50 points based on XP and streak multiplier)
- **Efficiency** (penalises 1 point for every day late)
- **Difficulty Scaled** (the max budget and max XP dynamically scale based on Easy/Medium/Hard mode, ensuring a perfect game always nets ~100 points)

### 9.3 Reward Tiers

| Tier | Trigger | Reward |
|---|---|---|
| **Elite PM** | Score ≥ 85% of maximum possible | CEO commendation scene + Gold badge |
| **Professional PM** | Score 60–84% | Standard debrief + Silver badge |
| **Trainee PM** | Score < 60% | Audit Report + Improvement recommendations |

### 9.4 Scoreboard Persistence
Scores are stored in `user://scoreboard.json` (top 10). Each entry records:
- Player name, difficulty, composite score, final budget, XP earned, total play time

---

## 10. HUD & Minimap System

### 10.1 Live HUD Elements (GameHUD.gd)
All elements update reactively on `GameManager.state_changed`:

| Element | Display | Source |
|---|---|---|
| Budget | `$XXX,XXX 💰` | `GameManager.budget` |
| Schedule | `XXX Days Left ⏱️` | `GameManager.schedule_days` |
| Streak | `X / 12 🔥` | `GameManager.streak` |
| XP | `XXXX XP ✨` | `GameManager.xp_score` |
| Phase | `PLANNING / EXECUTING...` | `GameManager.current_phase` |

### 10.2 Minimap
- **SubViewport** sharing the game world's `World2D` instance
- Camera follows player in real-time
- **Red Blinker:** 16×16px circular marker (bold, yellow-bordered) indicating the current objective room
- Pulsing animation (0.2→1.0 alpha, 400ms loop) ensures high visibility
- Blinker is automatically clamped to minimap boundaries when objective is off-screen

### 10.3 Interaction Prompt
- `"PRESS [ SPACE ] TO INTERACT"` appears bottom-right above the minimap
- Managed by `GameHUD.show_interaction_prompt(bool)` — called by `TuslerPad` on enter/exit/use
- Styled with yellow text on dark navy background with blue border

---

## 11. Functional Requirements

| ID | Requirement | Status |
|---|---|---|
| FR-01 | System shall load all 12 scenarios from `gppt_crisis_cabinet_v2.json` at startup | ✅ Implemented |
| FR-02 | System shall gate room doors behind PMBOK phase progression | ✅ Implemented |
| FR-03 | System shall present scenario popup with Tusler category, probability, impact, and 4 response options | ✅ Implemented |
| FR-04 | System shall award XP with streak multiplier for correct responses | ✅ Implemented |
| FR-05 | System shall trigger Game Over when budget reaches $0 | ✅ Implemented |
| FR-06 | System shall track and display all player decisions in an Audit Report | ✅ Implemented |
| FR-07 | System shall display a live minimap with objective blinker | ✅ Implemented |
| FR-08 | System shall support Easy / Medium / Hard difficulty via lobby kiosk | ✅ Implemented |
| FR-09 | System shall persist top-10 scores across sessions in `user://scoreboard.json` | ✅ Implemented |
| FR-10 | System shall lock all doors until the InfoTrigger tutorial is read | ✅ Implemented |
| FR-11 | System shall disable Continue button after first press (anti-double-count guard) | ✅ Implemented |
| FR-12 | System shall show interaction prompt on HUD (not world-space) when near a Risk Pad | ✅ Implemented |

---

## 12. Non-Functional Requirements

| ID | Attribute | Requirement | Implementation |
|---|---|---|---|
| NFR-01 | **Performance** | 60 FPS on Intel UHD 620 (Surface Pro 6) | GL Compatibility renderer |
| NFR-02 | **Portability** | Runs without installation on Windows 10/11 x64 | Self-contained PCK export |
| NFR-03 | **Accessibility** | No time-critical reflex required; Space Bar is the only interaction key | Single-button interaction design |
| NFR-04 | **Usability** | New player completes tutorial gate within 2 minutes | InfoTrigger mandatory briefing |
| NFR-05 | **Privacy** | No data transmitted externally; all scores stored locally | `user://scoreboard.json` only |
| NFR-06 | **Stability** | No crashes from button double-clicks or rapid input | `button.disabled = true` guard |

---

## 13. Risk Register (Project Risks — GPPT D7)

This section documents the **project development risks** using the Tusler model (distinct from the in-game educational scenarios).

| ID | Category | Risk Description | Prob | Impact | Response Strategy | Mitigation Action |
|---|---|---|---|---|---|---|
| R-01 | 🐯 Tiger | Rendering incompatibility on Intel integrated GPU causes transparency bugs | High | High | **Mitigate** | Switched renderer from Vulkan (Forward+) to OpenGL 3.3 (GL Compatibility); added procedural solid `ColorRect` backgrounds in `ScenarioPopup.gd` |
| R-02 | 🐯 Tiger | Phase progression skips stages on Medium/Hard due to float rounding or double-clicks | High | High | **Mitigate** | Replaced float math (`max_s * 0.75`) with integer `quarter = max_s / 4`; added `button.disabled = true` immediately on Continue press |
| R-03 | 🐊 Alligator | Originality score above 65% triggers plagiarism flag in GPPT | Low | High | **Mitigate** | Scenario texts are original IT crisis narratives; all Tusler content is grounded in real project cases, not copied from worked examples |
| R-04 | 🐶 Puppy | Student skips tutorial and cannot understand risk pad mechanics | High | Low | **Avoid** | `IntroDoor` is hard-locked (`required_phase_level = 99`) until `GameManager.has_read_info = true`; no bypass possible |

---

## 14. KPIs & Assessment Criteria

### Kirkpatrick Level 1 — Reaction
- **Metric:** Post-session survey rating (1–5 scale)
- **Method:** In-game CEO debrief asks "Was this simulation realistic?"
- **Target:** ≥ 4.0 / 5.0 average from 20+ test sessions

### Kirkpatrick Level 2 — Learning
- **Metric:** Scenario accuracy rate (correct decisions / total pads)
- **Method:** Automatically tracked per session; shown on Performance Review screen
- **Target:** ≥ 70% accuracy on first Hard-mode playthrough

### Kirkpatrick Level 3 — Behaviour
- **Metric:** Improvement in accuracy between first and third playthrough (same player)
- **Method:** Scoreboard composite score delta across sessions
- **Target:** ≥ 15% improvement in XP score by third session

### Kirkpatrick Level 4 — Results
- **Metric:** Student pass rate on COM0463 final exam risk management section
- **Method:** Instructor comparison of exam scores: cohort that used Crisis Cabinet vs. lecture-only cohort
- **Target:** ≥ 10% higher mean score in the gamified cohort

---

## 15. Ethical Design & Compassion Model

### 15.1 Zero-Harm Principle
```
losePoints = 0
```
No XP is ever subtracted for a wrong answer. The player's budget decreases (simulating project cost of poor decisions) but their personal knowledge score is never taken away. This prevents the "fear of failure" loop that discourages learning.

### 15.2 Non-Punitive Feedback
Wrong answers trigger an explanatory panel that teaches the correct PMBOK principle without blame language. The word "wrong" never appears — instead: *"A different approach was needed here."*

### 15.3 Privacy Compliance
- All data stored locally in `user://scoreboard.json`
- No player email, student ID, or biometric data is collected
- Scores are self-reported by player name (entered voluntarily)
- The game can be played completely anonymously as "Guest"

### 15.4 Compassion Mechanics
- **Difficulty Warning:** A confirmation dialog appears before Hard mode, warning the player about increased budget pressure
- **Audit Report:** Game Over shows a constructive Audit Report (not a failure screen) listing every decision and its PMBOK rationale
- **CEO Scene:** Successful completion ends with a positive narrative reinforcement from the "CEO" character

---

## 16. Technical Deployment Notes

### 16.1 Export Configuration
```
# project.godot
[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"

[display]
window/size/viewport_width=1920
window/size/viewport_height=1080
```

### 16.2 File Dependencies
| File | Path | Purpose |
|---|---|---|
| Scenario Data | `res://gppt_crisis_cabinet_v2.json` | All 12 PMBOK scenarios |
| Scoreboard | `user://scoreboard.json` | Persistent top-10 scores |
| GameManager | `res://autoloads/GameManager.gd` | Singleton state management |

### 16.3 Known Issues & Resolutions
| Issue | Root Cause | Resolution |
|---|---|---|
| Transparent popup background on Intel GPU | Vulkan's `StyleBoxFlat` rendered with alpha on OpenGL fallback | Replaced with procedural `ColorRect` solid background |
| Phase skipping on Medium/Hard | Float multiplication rounding (`int(8 * 0.75) = 5` instead of `6`) | Replaced with `quarter = max_s / 4` integer arithmetic |
| Double-counted scenario completions | Player double-clicking Continue before tween completed | `button.disabled = true` immediately on first press |
| Door unlocking wrong on Easy mode | XP-based threshold (330 XP) unreachable with 4 scenarios | Replaced with node-name-based phase mapping |

### 16.4 Controls Reference
| Key | Action |
|---|---|
| Arrow Keys / WASD | Move player |
| Space | Interact with Risk Pads / Doors |
| Escape | Open Pause Menu |

---

*Documentation generated: 2026-05-05 · Crisis Cabinet v1.0 · COM0463 GPPT Submission*
