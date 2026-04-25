# Crisis Cabinet - Gameplay Flow Guide

This document explains exactly what the player experiences at each stage of the game. Use it to understand the intended gameplay without reading the full design documents.

---

## Starting the Game

1. Player launches the game -> Main Menu appears
2. Player clicks "New Game" -> Enters the **Training Wing**
3. The Training Wing is a corridor with 6 station pads
4. Station 1 is available (glowing teal), Stations 2-6 are locked (dimmed)
5. Player walks to Station 1 and presses Space -> Station overlay opens

---

## Layer 1 - Learning the Fundamentals

The player progresses through 6 stations. Each teaches one concept through interactive exercises. Stations unlock sequentially.

### Station 1: "What Is a Risk?"
**The player sees:** 5 statements about the SecurePay project, one at a time  
**The player does:** Decides if each is a "Project Risk" or "Not a Risk"  
**After each answer:** An animated Cause -> Event -> Effect chain explains WHY it is or isn't a risk  
**Teaching point:** A risk has three parts - a cause, an uncertain event, and an impact on project objectives

### Station 2: "Probability"
**The player sees:** 5 risk events with three zone buttons (Low / Medium / High)  
**The player does:** Places each risk on the probability scale  
**After each placement:** Evidence columns show factors that increase and decrease likelihood  
**Teaching point:** Probability assessment should be evidence-based, not gut feeling

### Station 3: "Impact & Client Priorities"
**The player does (in sequence):**
1. **Talks to Dana** (CEO) through branching dialogue - learns her priorities
2. **Builds Dana's profile card** - sets four stat bars (Budget Tolerance, Schedule Flexibility, Quality Standards, Scope Flexibility) based on what Dana said
3. **Assesses impact** of 3 risks across 4 dimensions (Cost, Schedule, Quality, Scope)
4. **Sees ripple effects** showing how impact cascades through the project
5. **Views the priority lens** - how Dana's profile changes which impacts are critical vs tolerable
6. **Compares two clients** - Dana vs a government agency with opposite priorities

**Teaching point:** Impact isn't absolute - the same risk can be critical or minor depending on what the stakeholder cares about

### Station 4: "The Risk Matrix"
**The player sees:** A 2x2 matrix (Probability x Impact) with four quadrants  
**The player does:** Places 4 risks on the matrix  
**After each placement:** The quadrant reveals its fire metaphor identity:
- **Wildfire** (High Prob x High Impact) - act immediately, top priority
- **Volcano** (Low Prob x High Impact) - rare but catastrophic, always have a plan
- **Campfire** (High Prob x Low Impact) - constant but manageable, don't over-invest
- **Spark** (Low Prob x Low Impact) - log it and move on

**Teaching point:** The matrix turns a list of worries into a priority map

### Station 5: "Response Strategies"
**The player does (in sequence):**
1. **Investigates** by talking to Jordan (Senior Developer) about the payment API risk
2. **Explores all four strategies** - must click "See what happens" on each one:
   - **Avoid:** Eliminate the risk by changing the plan
   - **Mitigate:** Reduce probability or impact
   - **Transfer:** Shift the risk to a third party
   - **Accept:** Acknowledge and prepare a contingency
3. For each strategy, a **ripple effect** shows the consequences
4. After exploring all four, **chooses one** and sees a tradeoff analysis

**Teaching point:** Strategy selection is about matching tradeoffs to constraints, not finding the "right" answer

### Station 6: "Putting It All Together"
**The player does:** Completes one full risk assessment cycle on a new risk (QA testing framework incompatibility):
1. Identify -> 2. Assess probability -> 3. Assess impact -> 4. Classify on matrix -> 5. Investigate (talk to Alex) -> 6. Choose strategy -> 7. Review debrief

**Special mechanic:** Hints fade in after 8 seconds of inactivity at any step  
**Teaching point:** Validates readiness for the project simulation

---

## Layer 2 - The Project Simulation (Coming Next)

After completing all 6 stations, the player enters a four-phase project simulation:

**Planning -> Execution -> Monitoring -> Closing**

Each phase presents 4-5 risks. The player:
- Builds and maintains a **risk register**
- Allocates limited **budget** and **team capacity** to risk responses
- Faces **probability rolls** at the end of each phase - risks trigger or resolve based on their preparations
- Deals with **cascading consequences** - triggered risks spawn new risks
- Manages **stakeholder trust** through honest communication with Dana
- Can **fail** if the project reaches an unrecoverable state (but failure includes a detailed debrief showing what went wrong and why)

The old XP/points system is replaced by a **Project Health Dashboard** with four dimensions: Budget Health, Schedule Health, Quality Health, and Stakeholder Trust.

---

## Layer 3 - The Proving Ground (Coming Later)

Same project (SecurePay) but post-launch during an acquisition:

- Dana's priorities **shift** under pressure from the acquiring company
- Some risks are **ambiguous** - team members disagree on probability
- Some decisions have **ethical dimensions** beyond pure risk calculus
- **No hints**, shorter debriefs, less guidance - the player operates independently

The game ends with a **Management Profile** (not a score) that describes what kind of PM the player became.
