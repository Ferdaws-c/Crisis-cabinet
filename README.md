# 🏆 Crisis Cabinet: IT Project Risk Management Simulation

[![Engine](https://img.shields.io/badge/Engine-Godot_4.4.1-blue?logo=godot-engine&logoColor=white)](https://godotengine.org/)
[![Course](https://img.shields.io/badge/IKU-COM0463_IT_Project_Management-red)](https://www.iku.edu.tr/)
[![Framework](https://img.shields.io/badge/GPPT-v2.0.10_Framework-green)](#)
[![Database](https://img.shields.io/badge/Database-SilentWolf_Cloud-orange)](https://silentwolf.com/)

**Crisis Cabinet** is an immersive 2D top-down gamified simulation built in **Godot 4.4.1 (GL Compatibility)**. Designed as part of the senior curriculum for **COM0463 (IT Project Management) at Istanbul Kültür University**, it teaches PMBOK 7th Edition **Project Risk Management (Chapter 11)** principles to senior IT students using kinesthetic learning and game-based training.

---

## 📖 Table of Contents
1. [Project Overview](#-project-overview)
2. [Educational & Theoretical Framework](#-educational--theoretical-framework)
3. [Gameplay Mechanics](#-gameplay-mechanics)
4. [Minigame Suite](#%EF%B8%F0-minigame-suite)
5. [Difficulty & Score System](#-difficulty--score-system)
6. [Technical Architecture](#%EF%B8%F0-technical-architecture)
7. [Leaderboard & Persistence](#-leaderboard--persistence)
8. [Controls Reference](#-controls-reference)
9. [Setup & Running](#%EF%B8%F0-setup--running)

---

## 🎯 Project Overview

In traditional classrooms, students memorize risk management theory but struggle to apply it under time-pressured project conditions. They frequently confuse **Mitigation** with **Avoidance** and struggle to identify when **Acceptance** is the correct professional choice. 

**Crisis Cabinet** bridges this gap:
* Players navigate a corporate facility as a Project Manager avatar.
* Four Risk Rooms correspond to PMBOK lifecycle phases: **Planning ➔ Executing ➔ Monitoring ➔ Closing**.
* Interactive Risk Pads present realistic IT crisis scenarios mapped directly from the **Tusler Risk Classification Matrix**.
* Poor choices drain the project budget and schedule, providing zero-stakes consequences for decision-making.

---

## 🎓 Educational & Theoretical Framework

### 1. Tusler Risk Classification Matrix
All in-game scenarios are organized around Tusler's 2×2 **Probability × Impact** matrix:

| Category | Probability | Impact | Target PMBOK Response |
| :--- | :--- | :--- | :--- |
| 🐯 **Tiger** | High (≥70%) | High (≥$15k) | **Mitigate** or **Avoid** |
| 🐊 **Alligator** | Low (≤25%) | High (≥$15k) | **Transfer** or **Mitigate** |
| 🐶 **Puppy** | High (≥70%) | Low (≤$5k) | **Accept** or **Avoid** |
| 🐱 **Kitten** | Low (≤25%) | Low (≤$5k) | **Accept** (always) |

### 2. PMBOK §11 Risk Responses
Before resolving a crisis pad, players read lesson text mapping to:
* **Avoidance:** Eliminating the threat or protecting the project from its impact.
* **Mitigation:** Action taken to reduce the probability or impact of a risk.
* **Transference:** Shifting ownership of the impact/response to a third party (e.g., insurance, outsourcing).
* **Acceptance:** Acknowledging the risk and choosing not to take active intervention unless it occurs.

---

## 🕹️ Gameplay Mechanics

```
Lobby (Kiosk Mode) ➔ Tutorial Gate ➔ Planning Room ➔ Executing Room ➔ Monitoring Room ➔ Closing Room ➔ CEO Suite (Evaluation)
```

1. **Tutorial Gate:** Doors to the facility remain locked until the player reads the initial *PMBOK Briefing Kiosk*.
2. **Kiosk Difficulty Selection:** Players choose **Easy**, **Medium**, or **Hard** presets.
3. **Phase-Locked Doors:** Rooms unlock sequentially as risk scenarios are solved. Door state logic updates dynamically via reactive signals.
4. **Interaction Prompts:** Interface cues appear bottom-right when the player is near a Risk Pad.
5. **CEO Evaluation:** The game ends in the CEO Suite where players receive a performance grade based on budget conservation and classification accuracy.

---

## 🎮 Minigame Suite
Inside the facility, players participate in interactive minigames representing IT processes, modified with specific risk dynamics:

* **SWOT Smasher:** Players categorize strengths, weaknesses, opportunities, and threats. Incorrect choices carry a **-$500** penalty.
* **Decision Dash:** A fast-paced decision challenge offering a flat **+$1,000** bonus.
* **Trigger Tracker:** Avoid threat icons. Hits carry a **-$1,500** budget penalty and cost **-1 Day** from the schedule.
* **Reserve Roulette:** Test risk contingency funds. Missing targets incurs a **-$300** penalty.
* **Audit Escape:** Run through security checks. Collecting green items increases player speed, while hitting red obstacles slows the player down.

---

## 📊 Difficulty & Score System

| Setting | Easy | Medium | Hard |
| :--- | :--- | :--- | :---: |
| **Starting Budget** | $200,000 | $150,000 | $100,000 |
| **Risk Pads per Room** | 1 | 2 | 3 |
| **Total Scenarios** | 4 | 8 | 12 |
| **Schedule Days** | 120 | 120 | 120 |

### Scoring Formula
Final player score evaluated out of **100 points**:
$$\text{Composite Score} = \text{Budget Score } (50\text{ pts}) + \text{Performance Score } (50\text{ pts}) - \text{Late Schedule Penalties}$$
* **Budget Score:** Based on final remaining budget relative to difficulty baseline.
* **Performance Score:** Evaluates XP accumulated through scenario streaks.
* **Late Penalty:** Deducts 1 point for every day late beyond the 120-day limit.

---

## 🛠️ Technical Architecture

* **Engine:** Godot 4.4.1 (Stable)
* **Renderer:** `gl_compatibility` (OpenGL 3.3) for stability on older academic computers and integrated graphics.
* **Architecture Highlights:**
  * **Thread-Safe Snapshotting:** The `PerformanceReview.gd` scene snapshots all leaderboard data before rendering, preventing race conditions or crashes from scene state changes.
  * **Asynchronous Scene Transitions:** `CeoPopup.gd` transitions instantly to `PerformanceReview.tscn`, which displays a dark loading overlay during its 2.0s buffer to prevent underlying map flickering.
  * **Robust Cloud Uploads:** Database operations are completely decoupled from game states, running on static screens with action blocks.

---

## 🏆 Leaderboard & Persistence

Crisis Cabinet runs a split local-cloud scoreboard architecture:

* **Local Scoreboard:** Saves top-10 scores locally to `user://scoreboard.json`.
* **Global Leaderboard:** Integrates with the **SilentWolf Cloud API** to track scores globally.
  * **Extended Metadata:** Cloud score structures sync full decision logs and date stamps (`yyyy/mm/dd`) so users can audit global player stats from the Main Menu.
  * **Timeout Fail-Safe:** Global uploads run with a 59-second timeout timer. If the network is slow or connection fails, the exit action automatically unlocks to prevent players from getting stuck.

---

## ⌨️ Controls Reference

| Control | Action |
| :--- | :--- |
| **W, A, S, D** or **Arrow Keys** | Move Character Avatar |
| **SPACE** | Interact with Risk Pads, Doors, Kiosks |
| **ESC** | Open / Close Pause Menu |
| **D + E + L** (Main Menu Scoreboard) | Wipe Global Leaderboard (Admin Override) |

---

## 🚀 Setup & Running

### Prerequisites
* [Godot Engine 4.4.1 (Standard Version)](https://godotengine.org/download)

### Run in Editor
1. Clone this repository:
   ```bash
   git clone https://github.com/your-username/crisis-cabinet.git
   ```
2. Launch Godot Engine and import the project by selecting the `project.godot` file in the root directory.
3. Press **F5** to run the game.

### Build Executable
1. Within Godot, go to **Project ➔ Export**.
2. Select **Windows Desktop** (or your target OS).
3. Ensure the Target Renderer is set to **Compatibility**.
4. Click **Export Project** to output a standalone executable binary.
