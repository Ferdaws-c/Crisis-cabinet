# Crisis Cabinet — Layer 2 Design Document
## "The Project Simulation"

**Document version:** 1.0
**Date:** April 23, 2026
**Game engine:** Godot 4.4 (GDScript)
**Project context:** SecurePay — continued from Layer 1. Same client (Dana), same team, same constraints.
**Prerequisite:** Layer 1 complete (`layer1_complete == true`)

---

## 1. Layer 2 Overview

### Purpose

Layer 2 is where the player transitions from learning risk management concepts to practicing them under realistic project conditions. The player manages the full lifecycle of the SecurePay project across four phases, making decisions with limited resources, living with consequences, and discovering how risks interconnect and compound over time.

By the end of Layer 2, the player should be able to:

- Build and maintain a risk register as a living management tool
- Prioritize risks under resource constraints
- Choose response strategies based on tradeoffs, not textbook answers
- Investigate risks through conversation before committing to a response
- Recognize cascading consequences and risk interactions
- Read a project health dashboard and respond to deteriorating conditions
- Trace project outcomes back to their own decisions

### Design Principles

1. **Consequence is the curriculum.** Layer 2 does not tell the player "correct" or "incorrect." It shows what happened as a result of their choices, then explains why through debriefs.
2. **Decisions persist.** Every choice the player makes affects the project state for the remainder of the game. There is no reset between phases.
3. **Resource scarcity forces prioritization.** The player never has enough budget or capacity to address every risk fully. Choosing what to fund and what to accept is the core skill.
4. **Investigation is rewarded, not required.** The player can always skip NPC conversations and decide immediately, but doing so means acting on incomplete information. Better investigation leads to better decisions.
5. **Failure is educational.** If the project reaches an unrecoverable state, the game treats it as the most powerful teaching moment — not a punishment.

### Physical Layout in the Game

Layer 2 uses the existing four risk rooms in the facility map, repurposed as project phases:

- Room 1 → Planning Phase
- Room 2 → Execution Phase
- Room 3 → Monitoring Phase
- Room 4 → Closing Phase

The player progresses through rooms sequentially. Unlike the current implementation where doors unlock based on completion count, Layer 2 doors unlock when the player has completed all required actions for the current phase (assessed all surfaced risks, allocated responses, and confirmed their plan).

The HUD is updated to display the Project Health Dashboard and provide access to the Risk Register at all times.

---

## 2. Core Systems

### 2.1 — The Risk Register

The risk register is the player's primary tool throughout Layer 2. It is a persistent, interactive panel accessible from the HUD at any time.

**How risks enter the register:**

Risks enter the register through two mechanisms:

- **Auto-populated risks:** Most risks are surfaced through project events, phase transitions, and NPC reports. When these occur, a new entry appears in the register with status "Unassessed." The player sees a notification and must open the register to evaluate the risk. This keeps the game flowing without requiring manual data entry.

- **Hidden risks (player-identified):** 2-3 risks across all of Layer 2 are not surfaced automatically. Instead, they are hinted at through NPC dialogue — an offhand comment, a subtle complaint, a detail that doesn't quite add up. If the player recognizes the hint, they can manually add the risk to the register using an "Add Risk" button. If they miss it, the risk still exists in the system and can trigger later — but the player won't have prepared for it. This rewards attentive investigation and teaches that risk identification is an active skill.

**Risk register entry fields:**

Each entry in the register contains:

| Field | Description | Set by |
|-------|-------------|--------|
| Risk ID | Auto-generated sequential identifier | System |
| Title | Short description of the risk | System (auto-populated) or Player (hidden risks) |
| Source | How it was identified — event, NPC report, or player-identified | System |
| Phase Identified | Which project phase the risk was added | System |
| Probability | Low / Medium / High | Player |
| Impact Dimensions | Cost / Schedule / Quality / Scope ratings | Player |
| Matrix Category | Wildfire / Volcano / Campfire / Spark | Player (auto-suggested based on probability + impact) |
| Response Strategy | Avoid / Mitigate / Transfer / Accept | Player |
| Resources Allocated | Budget and/or capacity committed to the response | Player |
| Status | Unassessed / Analyzed / Response Planned / Active / Triggered / Resolved / Escalated | System + Player |
| Outcome | What actually happened (filled in when risk triggers or is resolved) | System |

**Register interactions:**

- The player can open the register at any time to review, update, or reassess risks.
- Risks that have triggered are marked visually (red border or fire icon matching their category).
- Resolved risks are grayed out but remain visible for reference.
- The register supports sorting by status, category, and phase.
- At any point, the player can change a risk's response strategy — but reallocating resources costs a phase action (see Section 3).

### 2.2 — Project Health Dashboard

The Project Health Dashboard replaces the current points/XP display in the HUD. It tracks four dimensions that reflect the real-time state of the SecurePay project.

**The four health dimensions:**

**Budget Health**
- Tracks remaining contingency budget relative to committed and spent resources
- Base states: On Track / Strained / Critical
- Expandable states (for future depth): On Track / Tightening / Strained / Depleted / Critical

**Schedule Health**
- Tracks accumulated schedule impact relative to the launch deadline
- Base states: On Track / Slipping / Critical
- Expandable states: Ahead / On Track / Slipping / At Risk / Critical

**Quality Health**
- Tracks cumulative quality impact from risk events, team changes, and shortcuts
- Base states: On Track / Declining / Critical
- Expandable states: Excellent / On Track / Declining / Deficient / Critical

**Stakeholder Trust**
- Tracks Dana's confidence in the project based on visible outcomes and the player's communication
- Base states: Confident / Concerned / Lost Confidence
- Expandable states: Enthusiastic / Confident / Neutral / Concerned / Lost Confidence

**How health changes:**

Each dimension has an internal numeric value (hidden from the player — they see only the state label). Values shift based on:

- Risk triggering events (negative shifts)
- Successful risk responses (positive or neutral shifts)
- Resource allocation choices (spending budget reduces Budget Health but may protect other dimensions)
- Phase progression without addressing critical risks (gradual negative drift)
- Stakeholder conversations (Trust shifts based on honesty, preparedness, and whether the player has answers to Dana's questions)

**Client priority weighting:**

Dana's client profile (established in Layer 1) weights how health changes translate to Stakeholder Trust. Because Dana has low schedule flexibility, a Schedule Health drop from "On Track" to "Slipping" causes a larger Trust drop than the same change in Budget Health. This is handled by a multiplier table:

| Dimension | Dana's Sensitivity | Trust Impact Multiplier |
|-----------|-------------------|----------------------|
| Budget | Low | 0.5x |
| Schedule | Very High | 2.0x |
| Quality | High | 1.5x |
| Scope | Medium | 1.0x |

These multipliers are defined in the scenario data, not hardcoded, so different clients in future content can have different sensitivity profiles.

**Dashboard visual design:**

Visual style decisions are deferred to the unified style pass after all layers are designed. The document specifies only the information architecture: four labeled indicators, each showing the current state label, with a visual treatment that makes "Critical" states immediately attention-grabbing and "On Track" states calm and unobtrusive.

### 2.3 — Resource System

The player manages two resource pools throughout Layer 2:

**Contingency Budget**
- Starting value: determined by difficulty level (carried from game start)
- Spent when: the player allocates budget to risk responses (mitigation costs, transfer contracts, avoidance replanning)
- Recovered when: a risk is resolved without triggering and the player had allocated budget to it (partial recovery — not full refund, since preparation still costs something)
- Visible in: the HUD, alongside the Budget Health indicator

**Team Capacity**
- Measured in available person-weeks per phase
- Starting value: 12 person-weeks per phase (representing a team of 4 working 3 weeks per phase)
- Spent when: the player assigns team effort to risk responses (investigation, mitigation work, parallel development, manual testing)
- Not recoverable within a phase — capacity is a per-phase budget
- Visible in: the HUD, as a simple bar or counter

**Resource allocation rules:**

- Each response strategy for each risk has a defined cost in budget and/or capacity (specified in scenario data)
- The player sees the cost before committing
- If the player cannot afford a strategy, it is grayed out with an explanation ("Requires $20K — you have $12K remaining")
- The player can reallocate resources by changing a risk's strategy, but this costs 1 person-week of capacity (representing the administrative overhead of replanning)
- Unspent capacity does not carry over between phases — it represents time, not savings

### 2.4 — Probabilistic Risk Triggering

At the end of each phase (before the door to the next room unlocks), the game resolves all active risks through probability rolls.

**How it works:**

Each risk has a base trigger probability defined in the scenario data (e.g., 70% for a high-probability risk). The player's response strategy modifies this probability:

| Strategy | Probability Modifier |
|----------|---------------------|
| Avoid | Risk is removed from the trigger pool entirely (probability = 0%) |
| Mitigate | Probability reduced by 30-50% (defined per scenario) |
| Transfer | Probability unchanged, but impact is reduced (the third party absorbs part of the damage) |
| Accept (active) | Probability unchanged, but contingency plan reduces impact if triggered |
| Accept (passive / no resources allocated) | Probability unchanged, full impact applies |
| Unassessed (player never addressed it) | Probability unchanged, full impact applies, plus a "surprise" penalty to Stakeholder Trust |

The roll is a simple random check: generate a number 0-100, if it's below the modified probability, the risk triggers.

**Design constraint on fairness:**

The system is tuned so that a well-prepared player (who assessed all risks, chose appropriate strategies, and allocated resources) can absorb 1-2 bad luck triggers per phase without reaching Critical in any dimension. Only a player who systematically neglects risks should face cascading failures. This means:

- Individual risk impact values are calibrated so that no single triggered risk can move a health dimension from "On Track" to "Critical" in one step
- The probability modifiers from mitigation are meaningful — a mitigated risk should trigger noticeably less often than an accepted one
- At least one risk per phase should have a relatively low trigger probability even without mitigation, giving the player some breathing room

**Trigger resolution sequence:**

When a risk triggers, the following sequence plays out:

1. An event notification appears: "RISK TRIGGERED: [Risk Title]"
2. The Ripple Effect animation plays, showing the consequence chain
3. Project Health Dashboard values update visibly
4. If the risk spawns downstream risks, new entries appear in the register as "Unassessed"
5. A brief debrief appears explaining why this happened and how the player's preparation (or lack of it) affected the outcome
6. The player acknowledges and continues

When a risk does NOT trigger:

1. The risk status updates to "Resolved" (if it was a one-time risk) or remains "Active" (if it persists into future phases)
2. A brief note appears: "Risk did not materialize this phase. Your [strategy] reduced the probability."
3. If the player had allocated budget, a partial refund is applied

### 2.5 — Cascading Consequences

Triggered risks can spawn new risks or modify existing ones. This is the mechanic that teaches risk interaction and the compounding nature of project problems.

**How cascading works:**

Each risk in the scenario data has an optional `if_triggered` field containing:

```
"if_triggered": {
    "spawns": [
        {
            "risk_id": "exec_003",
            "title": "New developer unfamiliar with payment module",
            "delay_phases": 0,
            "auto_populate": true
        }
    ],
    "modifies": [
        {
            "risk_id": "plan_002",
            "field": "probability",
            "change": "+20%",
            "reason": "Loss of key team member increases likelihood of integration delays"
        }
    ],
    "health_impact": {
        "budget": -15,
        "schedule": -25,
        "quality": -10,
        "stakeholder_trust": -20
    }
}
```

**Spawned risks** appear in the register immediately (if `delay_phases` is 0) or in a future phase (if delayed). They follow the same lifecycle as any other risk — the player must assess and respond to them.

**Modified risks** have their probability or impact adjusted. The player sees a notification: "Risk updated: [Title] — probability has increased due to [reason]." The register entry updates accordingly, and the player may want to reassess their strategy.

**Health impacts** are applied to the dashboard immediately. The ripple effect animation shows the player exactly which dimensions are hit and by how much.

**Cascading depth limit:** To keep the game manageable, cascading is limited to one generation — a spawned risk can trigger but does not spawn further risks. This prevents exponential complexity while still teaching the concept.

### 2.6 — Conversation and Investigation System

The conversation mechanic introduced in Layer 1 (Stations 5 and 6) is now fully active in every phase. Before responding to any risk, the player has the option to investigate by talking to relevant NPCs.

**How investigation works in Layer 2:**

When the player opens a risk in the register and prepares to choose a strategy, an "Investigate" button is available if there is an NPC with relevant information. Pressing it opens the branching conversation UI (reused from Layer 1's `NPCDialogue.tscn`).

Each investigation conversation is 2-4 exchanges. The information revealed can:

- Change the player's understanding of probability (NPC reveals evidence that makes the risk more or less likely)
- Reveal hidden impact dimensions the player might not have considered
- Suggest a strategy the player might not have thought of
- Reveal a hidden risk (if the player recognizes the hint)
- Provide context that makes the debrief more meaningful later

**Investigation cost:** Each investigation costs 1 person-week of team capacity. This creates a tradeoff — investigating every risk thoroughly leaves less capacity for actual mitigation work. The player must decide which risks are worth investigating and which they can assess from surface information alone.

**Skipping investigation:** The player can always skip investigation and go straight to strategy selection. This is faster and cheaper but means acting on less information. The game tracks whether the player investigated before responding, and the debrief references this: "You chose to Mitigate without investigating. If you'd talked to Jordan, you would have learned that the vendor already has a fix in progress — Accept might have been sufficient."

---

## 3. Phase-by-Phase Design

### 3.1 — Phase 1: Planning

**Narrative context:** The SecurePay project has been approved. The player's job is to identify the risks they can foresee, build their initial risk register, and allocate resources before development begins.

**Phase resources:**
- Contingency budget: Full starting amount (difficulty-dependent)
- Team capacity: 12 person-weeks

**Risks surfaced in this phase:**

5 risks are auto-populated into the register at the start of the phase:

| ID | Title | Source | Base Probability | Primary Impact | Cascade Potential |
|----|-------|--------|-----------------|----------------|-------------------|
| PLAN-01 | Lead developer may leave for competitor offer | Jordan mentions in team briefing | 60% | Schedule: High, Quality: Medium, Cost: Medium | If triggered: spawns EXEC-03 (replacement onboarding risk) |
| PLAN-02 | Third-party payment API may not be ready on time | Vendor status report | 50% | Schedule: High, Scope: Medium | If triggered: spawns EXEC-04 (manual payment workaround risk) |
| PLAN-03 | Client may request scope changes after first demo | Historical pattern | 75% | Scope: Medium, Schedule: Medium | If triggered: modifies PLAN-01 probability +10% (team stress) |
| PLAN-04 | New banking regulation may require additional security features | Industry news alert | 40% | Cost: High, Schedule: Medium, Quality impact is positive | If triggered: spawns MON-03 (compliance audit risk) |
| PLAN-05 | Project budget estimate may be too optimistic | Finance review flag | 55% | Budget: High | If triggered: reduces contingency budget by 20% |

**1 hidden risk available in this phase:**

| ID | Title | Hint Source | Base Probability | Primary Impact |
|----|-------|-------------|-----------------|----------------|
| PLAN-H1 | Team morale declining due to overtime expectations | Jordan mentions offhand: "The team's been putting in extra hours to prep — I hope that's not going to be the norm." | 45% | Quality: Medium, Schedule: Low (initially), but if combined with PLAN-01 triggering, probability jumps to 70% |

If the player recognizes the hint and adds this risk, they can mitigate it early (team-building budget, workload rebalancing). If they miss it, it persists silently into Execution.

**Player actions in Planning:**

1. Review the 5 auto-populated risks in the register
2. For each risk: assess probability and impact, classify on the matrix, choose a response strategy, allocate resources
3. Optionally investigate risks by talking to available NPCs
4. Optionally identify the hidden risk from NPC dialogue
5. Confirm the plan — this triggers the phase resolution (probability rolls for all active risks)

**NPCs available in Planning:**

| Character | Role | Information they provide |
|-----------|------|------------------------|
| Jordan (Senior Developer) | Returns from Layer 1 | Details on PLAN-01 (developer retention), hints at PLAN-H1 (team morale) |
| Dana (CEO) | Returns from Layer 1 | Reinforces schedule priority, provides context on PLAN-03 (scope change likelihood) |
| Sam (Vendor Contact) | New — light role | Details on PLAN-02 (API readiness), reveals vendor's track record |

**Phase resolution:**

After the player confirms their plan, probability rolls execute for all risks. Triggered risks play their consequence sequences. The door to Phase 2 (Execution) unlocks.

**Transition to Execution:**

A brief project status update appears: "Planning complete. Development begins. Here's where your project stands." The dashboard is shown with current health values. Any triggered risks and their consequences are summarized.

### 3.2 — Phase 2: Execution

**Narrative context:** Development is underway. The team is building the SecurePay app. Risks from Planning may have triggered, and new risks emerge as real work begins.

**Phase resources:**
- Contingency budget: Remaining from Planning (minus any spent)
- Team capacity: 12 person-weeks (fresh allocation — represents the next sprint cycle)

**Risks surfaced in this phase:**

3 new auto-populated risks, plus any spawned by Planning triggers:

| ID | Title | Source | Base Probability | Primary Impact | Cascade Potential |
|----|-------|--------|-----------------|----------------|-------------------|
| EXEC-01 | Key integration test environment unavailable due to infrastructure issue | DevOps report | 45% | Schedule: Medium, Quality: Medium | If triggered: modifies EXEC-02 probability +15% |
| EXEC-02 | Critical defects discovered in core payment flow during testing | QA report | 50% | Quality: High, Schedule: Medium, Stakeholder Trust: Medium | If triggered: spawns MON-01 (emergency fix resource crunch) |
| EXEC-03 | (Conditional) New developer struggling with codebase — only appears if PLAN-01 triggered | Team lead report | 65% | Quality: High, Schedule: Medium | If triggered: modifies MON-02 probability +20% |
| EXEC-04 | (Conditional) Manual payment workaround causing integration complexity — only appears if PLAN-02 triggered | Jordan's status update | 55% | Quality: Medium, Cost: Medium | No further cascade |

**1 hidden risk available in this phase:**

| ID | Title | Hint Source | Base Probability | Primary Impact |
|----|-------|-------------|-----------------|----------------|
| EXEC-H1 | Competitor launches similar app, increasing pressure from Dana to accelerate | Dana mentions in passing: "Did you see FinanceForward's press release yesterday? They're moving fast." | 60% | Stakeholder Trust: High (Dana becomes more demanding), Schedule: pressure increases |

If the player catches this and adds it, they can proactively manage Dana's expectations (Accept with active contingency: prepare a competitive analysis showing SecurePay's advantages). If missed, Dana's trust erodes faster in Monitoring.

**Player actions in Execution:**

1. Review any new risks in the register (auto-populated and spawned)
2. Reassess existing risks from Planning if circumstances have changed
3. For each new risk: assess, classify, respond, allocate resources
4. Optionally investigate and identify hidden risks
5. Manage capacity carefully — Execution typically has more active risks than Planning
6. Confirm phase completion — triggers resolution rolls

**NPCs available in Execution:**

| Character | Role | Information they provide |
|-----------|------|------------------------|
| Jordan (Senior Developer) | Ongoing | Details on EXEC-01, EXEC-03 (if present), technical context for decisions |
| Alex (QA Lead) | Returns from Layer 1 | Details on EXEC-02 (testing defects), quality assessment |
| Dana (CEO) | Brief check-in | Hints at EXEC-H1 (competitor pressure), asks about progress |

**Phase resolution and transition:**

Same structure as Planning — rolls execute, consequences play out, door to Monitoring unlocks. The project status update now shows trend arrows on the dashboard: dimensions that improved, worsened, or stayed stable compared to the end of Planning.

### 3.3 — Phase 3: Monitoring

**Narrative context:** The project is past the midpoint. The launch date is approaching. The cumulative weight of all decisions — good and bad — is now visible. This is the most demanding phase.

**Phase resources:**
- Contingency budget: Remaining from Execution
- Team capacity: 10 person-weeks (reduced — team fatigue, some capacity consumed by ongoing mitigation work from earlier phases)

**Risks surfaced in this phase:**

2-3 new auto-populated risks, plus any spawned by Execution triggers. Monitoring is intentionally the phase with the most active risks — the player is managing a portfolio, not individual items.

| ID | Title | Source | Base Probability | Primary Impact | Cascade Potential |
|----|-------|--------|-----------------|----------------|-------------------|
| MON-01 | (Conditional) Team stretched thin fixing defects, causing delays in feature completion — only appears if EXEC-02 triggered | Resource utilization report | 70% | Schedule: High, Quality: Medium, Stakeholder Trust: Medium | If triggered: directly threatens launch date |
| MON-02 | User acceptance testing reveals usability issues requiring redesign of key screens | UAT feedback report | 55% | Schedule: Medium, Cost: Medium, Quality: Medium | If triggered: forces scope/schedule tradeoff decision |
| MON-03 | (Conditional) Compliance audit scheduled earlier than expected — only appears if PLAN-04 triggered | Regulatory body notification | 50% | Schedule: Medium, Cost: High | No further cascade |

**No hidden risks in Monitoring.** The player has enough to manage with active and cascaded risks. The focus here is on portfolio management and stakeholder communication, not discovery.

**The Stakeholder Pressure mechanic:**

Monitoring introduces a mandatory conversation with Dana that occurs at the start of the phase, before the player addresses any risks. Dana asks direct questions about the project, and the player's response options are shaped by actual project state.

Example conversation flow:

If Schedule Health is "Slipping":

> **Dana:** "I've been looking at the timeline. We're supposed to launch in 6 weeks and it looks like we're behind. What's going on?"
>
> **Player options:**
> - (If the player mitigated relevant risks): "We hit a delay on [specific risk], but we had a backup plan in place. Here's how we're recovering." → Trust: stable or slight increase
> - (If the player accepted and it triggered): "We had an issue with [specific risk] that we chose to accept. It materialized and cost us [X weeks]. Here's our recovery plan." → Trust: slight decrease (honest but shows the gamble didn't pay off)
> - (Regardless of state): "Everything's under control, don't worry." → Trust: significant decrease if things are NOT under control (Dana can see the dashboard; dishonesty is punished)

The key teaching moment: **transparency with stakeholders is a risk management strategy.** A player who communicates honestly about problems and shows they have a plan maintains trust even when things go wrong. A player who deflects or hides problems loses trust rapidly — and lost trust limits their options in Closing.

If the player identified EXEC-H1 (competitor pressure) and prepared for it, they have an additional response option: "I'm aware of FinanceForward's moves. Here's our competitive positioning..." This shows Dana the player is proactive, which increases trust.

**Player actions in Monitoring:**

1. Mandatory stakeholder conversation with Dana
2. Review all active risks — both new and ongoing from previous phases
3. Reassess and potentially reallocate resources based on what's triggered and what hasn't
4. Address new risks with diminished resources (less budget, less capacity)
5. Make hard tradeoff decisions — this is where the player might have to let a Campfire burn because they need all remaining resources for a Wildfire
6. Confirm phase completion — triggers final resolution rolls before Closing

**NPCs available in Monitoring:**

| Character | Role | Information they provide |
|-----------|------|------------------------|
| Dana (CEO) | Mandatory conversation | Stakeholder pressure, project status accountability |
| Jordan (Senior Developer) | Available for investigation | Technical status, team morale, capacity assessment |
| Alex (QA Lead) | Available for investigation | Quality status, testing coverage, defect trends |

### 3.4 — Phase 4: Closing

**Narrative context:** The launch is imminent. Remaining risks must be resolved, accepted, or escalated. The player makes final decisions about what to deliver and how to handle outstanding issues.

**Phase resources:**
- Contingency budget: Whatever remains
- Team capacity: 8 person-weeks (further reduced — crunch time, team fatigue)

**Risks in this phase:**

No new risks are introduced. Closing is about resolving what's open:

- Any risks still in "Active" or "Response Planned" status need final disposition
- The player reviews each open risk and chooses: resolve (confirm the response worked), accept residual risk (acknowledge it remains but proceed), or escalate (flag it as a known issue for post-launch)
- Each disposition choice affects the final project outcome

**Final decisions:**

Before the project closes, the player faces 2-3 strategic decisions that force explicit tradeoffs. These are not risk assessments — they are project management judgment calls shaped by the risk landscape.

**Decision 1 — Launch scope:**
"The launch date is [X days away]. Given the current state of the project, what do you deliver?"
- Option A: Full feature set — all originally planned features, but quality may be compromised if Quality Health is low
- Option B: Core features only — cut nice-to-haves, but ensure core features are solid
- Option C: Request a 2-week delay — deliver everything at high quality, but miss Dana's market window

The "correct" choice depends entirely on project state. If Quality Health is "On Track," Option A is viable. If Schedule is "Critical," Option C might save the product but damage Trust. If Dana's priority profile is considered, Option B might be the best match (she said she'd rather launch with fewer features than launch late).

**Decision 2 — Outstanding defects:**
"QA has flagged [N] known issues. How do you handle them?"
- Option A: Fix all before launch — costs [X] person-weeks and may delay
- Option B: Fix critical issues only, ship known minor issues with a day-1 patch plan
- Option C: Ship as-is, address in post-launch updates

**Decision 3 — Stakeholder communication:**
"Dana wants a final status briefing before launch. What do you tell her?"
This is a closing conversation where the player's honesty, preparedness, and self-awareness are evaluated. The available dialogue options reflect the actual project state — a player who managed well has confident, evidence-backed options; a player who struggled has harder choices between honesty and optimism.

**Phase resolution:**

No probability rolls in Closing — the project launches based on accumulated state. The game transitions to the Project Outcome sequence (Section 4).

---

## 4. Project Outcome and Debrief

### 4.1 — Project Outcome Simulation

After Closing phase decisions are finalized, an animated sequence shows the SecurePay launch and its immediate aftermath. This is not a cutscene — it's a dynamic narrative generated from the project state.

**The outcome is built from four components:**

**Launch timing:**
- If Schedule Health is "On Track" or better: "SecurePay launches on the target date. Dana's team beats FinanceForward to market."
- If Schedule Health is "Slipping": "SecurePay launches one week late. FinanceForward is already live, but SecurePay's feature set is competitive."
- If Schedule Health is "Critical" and the player didn't choose to delay: "SecurePay launches three weeks late. FinanceForward has captured early adopters."

**Product quality:**
- If Quality Health is "On Track" or better: "The app runs smoothly. User reviews are positive. No critical bugs reported in the first week."
- If Quality Health is "Declining": "Users report intermittent issues with payment processing. The team scrambles to push a hotfix."
- If Quality Health is "Critical": "A critical security vulnerability is discovered on day two. The app is pulled from the store for emergency patching. Media coverage is negative."

**Financial result:**
- Based on Budget Health: how much of the contingency was spent, whether the project stayed within acceptable bounds.

**Stakeholder relationship:**
- Based on Stakeholder Trust: Dana's reaction, whether the relationship continues, whether the team is trusted with future projects.

The four components combine into a narrative outcome that feels personal to the player's journey. No two playthroughs should produce identical outcome text.

### 4.2 — Comprehensive Debrief

After the outcome sequence, the game presents the most important teaching element of Layer 2: a full project retrospective.

**The debrief walks through the entire project timeline in four sections:**

**Section 1 — Risk Register Review:**
Every risk the player encountered is listed with:
- The player's assessment (probability, impact, category)
- The response strategy chosen
- Whether the risk triggered
- What actually happened
- A comparison to the "optimal" response (framed as "here's another approach that could have worked" — never "you were wrong")

**Section 2 — Cascade Map:**
A visual diagram showing how triggered risks spawned or modified other risks. The player sees the chain of consequences from their decisions. Lines connect risks that influenced each other, with annotations explaining each link. This teaches systemic thinking — risks don't exist in isolation.

**Section 3 — Decision Tracing:**
For each health dimension that ended below "On Track," the game traces backward to identify the 2-3 decisions that most contributed to the decline. Each trace uses the Ripple Effect animation:
"Schedule Health ended at 'Slipping.' Here's why: In Planning, you accepted PLAN-02 (API delay) without mitigation. It triggered in Execution, adding 3 weeks. Then in Monitoring, the cascaded risk MON-01 consumed 4 person-weeks of capacity you needed for feature completion."

This is the moment where the player connects their choices to outcomes — the core learning experience of Layer 2.

**Section 4 — Lessons Learned:**
3-5 key lessons derived from the player's specific playthrough. These are not generic tips — they reference the player's actual decisions:
- "You consistently investigated before deciding — this led to better strategy choices, especially with PLAN-01 where Jordan's information changed the optimal response."
- "You allocated 60% of your contingency budget in Planning, leaving little room for Execution risks. Consider reserving at least 30% of contingency for later phases."
- "You missed the hidden risk about team morale (PLAN-H1). When it triggered in Execution, it compounded with the developer departure to create a quality spiral."

**Debrief mechanics:**

The debrief uses the same explanation mechanics from Layer 1:
- Cause → Event → Effect chains for individual risk outcomes
- Ripple Effect animations for cascade tracing
- Evidence Columns for "why this probability/impact was what it was"

This continuity reinforces the frameworks — the player sees the same visual language applied to their own decisions, connecting theory (Layer 1) to practice (Layer 2).

### 4.3 — Performance Summary

After the debrief, a final summary screen shows:

**Project Outcome Grade:**
Not a letter grade or numeric score — a descriptive outcome label based on the four health dimensions at project end:

| Outcome Label | Condition |
|---------------|-----------|
| "Exceptional Delivery" | All four dimensions On Track or better |
| "Successful Launch" | No dimension at Critical, at most one at its second-lowest state |
| "Troubled Delivery" | One dimension at Critical, or two at second-lowest |
| "Project Rescued" | Two dimensions at Critical but project still launched |
| "Project Failed" | Failure condition triggered (see Section 5) |

**Dimension-specific outcomes:** Each health dimension gets a one-line summary tied to the narrative outcome.

**Key statistics:**
- Risks identified: X out of Y available (including hidden risks)
- Risks mitigated successfully: X
- Risks that triggered: X
- Investigations conducted: X out of Y available
- Resources remaining: $X budget, X person-weeks unused

---

## 5. Failure Conditions

### Philosophy

Failure is educational, not punitive. A player who fails and sees the debrief learns more than a player who coasted through safely. Failure should always be traceable to player decisions, never to pure bad luck.

### Trigger Conditions

The project enters a failure state when any of the following occur:

**Condition 1 — Dual Critical:** Two or more health dimensions reach "Critical" simultaneously at the end of any phase resolution.

**Condition 2 — Trust Collapse:** Stakeholder Trust reaches "Lost Confidence" while any other dimension is at its lowest non-critical state or below.

**Condition 3 — Budget Exhaustion:** Contingency budget reaches zero AND a new risk triggers that requires budget to address (the player literally cannot respond).

### Failure Sequence

When a failure condition is met:

1. An emergency event triggers — Dana calls an urgent meeting
2. A scripted conversation plays where Dana explains her decision (cancel the project, bring in a different PM, restructure significantly)
3. The conversation is not hostile — Dana is disappointed but professional. The tone is "let's understand what happened" not "you failed"
4. The full debrief plays (identical to Section 4.2) with an additional section: **"The Breaking Point"** — identifying the exact moment the project became unrecoverable and the 2-3 decisions that led to it
5. The player is offered two options:
   - **Restart Layer 2** from the beginning with all Layer 1 knowledge intact
   - **Restart from Phase 2** (Execution) with Planning decisions preserved — available only if the failure occurred in Monitoring or Closing, giving the player a chance to change their mid-project decisions without redoing the entire plan

### Fairness Safeguards

To ensure failure feels fair:

- No single risk trigger can move any dimension from "On Track" to "Critical" in one step
- The probability system is tuned so that a player who assessed and responded to all visible risks has a low chance of cascading failure from bad luck alone
- At least one risk per phase has low enough base probability that it serves as "breathing room"
- The hidden risks (PLAN-H1, EXEC-H1) are never the sole cause of failure — they contribute to decline but don't independently trigger failure conditions
- If the player is approaching failure (any dimension at one step above Critical), the dashboard pulses or highlights to draw attention, and available NPCs may proactively warn the player in their next conversation

---

## 6. NPC Roster for Layer 2

### Returning Characters

| Character | Role | Phases Active | Dialogue Volume |
|-----------|------|--------------|----------------|
| Dana (CEO of SecurePay) | Client and primary stakeholder | All phases — brief check-ins in Planning and Execution, mandatory conversation in Monitoring, final briefing in Closing | 3-4 exchanges per appearance |
| Jordan (Senior Developer) | Technical lead and team voice | All phases — available for investigation | 2-3 exchanges per phase |
| Alex (QA Lead) | Quality perspective | Execution, Monitoring — available for investigation | 2-3 exchanges per phase |

### New Characters

| Character | Role | Phases Active | Dialogue Volume | Purpose |
|-----------|------|--------------|----------------|---------|
| Sam (Vendor Contact) | Third-party API vendor representative | Planning, Execution | 2-3 exchanges per phase | Provides information on PLAN-02 (API readiness), reveals vendor reliability, adds external dependency perspective |
| Morgan (Project Sponsor) | Senior executive who approved the project | Monitoring, Closing | 2 exchanges per phase | Adds organizational pressure perspective, asks about budget justification, provides contrast to Dana's priorities |
| Ravi (Junior Developer) | Newest team member | Execution, Monitoring | 2 exchanges per phase | Ground-level perspective on team morale, workload, and quality issues. Source of hints for hidden risks related to team dynamics |

All new characters are designed with minimal dialogue trees. Each has a specific informational function — they exist to give the player investigation targets, not to be fully fleshed-out NPCs. Expansion of their dialogue is possible in future iterations.

---

## 7. Data Requirements

### Scenario Data Structure

Each risk in Layer 2 requires a richer data structure than the current JSON schema. The new schema per risk:

```
{
    "id": "PLAN-01",
    "title": "Lead developer may leave for competitor offer",
    "phase": "planning",
    "source_type": "auto",
    "source_description": "Jordan mentions in team briefing",
    "base_probability": 60,
    "impact": {
        "budget": 15,
        "schedule": 25,
        "quality": 10,
        "stakeholder_trust": 5
    },
    "investigation": {
        "npc": "jordan",
        "reveals": "Developer has received an offer but hasn't decided yet. Retention bonus or role change could help.",
        "modifies_assessment": {
            "probability_adjustment": -10,
            "recommended_strategy": "mitigate"
        }
    },
    "response_options": {
        "avoid": {
            "description": "Restructure the project to remove dependency on this developer",
            "cost_budget": 5000,
            "cost_capacity": 3,
            "probability_after": 0,
            "impact_reduction": {},
            "tradeoff_note": "Eliminates the risk but costs significant capacity and may affect team dynamics"
        },
        "mitigate": {
            "description": "Offer retention incentives and cross-train a backup developer",
            "cost_budget": 15000,
            "cost_capacity": 2,
            "probability_after": 25,
            "impact_reduction": { "schedule": -10, "quality": -5 },
            "tradeoff_note": "Reduces probability significantly. Even if triggered, cross-training limits the damage."
        },
        "transfer": {
            "description": "Contract a staffing agency to have a qualified replacement on standby",
            "cost_budget": 20000,
            "cost_capacity": 1,
            "probability_after": 60,
            "impact_reduction": { "schedule": -15, "quality": -5 },
            "tradeoff_note": "Doesn't prevent the departure but ensures rapid replacement. Cost is higher upfront."
        },
        "accept": {
            "description": "Acknowledge the risk and prepare documentation for knowledge transfer",
            "cost_budget": 0,
            "cost_capacity": 1,
            "probability_after": 60,
            "impact_reduction": { "schedule": -5 },
            "tradeoff_note": "Cheapest option. Documentation helps but doesn't prevent schedule damage if they leave."
        }
    },
    "if_triggered": {
        "spawns": ["EXEC-03"],
        "modifies": [],
        "health_impact": {
            "budget": -15,
            "schedule": -25,
            "quality": -10,
            "stakeholder_trust": -10
        },
        "narrative": "The lead developer accepted the competitor's offer and gave two weeks' notice. The team is shaken, and critical knowledge about the payment module architecture is at risk."
    },
    "if_resolved": {
        "health_impact": {
            "stakeholder_trust": 5
        },
        "narrative": "The lead developer decided to stay. Your proactive approach paid off."
    },
    "debrief": {
        "optimal_strategy": "mitigate",
        "explanation": "Given Dana's low schedule tolerance, investing $15K in retention and cross-training is the best cost-to-protection ratio. The developer's departure would cascade into schedule and quality issues that cost far more than $15K to address."
    }
}
```

### New fields needed in GameManager.gd

```
# Layer 2 state
var risk_register: Array = []
var active_phase: String = "planning"
var contingency_budget: int = 0
var phase_capacity: int = 12

# Project Health (internal numeric values, 0-100)
var health_budget: int = 100
var health_schedule: int = 100
var health_quality: int = 100
var health_stakeholder_trust: int = 100

# Health state thresholds (expandable)
# These thresholds map internal values to display states
# Base states use 3 tiers; expanded states use 5 tiers
var health_thresholds: Dictionary = {
    "base": {
        "on_track": 60,
        "strained": 30,
        "critical": 0
    }
}

# Investigation tracking
var investigations_conducted: int = 0
var investigations_available: int = 0
var hidden_risks_found: int = 0
var hidden_risks_total: int = 0

# Phase history
var phase_results: Array = []

# Failure tracking
var failure_triggered: bool = false
var failure_condition: String = ""
var failure_phase: String = ""
```

### New Scenes Required

| Scene | Purpose |
|-------|---------|
| `RiskRegisterPanel.tscn` | Persistent HUD panel for the risk register |
| `RiskEntryCard.tscn` | Individual risk entry within the register (reusable) |
| `HealthDashboard.tscn` | Project Health Dashboard HUD element |
| `PhaseResolution.tscn` | Phase-end probability roll and consequence sequence |
| `ResourceAllocationUI.tscn` | Interface for assigning budget and capacity to risk responses |
| `StakeholderConversation.tscn` | Specialized conversation scene for Dana's mandatory check-ins |
| `ProjectOutcome.tscn` | End-of-project narrative sequence |
| `DebriefScreen.tscn` | Comprehensive debrief with cascade map and decision tracing |
| `CascadeMap.tscn` | Visual diagram component showing risk interaction chains |
| `FailureSequence.tscn` | Emergency meeting and breaking point analysis |

Note: Several Layer 1 scenes are reused in Layer 2 — `NPCDialogue.tscn`, `RippleEffect.tscn`, `CauseEventEffectChain.tscn`, `EvidenceColumns.tscn`, `RiskMatrix.tscn`, and `ClientProfileCard.tscn`. These do not need to be rebuilt.

---

## 8. Transition to Layer 3

When Layer 2 is complete (either through successful project delivery or through the failure-and-retry cycle), the following carries forward:

- The **risk register** persists as a mechanic but resets its contents for Layer 3's new scenarios
- The **Project Health Dashboard** remains the primary feedback mechanism
- The **conversation system** continues with the same NPC interaction patterns
- The **resource system** carries the same structure but Layer 3 adjusts starting values and constraints for increased difficulty
- The player's **Layer 2 performance summary** is stored and can optionally influence Layer 3's starting conditions or available hints
- The **debrief mechanics** remain but with reduced scaffolding — Layer 3 debriefs are shorter and assume the player understands the frameworks

Layer 3 introduces:
- Higher risk density and complexity
- Risk interactions that cross multiple dimensions simultaneously
- Reduced resources and tighter constraints
- Fewer hints and less guidance
- The expectation that the player can manage independently

Layer 3 design will be documented separately.
