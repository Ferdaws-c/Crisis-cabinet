# Crisis Cabinet — Layer 1 Design Document
## "The Training Wing"

**Document version:** 1.0  
**Date:** April 22, 2026  
**Game engine:** Godot 4.4 (GDScript)  
**Project context used throughout Layer 1:** SecurePay — a mobile banking app for a mid-sized fintech company, with a 4-month deadline and a $200K budget.

---

## 1. Layer 1 Overview

### Purpose

Layer 1 is the player's first experience after the main menu. Its job is to take a player who knows nothing about risk management and teach them five foundational concepts through interactive, consequence-driven gameplay — not text walls or slideshows.

By the end of Layer 1, the player should understand:

- What a project risk is (and what it isn't)
- How to assess probability using evidence-based reasoning
- How to assess impact across four dimensions, weighted by client priorities
- How the risk matrix works and what the four severity categories mean
- What the four PMBOK response strategies are, when to use each, and how to investigate a risk before responding
- How all five skills combine in a full risk assessment cycle

### Design Principles

1. **Experience before terminology.** The player encounters the situation first, then the concept is named afterward. Never lead with a definition.
2. **No flat text blocks.** Every explanation uses one of four visual explanation mechanics (defined in Section 8). If it can't be shown visually or interactively, it doesn't belong in Layer 1.
3. **Consequence is the teacher.** Where possible, the player sees the result of their choices — correct or incorrect — play out before receiving an explanation.
4. **One concept per station.** Each station has a single learning objective. Stations build on each other sequentially.
5. **Consistent project context.** All stations reference the same project (SecurePay) so the player builds cumulative familiarity with the scenario rather than context-switching.

### Physical Layout in the Game

Layer 1 occupies a dedicated area of the facility map — the "Training Wing" — positioned between the main menu spawn point and the first risk room. It consists of a corridor with six stations arranged sequentially. Each station is gated: the player cannot proceed to the next station until they complete the current one. The visual design of the corridor should feel like an onboarding area — clean, well-lit, with signage or floor markings guiding the player forward.

The gating mechanism reuses the existing `RoomDoor.gd` system, but instead of phase-based unlocking, doors unlock on station completion flags stored in `GameManager.gd`.

### Completion Criteria

Layer 1 is complete when the player finishes all six stations. Upon completion:

- A flag `layer1_complete` is set in `GameManager.gd`
- The door to the first risk room (Layer 2) unlocks
- The player's training performance is logged (not scored punitively — this is learning, not evaluation)

---

## 2. Station 1 — "What Is a Risk?"

### Learning Objective

The player learns to distinguish genuine project risks from general problems, inconveniences, or certainties. They learn that a risk has three components: a cause, an uncertain event, and an impact on at least one project objective (scope, time, cost, quality).

### Project Context

The player has just been assigned as project manager for SecurePay. A short on-screen introduction sets the stage: "You've just been made PM for SecurePay — a mobile banking app that needs to launch in 4 months with a $200K budget. Your first job: figure out what could go wrong."

### Interaction Flow

**Step 1 — Identification exercise.**

Five statements appear one at a time on a display board or screen within the game world. For each, the player presses one of two buttons: "Project Risk" or "Not a Risk."

The five statements:

| # | Statement | Correct Answer | Why |
|---|-----------|---------------|-----|
| 1 | "The lead developer has been interviewing at other companies." | Risk | Uncertain event (may leave), impacts schedule and quality |
| 2 | "The office Wi-Fi was slow yesterday." | Not a Risk | Past event, no ongoing project impact, not uncertain |
| 3 | "The client's CEO mentioned they might want to add cryptocurrency support." | Risk | Uncertain scope change, impacts cost, schedule, and scope |
| 4 | "The team uses a programming language none of them have used before." | Risk | Increases probability of defects and delays, impacts quality and schedule |
| 5 | "The government already passed a new banking data regulation that takes effect in 2 months." | Not a Risk | Not uncertain — it's a certainty. It's a constraint or issue to manage, not a risk |

**Step 2 — Explanation after each answer.**

Regardless of whether the player answers correctly, the explanation triggers using the **Cause → Event → Effect Chain** mechanic (see Section 8.1).

For risks (correct = "Project Risk"):

- Three animated panels appear in sequence.
- Panel 1 (Cause): the underlying condition. Example: "Developer is dissatisfied and exploring options."
- Panel 2 (Event): the uncertain occurrence. Example: "Developer resigns mid-sprint."
- Panel 3 (Effect): the project impact. Example: "3 weeks of knowledge lost. Replacement hiring adds $15K and 4 weeks to the schedule."
- A concluding line appears beneath: "This is a risk because the event is uncertain and the effect touches project objectives — in this case, cost and schedule."

For non-risks (correct = "Not a Risk"):

- The chain still appears, but Panel 3 shows no meaningful project impact, or Panel 2 shows no uncertainty.
- Example for the Wi-Fi statement: Panel 1: "ISP had a service interruption." → Panel 2: "Wi-Fi was slow for a few hours." → Panel 3: "No measurable impact on project deliverables, timeline, or budget."
- Concluding line: "This already happened and didn't affect the project. A risk looks forward at uncertain events that could change your project's outcome."

For statement 5 (the regulation — the trickiest one):

- Panel 1: "Government regulation passed." → Panel 2: "Regulation takes effect — this WILL happen, there is no uncertainty." → Panel 3: "You must comply. This is a constraint, not a risk."
- Concluding line: "If it's guaranteed to happen, it's not a risk — it's a fact you plan around. Risks live in the space of 'might happen.' However, the risk might be: 'We might not achieve compliance in time.'"
- A secondary chain then shows the actual risk version: "Team unfamiliar with new regulation" → "Compliance features built incorrectly" → "App fails regulatory review, launch delayed."

**Step 3 — Summary moment.**

After all five statements, a brief visual summary fades in — three icons representing Cause, Event, and Effect with a connecting arrow, and the sentence: "A project risk = an uncertain event, rooted in a cause, that could affect your project's scope, time, cost, or quality."

The player presses Continue. The door to Station 2 unlocks.

### Completion Criteria

- Player has answered all 5 statements.
- All explanations have been shown (player cannot skip explanations).
- Flag `station_1_complete` set in GameManager.

---

## 3. Station 2 — "Probability"

### Learning Objective

The player learns to assess how likely a risk is to occur using evidence and project context, not gut feeling. They learn that probability sits on a spectrum and that certain factors increase or decrease it.

### Interaction Flow

**Step 1 — Introduction.**

A short contextual prompt: "Now that you know what risks look like on SecurePay, let's figure out which ones are most likely to actually happen."

**Step 2 — Drag-and-place exercise.**

A horizontal scale appears on screen with three zones: Low, Medium, High. Five risk events appear as draggable cards. The player drags each card to the zone they think is correct.

The five risks:

| # | Risk Event | Correct Zone | Key Evidence |
|---|-----------|-------------|-------------|
| 1 | "A meteor destroys the data center." | Low | Statistically near-impossible; included to calibrate the low end |
| 2 | "The client requests scope changes after the first demo." | High | Industry data shows this happens in ~70-80% of IT projects |
| 3 | "A critical third-party API has breaking changes in a new release." | Medium | Common but unpredictable; depends on vendor release cycles |
| 4 | "A key team member takes extended sick leave." | Medium | Possible for any team; neither certain nor negligible |
| 5 | "The project goes over budget." | High | Industry stats show majority of IT projects exceed initial budgets |

**Step 3 — Evidence-based explanation after each placement.**

After the player places each card, the explanation triggers using the **Evidence Columns** mechanic (see Section 8.2).

Two columns animate in side by side:

- Left column header: "Makes it MORE likely"
- Right column header: "Makes it LESS likely"

Each column fills in with 2-3 bullet points specific to the risk and the SecurePay project context.

Example for Risk #2 (scope changes after demo):

| Makes it MORE likely | Makes it LESS likely |
|---------------------|---------------------|
| Client hasn't seen working software yet | Requirements document was signed off |
| Banking apps have complex compliance layers that surface late | (noted as weak evidence on its own) |
| First demos almost always generate feedback and changes | |

Concluding line: "In IT projects, significant scope change requests after the first client demo happen more often than not. Historical patterns and the specific conditions of SecurePay both point to High probability. Key lesson: probability assessment should be driven by evidence and historical patterns, not instinct."

For the meteor risk, the "less likely" column is overwhelmingly full, making the point visually obvious and slightly humorous — teaching the player that not all risks deserve attention.

**Step 4 — Debrief.**

After all five placements, a brief animation shows the five risks ordered from lowest to highest probability with their evidence summaries compressed into single lines. The player sees the full spectrum and how evidence supports each position.

Concluding message: "Probability isn't a guess — it's a judgment built on evidence. When you assess risk in a real project, you'll look at historical data, team experience, project conditions, and industry patterns."

### Completion Criteria

- Player has placed all 5 risks.
- All evidence explanations have been viewed.
- Flag `station_2_complete` set in GameManager.

---

## 4. Station 3 — "Impact and Client Priorities"

### Learning Objective

The player learns that impact has four dimensions (cost, schedule, quality, scope), that the same risk can hit multiple dimensions, and — critically — that different clients weight these dimensions differently. Impact assessment is always relative to stakeholder priorities.

### Interaction Flow

**Step 1 — Meet the client.**

Before any impact assessment, the player encounters an NPC — the SecurePay client, "Dana, CEO of SecurePay." A light branching conversation begins.

The conversation is 3-4 exchanges where the player chooses what to ask. The purpose is for the player to extract the client's priorities through dialogue rather than being told directly.

Example conversation flow:

> **Player choice 1:** "What does success look like for SecurePay?"
>
> **Dana:** "Simple — we need to be live before FinanceForward launches their app in March. If we're second to market, the whole project might as well not exist."

> **Player choice 2:** "How flexible is the budget?"
>
> **Dana:** "We just closed a funding round. Money isn't the issue — time is. I'd rather spend an extra $50K and launch on time than save money and lose the window."

> **Player choice 3:** "What about feature completeness?"
>
> **Dana:** "Core features must work perfectly — payments, transfers, account management. The nice-to-haves? Those can wait for v2. I'd rather launch with fewer features than launch late with everything."

> **Player choice 4:** "How important is security and quality to you?"
>
> **Dana:** "It's banking. If there's a security breach in month one, we're finished. Quality on core features is non-negotiable."

**Step 2 — Build the client profile card.**

After the conversation, a blank **stylized profile card** appears — designed like a strategy game character card. It has Dana's avatar at the top, the company name, and four empty stat bars:

- Budget Tolerance: [empty bar]
- Schedule Flexibility: [empty bar]
- Quality Standards: [empty bar]
- Scope Flexibility: [empty bar]

The player fills in each bar by setting a level (Low / Medium / High) based on what Dana said in the conversation.

Correct profile for Dana/SecurePay:

- Budget Tolerance: **High** (she explicitly said money isn't the issue)
- Schedule Flexibility: **Low** (hard market deadline, schedule is her top concern)
- Quality Standards: **High** (banking security is non-negotiable — meaning quality standards are strict, so tolerance for quality hits is Low, but the "standards" bar is High)
- Scope Flexibility: **High** (she's willing to cut nice-to-haves)

Important design note on the stat bars: the bars represent how much tolerance the client has in each dimension. High budget tolerance = they can absorb cost overruns. Low schedule flexibility = schedule hits are devastating.

If the player sets a bar incorrectly, the game highlights the relevant conversation line: "Remember what Dana said: 'Money isn't the issue — time is.' That suggests her budget tolerance is high, not low."

The completed profile card remains visible in the corner of the screen for the remainder of Station 3. In Layer 2, different scenarios may introduce different clients with different profiles.

**Step 3 — Impact assessment exercise.**

Three risks appear (drawn from the same pool used in Stations 1-2 for continuity). For each risk, the player sees four dimension sliders:

- Cost Impact: None / Low / Medium / High
- Schedule Impact: None / Low / Medium / High
- Quality Impact: None / Low / Medium / High
- Scope Impact: None / Low / Medium / High

The player rates each dimension independently.

The three risks:

**Risk A — "Lead developer resigns."**

Expected ratings:
- Cost: Medium (recruitment + onboarding ≈ $30K)
- Schedule: High (6-week ramp-up for replacement, knowledge transfer gap)
- Quality: Medium (new developer doesn't know codebase, early defect rate increases)
- Scope: Low-Medium (some features might be simplified but core scope is maintainable)

**Risk B — "Third-party payment API delayed by 3 weeks."**

Expected ratings:
- Cost: Low (no direct cost, but delay may cause indirect costs)
- Schedule: High (payment integration is on the critical path)
- Quality: Low (API quality is the vendor's problem)
- Scope: Medium (may need to launch without some payment features)

**Risk C — "Compliance review reveals that the app needs additional security features."**

Expected ratings:
- Cost: Medium-High (new security features require development time and possibly third-party tools)
- Schedule: Medium (additional work, but compliance is non-negotiable so schedule absorbs it)
- Quality: None/Low (this actually improves quality)
- Scope: Low (scope increases, which isn't a "hit" but is a change to manage)

**Step 4 — Ripple effect explanation.**

After each risk assessment, the explanation triggers using the **Ripple Effect Animation** mechanic (see Section 8.3).

The game plays out the consequence chain for that risk, showing how impact cascades across dimensions in sequence.

Example for Risk A (developer resigns):

- Ripple 1: "Developer leaves. Immediate knowledge gap." → Schedule +3 weeks
- Ripple 2: "You post the job. Recruitment takes 2 weeks, costs $8K." → Cost +$8K
- Ripple 3: "New developer starts. Onboarding and codebase learning: 4 weeks at reduced output." → Schedule +4 weeks, Quality temporarily reduced
- Ripple 4: "Under time pressure, some features are simplified." → Scope adjusted

After the ripple sequence, the player's original ratings are compared to the actual cascade. Where they under- or over-estimated, the game highlights the gap and explains: "You rated cost as Low, but the ripple shows recruitment, onboarding, and reduced productivity add up to roughly $30K — that's Medium for a $200K project."

**Step 5 — The priority lens.**

After the player has seen the ripple effects, the game introduces the critical insight: "But how bad is this really? That depends on the client."

The client profile card (Dana's card) pulses or highlights. The game overlays the impact ratings with Dana's tolerance levels:

- Cost impact: Medium — but Dana's budget tolerance is High → "This hurts, but Dana can absorb it."
- Schedule impact: High — and Dana's schedule flexibility is Low → "This is a critical threat. Dana cannot afford schedule slips."

A visual indicator (such as a color shift or warning icon) shows which impacts are "tolerable" vs. "critical" given the client profile. The concluding message: "The same risk on a different project — one with a tight budget but a flexible deadline — would flip entirely. Impact assessment without knowing your stakeholder's priorities is incomplete."

**Step 6 — Contrast exercise (optional but recommended).**

To drive the point home, the game briefly shows a second client profile card — a government agency with the opposite priorities (Low budget tolerance, High schedule flexibility, Very High quality standards, Low scope flexibility). The player sees how Risk A's impact ratings would be interpreted completely differently: suddenly cost is the critical dimension, and schedule is tolerable. No new interaction required — this is a 15-second visual comparison that makes the lesson concrete.

### Completion Criteria

- Player has completed the conversation with Dana.
- Player has correctly filled in the client profile card (with correction feedback if needed).
- Player has assessed all 3 risks across all 4 dimensions.
- All ripple effect explanations have been viewed.
- Priority lens comparison has been shown.
- Flag `station_3_complete` set in GameManager.

---

## 5. Station 4 — "The Risk Matrix"

### Learning Objective

The player learns how probability and impact combine into a severity classification using a 2×2 risk matrix. They learn the four severity categories (using the fire metaphor system) and understand the strategic meaning of each category — not just its label, but what it tells you about how to prioritize.

### The Fire Metaphor System

The four quadrants of the risk matrix use fire-based metaphors instead of the original Tusler animal categories. The mapping:

| | Low Impact | High Impact |
|---|---|---|
| **High Probability** | **Campfire** | **Wildfire** |
| **Low Probability** | **Spark** | **Volcano** |

Visual and strategic identity of each:

**Wildfire (High Probability, High Impact)**
- Visual: Spreading, aggressive fire consuming a landscape
- Color: Deep red / orange
- Strategic meaning: Immediate, aggressive action required. These risks are almost certain to happen and will cause serious damage. Ignoring a Wildfire guarantees project failure. Always your top priority.

**Volcano (Low Probability, High Impact)**
- Visual: Dormant mountain with a faint glow at the summit
- Color: Dark orange / amber
- Strategic meaning: Dormant but catastrophic if it erupts. You might go the whole project without it triggering — but if it does, recovery is extremely difficult. Always have a contingency plan, even if you don't actively mitigate.

**Campfire (High Probability, Low Impact)**
- Visual: Small controlled fire in a ring of stones
- Color: Yellow / warm amber
- Strategic meaning: Constantly burning, but manageable. These risks will happen repeatedly — minor delays, small bugs, routine scope questions. Individually they're small, but if you let too many campfires burn unattended, the smoke (cumulative effect) becomes a problem. Manage them efficiently without over-investing.

**Spark (Low Probability, Low Impact)**
- Visual: A single small spark that flickers and fades
- Color: Light yellow / gray
- Strategic meaning: Barely worth worrying about. Log it, note it, move on. Spending significant resources on Sparks means you're taking budget and attention away from Wildfires and Volcanoes.

### Interaction Flow

**Step 1 — The empty matrix.**

The player sees a 2×2 grid on a large display board in the game world. The axes are labeled (Probability on the vertical axis, Impact on the horizontal axis), but the quadrants are blank — no labels, no colors, no icons.

**Step 2 — Risk placement exercise.**

Four risks appear as cards (drawn from Stations 1-3 so the player already has context). The player drags each one onto the quadrant they believe is correct, based on the probability they assessed in Station 2 and the impact they assessed in Station 3.

The four risks and their correct placements:

| Risk | Probability | Impact (given Dana's priorities) | Quadrant |
|------|------------|--------------------------------|----------|
| Client requests scope changes after first demo | High | Low (Dana has high scope flexibility) | Campfire |
| Lead developer resigns | Medium-High | High (schedule impact is critical for Dana) | Wildfire |
| Meteor destroys data center | Low | High | Volcano |
| Project goes slightly over initial budget estimate | High | Low (Dana has high budget tolerance) | Campfire |

Note: Some risks may sit on borders between quadrants. When this happens, the game acknowledges the ambiguity: "This risk sits between Campfire and Wildfire — reasonable people might classify it either way. When in doubt in real projects, round up — treat borderline cases as the more severe category."

**Step 3 — Category reveal and character introduction.**

After the player places each risk, the correct quadrant lights up with its fire visual and color. A short animated vignette (3-5 seconds) plays showing the fire metaphor in action, and the category's strategic meaning appears as a brief spoken or displayed message.

The explanation mechanic here is the **Character-Driven Metaphor** format (see Section 8.4), adapted for fire instead of animals:

**Wildfire reveal:** The quadrant ignites with spreading flames. Message: "This is a Wildfire — it's already spreading, and it burns everything in its path. In your project, this means it's likely to happen and will hit where it hurts most. You deal with Wildfires first, aggressively, and with real resources. Never ignore a Wildfire."

**Volcano reveal:** The quadrant shows a dormant mountain with a rumble. Message: "This is a Volcano — quiet right now, maybe for the whole project. But if it erupts, the damage is massive and recovery is slow. You can't prevent a Volcano, but you can prepare. Always have a contingency plan for these."

**Campfire reveal:** The quadrant shows a small, steady fire in a stone ring. Message: "This is a Campfire — always burning, never dangerous on its own. Small delays, minor cost bumps, routine issues. Manage them with lightweight processes and don't over-invest. But watch out — too many unattended Campfires create smoke that obscures your view of real threats."

**Spark reveal:** The quadrant shows a brief flicker that fades. Message: "This is a Spark — might ignite, probably won't, and even if it does, it's small. Log it and move on. The biggest risk with Sparks is wasting time on them when Wildfires need your attention."

**Step 4 — Misplacement correction.**

If the player places a risk in the wrong quadrant, the game references their earlier assessments: "In Station 2, you assessed this risk's probability as High. In Station 3, you saw its schedule impact is critical for Dana. High probability + high impact = Wildfire, not Campfire."

The risk card visually slides to the correct quadrant, and the corresponding fire animation plays.

**Step 5 — Matrix summary.**

Once all four risks are placed, the full matrix is visible with all fire visuals active. A final message: "This is your risk matrix — the single most important tool in risk management. It turns a messy list of worries into a clear priority map. Wildfires first, then Volcanoes, then Campfires, then Sparks. Every risk you encounter from here on out, your first job is to put it on this matrix."

The matrix visual should be designed as a reusable UI element that reappears in the HUD during Layer 2 and Layer 3.

### Completion Criteria

- Player has placed all 4 risks on the matrix.
- All fire metaphor reveals have been shown.
- Any misplacements have been corrected with explanations.
- Flag `station_4_complete` set in GameManager.

---

## 6. Station 5 — "Response Strategies"

### Learning Objective

The player learns the four PMBOK risk response strategies (Avoid, Mitigate, Transfer, Accept), understands what each one does in practice, learns to evaluate tradeoffs between strategies, and experiences how investigating a risk through conversation can change the optimal response.

### Interaction Flow

**Step 1 — Introduction and investigation.**

The player is given a single clear risk: "The third-party payment API might not be ready in time for the SecurePay launch."

Before choosing any strategy, the player is prompted: "Before you decide how to handle this, maybe you should talk to the people involved."

An NPC becomes available — **"Jordan, Senior Developer"** — who has been working with the payment API. The player initiates a branching conversation.

Example conversation tree:

> **Player choice 1a:** "How likely is the API delay?"
>
> **Jordan:** "I talked to the vendor last week. They said they're 'on track,' but they've said that before and missed by three weeks. I'd say 50/50."

> **Player choice 1b:** "Is there an alternative API we could use?"
>
> **Jordan:** "There's PaySecure — it's more expensive but it's stable and available right now. We'd need about two weeks to integrate it."

> **Player choice 2a:** "What happens if we just wait for the original API?"
>
> **Jordan:** "If it comes on time, great — no extra cost. If it doesn't, we're looking at a 3-4 week delay, and that kills our March launch."

> **Player choice 2b:** "Could we build our own payment system?"
>
> **Jordan:** "Technically yes, but that's 6-8 weeks of work and we'd need to handle PCI compliance ourselves. That's a whole different project."

After 3-4 exchanges, the conversation closes. The information the player gathered should inform their strategy choice — but the game doesn't tell them which strategy is "correct" yet.

**Step 2 — Strategy exploration (try all four).**

Four action panels appear, each representing one strategy. The player is required to activate all four — not to choose one, but to see what each one looks like in practice.

For each strategy, the **Ripple Effect Animation** mechanic plays out the consequences:

**Avoid — "Remove the dependency on the external API entirely."**
- Action: Build payment functionality in-house.
- Ripple 1: "6-8 weeks of development added." → Schedule: devastating (launch date missed)
- Ripple 2: "PCI compliance scope added." → Cost: +$60K, Scope: significantly increased
- Ripple 3: "Risk is eliminated — no dependency on any vendor." → Risk: fully removed
- Summary: "The risk is gone, but the cure is worse than the disease for this project. Dana's schedule constraint makes this option impractical."

**Mitigate — "Start integrating the backup API (PaySecure) in parallel."**
- Action: Assign a developer to integrate PaySecure alongside the primary API.
- Ripple 1: "2 weeks of developer time on parallel integration." → Cost: +$15K
- Ripple 2: "If primary API is late, you switch to PaySecure with minimal delay." → Schedule: protected
- Ripple 3: "If primary API arrives on time, the backup work is partially wasted." → Cost: sunk but acceptable
- Summary: "The risk is significantly reduced. You spend money to buy schedule protection — a reasonable trade given Dana's priorities."

**Transfer — "Outsource the entire payment module to a specialist vendor with an SLA."**
- Action: Contract a payment integration firm with guaranteed delivery by a fixed date.
- Ripple 1: "Vendor contract: $40K with delivery guarantee." → Cost: +$40K
- Ripple 2: "Delivery risk shifts to the vendor — if they're late, contract penalties apply." → Schedule: protected (contractually)
- Ripple 3: "You lose direct control over code quality and integration details." → Quality: partially reduced
- Summary: "The risk is transferred but not eliminated. If the vendor fails, contract disputes take time. You've traded project risk for vendor risk."

**Accept — "Monitor the situation and act only if the API is actually late."**
- Action: Do nothing now. Check in with the vendor weekly.
- Ripple 1: "No immediate cost or effort." → Cost: $0, Schedule: unchanged (for now)
- Ripple 2: "If API arrives on time: best outcome — no money or effort wasted." → Positive scenario
- Ripple 3: "If API is late: you're scrambling with no backup. 3-4 week delay likely." → Schedule: potentially devastating
- Summary: "Acceptance is a valid strategy when the risk is low-impact or when response costs exceed the potential damage. Here, the potential schedule damage is severe — pure acceptance is a gamble."

**Step 3 — Informed choice.**

After seeing all four play out, the player is asked: "Now — which strategy would you choose?"

The player selects one. The game responds with a **tradeoff analysis** — not "correct/incorrect" but a reasoned evaluation:

"You chose Mitigate. Given Dana's priorities (low schedule flexibility, high budget tolerance), spending $15K to protect the launch date is a strong match. You're spending in a dimension the client can absorb (cost) to protect a dimension they can't (schedule). However, note that the residual risk isn't zero — if both APIs fail, you'd need a contingency. A thorough PM might pair Mitigate with Accept for the residual risk."

If the player chose Accept: "You chose Accept — which means you're betting the API arrives on time. If it does, this was the most efficient choice. But remember Dana's profile: she has near-zero schedule tolerance. Acceptance means you're gambling with the dimension she cares about most. In practice, most PMs would at least Mitigate alongside Acceptance for a risk this impactful."

If the player chose Avoid: "You chose Avoid — building in-house eliminates the dependency entirely, which is attractive. But look at the ripple: 6-8 weeks of extra work and a missed launch date. For Dana, missing March is project failure. Avoidance works best when the cost of avoidance is less than the cost of the risk itself."

If the player chose Transfer: "You chose Transfer — shifting the risk to a vendor with contractual guarantees. This is a valid and professional approach. The trade-off is cost ($40K) and reduced control over quality. For Dana, the cost is acceptable, but you'll want to monitor the vendor carefully since your quality reputation is still on the line."

**Step 4 — Strategy reference summary.**

A visual summary card appears showing all four strategies with one-line descriptions and a "best used when..." note for each:

- **Avoid:** Change the plan to eliminate the risk. Best when the risk is severe and the plan change is affordable.
- **Mitigate:** Take action to reduce probability or impact. Best when you can reduce the risk to an acceptable level at a reasonable cost.
- **Transfer:** Shift the risk to a third party. Best when someone else can manage the risk better than you, and the cost of transfer is justified.
- **Accept:** Acknowledge the risk and prepare to deal with it if it happens. Best when the risk is low-impact, or when all response options cost more than the potential damage.

This card should be designed as a reusable reference element accessible from the HUD in Layer 2 and Layer 3.

### Completion Criteria

- Player has completed the conversation with Jordan.
- Player has viewed all four strategy ripple sequences.
- Player has made a choice and received the tradeoff analysis.
- Flag `station_5_complete` set in GameManager.

---

## 7. Station 6 — "Putting It All Together"

### Learning Objective

The player completes one full risk assessment cycle independently — from identification through response strategy selection — using all skills learned in Stations 1-5. This station serves as a confidence-building exercise before entering Layer 2 and validates that the player can apply the complete framework.

### Interaction Flow

**Step 1 — New risk introduction.**

A fresh scenario is presented that the player has not seen before. It still relates to the SecurePay project:

"Your QA lead just told you: the automated testing framework isn't compatible with the new mobile OS version that just released. The tests aren't running, and without them, you can't verify that the app works on the latest devices."

**Step 2 — Identification (Station 1 skill).**

The player is asked: "Is this a project risk?"

If they answer correctly (Yes): the game shows a brief Cause → Event → Effect chain and confirms.
If they answer incorrectly (No): the game shows the chain and explains why it qualifies — uncertain event (devices might not work), project impact (quality, schedule, scope).

**Step 3 — Probability assessment (Station 2 skill).**

The player places the risk on the probability scale (Low / Medium / High).

Correct answer: Medium-High. The testing framework incompatibility is confirmed, but the *impact* of the incompatibility (whether the app actually has bugs on the new OS) is uncertain.

The evidence columns appear briefly to confirm or correct.

**Step 4 — Impact assessment (Station 3 skill).**

The player rates the four dimensions. Dana's client profile card is visible for reference.

Expected ratings:
- Cost: Medium (fixing framework + potential rework)
- Schedule: Medium-High (testing is on the critical path)
- Quality: High (can't verify app functionality without tests)
- Scope: Low (scope doesn't change, but delivery confidence drops)

The ripple effect animation plays to confirm or correct.

**Step 5 — Matrix classification (Station 4 skill).**

The risk matrix appears. The player places this risk on it.

Expected placement: **Wildfire** (medium-high probability, high impact on quality which Dana considers non-negotiable for a banking app).

The fire metaphor animation plays for the correct quadrant.

**Step 6 — Investigation and response (Station 5 skill).**

An NPC becomes available — **"Alex, QA Lead."** The player can ask 2-3 questions to gather context:

> **Player:** "How long to fix the testing framework?"
>
> **Alex:** "If we update the framework ourselves, maybe a week. But there might be a new version already in beta that supports the new OS — I haven't checked yet."

> **Player:** "Can we test manually in the meantime?"
>
> **Alex:** "For core features, yes — but it'll take 3x as long and we'll miss edge cases. It's a stopgap, not a solution."

> **Player:** "What if we just don't support the new OS version at launch?"
>
> **Alex:** "We could — but it launched last week and adoption is already at 15%. For a banking app, not supporting the latest OS is a bad look."

After the conversation, the four strategy panels appear. The player chooses one and receives the tradeoff analysis.

**Step 7 — Hint system.**

At each step (identification through response), a "Hint" button fades in after 8 seconds of inactivity. The hint references the relevant station:

- Identification hint: "Think about the three parts — cause, uncertain event, and effect on project objectives."
- Probability hint: "What evidence do you have? What patterns from similar projects apply?"
- Impact hint: "Check all four dimensions. And check Dana's profile — which dimensions matter most to her?"
- Matrix hint: "Where does this risk sit on the probability and impact axes?"
- Response hint: "Remember what you learned from Jordan — investigating first helps. What did Alex tell you?"

**Step 8 — Full debrief.**

After the player completes all steps, a comprehensive debrief screen shows:

1. The Cause → Event → Effect chain for this risk
2. The probability assessment with evidence
3. The impact ratings with ripple effects
4. The matrix placement with the fire category
5. The chosen strategy with tradeoff analysis
6. What the "textbook" response would look like (without calling the player's choice wrong — framed as "here's another perspective")

Final message: "You've just completed a full risk assessment cycle — the same process a real project manager uses every time a new risk is identified. You'll be doing this throughout the rest of the game, but now the stakes will be higher and the risks will be more complex. Ready?"

The door to the first risk room (Layer 2) unlocks.

### Completion Criteria

- Player has completed all six steps.
- Full debrief has been viewed.
- Flags `station_6_complete` and `layer1_complete` set in GameManager.
- Door to Layer 2 area unlocked.

---

## 8. Explanation Mechanics Reference

All explanations in Layer 1 use one of four visual mechanics. No station uses plain text blocks. These mechanics should be implemented as reusable UI components that can be invoked from any station's script.

### 8.1 — Cause → Event → Effect Chain

**Used in:** Stations 1, 6

**Description:** Three panels appear in horizontal sequence, connected by animated arrows. Each panel fades/slides in one at a time with a short delay (0.5-0.8 seconds between panels). The visual style should feel like a flowchart or storyboard.

**Panel contents:**
- Panel 1 (Cause): labeled "CAUSE" at the top, contains a short description and a relevant icon or small illustration.
- Panel 2 (Event): labeled "EVENT" with a question mark or uncertainty indicator, contains the uncertain occurrence.
- Panel 3 (Effect): labeled "EFFECT" with an impact indicator (color-coded by severity), contains the project consequence.

**Below the chain:** A concluding sentence that names the concept or principle being taught. This sentence should be no more than two lines.

**Implementation note:** This should be a reusable scene/component — `CauseEventEffectChain.tscn` — that accepts three text strings and an optional severity level for color coding.

### 8.2 — Evidence Columns

**Used in:** Stations 2, 6

**Description:** Two vertical columns appear side by side. The left column header is "Makes it MORE likely" (or "Increases impact" when used for impact assessment). The right column header is "Makes it LESS likely" (or "Decreases impact"). Items populate each column one at a time with a fade-in animation.

**Visual style:** Each item has a small arrow icon (up-arrow for increasing factors, down-arrow for decreasing). The column with more items should be visually dominant — if there are 4 "more likely" factors and 1 "less likely" factor, the imbalance itself communicates the assessment.

**Below the columns:** A concluding sentence that states the assessed level (Low/Medium/High) and the reasoning principle.

**Implementation note:** Reusable component — `EvidenceColumns.tscn` — that accepts two arrays of strings.

### 8.3 — Ripple Effect Animation

**Used in:** Stations 3, 5, 6

**Description:** A sequence of consequence panels that appear one at a time, each connected to the previous by an arrow or ripple line. Each panel represents one step in the cascade of consequences from a risk event or a strategy choice.

**Panel contents:** Each panel contains:
- A short description of what happens at this step
- A delta indicator showing the change to a specific dimension (e.g., "→ Schedule: +3 weeks" or "→ Cost: +$15K")
- A color coding matching the affected dimension

**Visual style:** Panels should appear in a vertical or flowing sequence, with each new panel "rippling" out from the previous one. The animation should feel like a chain reaction.

**At the end of the sequence:** A summary bar showing the net impact across all four dimensions (cost, schedule, quality, scope) with totals.

**Implementation note:** Reusable component — `RippleEffect.tscn` — that accepts an array of step objects, each containing a description, a dimension, and a delta value.

### 8.4 — Character-Driven Metaphor (Fire System)

**Used in:** Station 4

**Description:** When a risk matrix quadrant is activated, a fire-themed animation plays within the quadrant, and a strategic identity message appears. This is not a dialogue — it's a visual reveal with accompanying text that gives the category personality and strategic meaning.

**Visual elements per quadrant:**
- Animated fire visual (unique to each category — see Section 5 for descriptions)
- Category name in large text
- Color fill for the quadrant
- 2-3 sentence strategic description

**Implementation note:** These can be built as animated `TextureRect` or `AnimatedSprite2D` nodes within the matrix UI, with a `Label` or `RichTextLabel` for the strategic text. The matrix itself should be a reusable component — `RiskMatrix.tscn` — since it reappears in the HUD during Layers 2 and 3.

---

## 9. Data Requirements

### New fields needed in game state (GameManager.gd)

```
var station_1_complete: bool = false
var station_2_complete: bool = false
var station_3_complete: bool = false
var station_4_complete: bool = false
var station_5_complete: bool = false
var station_6_complete: bool = false
var layer1_complete: bool = false

var client_profile: Dictionary = {
    "name": "",
    "company": "",
    "budget_tolerance": "",
    "schedule_flexibility": "",
    "quality_standards": "",
    "scope_flexibility": ""
}

var layer1_performance: Dictionary = {
    "station_1_accuracy": 0.0,
    "station_2_accuracy": 0.0,
    "station_3_accuracy": 0.0,
    "station_4_accuracy": 0.0,
    "station_5_strategy_chosen": "",
    "station_6_hints_used": 0,
    "station_6_strategy_chosen": ""
}
```

### New scenes required

| Scene | Purpose |
|-------|---------|
| `TrainingWing.tscn` | The physical corridor containing all 6 stations |
| `Station1_Identification.tscn` | Station 1 UI and interaction logic |
| `Station2_Probability.tscn` | Station 2 UI and interaction logic |
| `Station3_Impact.tscn` | Station 3 UI and interaction logic |
| `Station4_Matrix.tscn` | Station 4 UI and interaction logic |
| `Station5_Strategies.tscn` | Station 5 UI and interaction logic |
| `Station6_FullCycle.tscn` | Station 6 UI and interaction logic |
| `CauseEventEffectChain.tscn` | Reusable explanation component |
| `EvidenceColumns.tscn` | Reusable explanation component |
| `RippleEffect.tscn` | Reusable explanation component |
| `RiskMatrix.tscn` | Reusable matrix component (used in Station 4 and HUD) |
| `ClientProfileCard.tscn` | Reusable client profile card component |
| `NPCDialogue.tscn` | Reusable branching conversation component |

### NPC characters introduced in Layer 1

| Character | Role | Appears in | Purpose |
|-----------|------|-----------|---------|
| Dana | CEO of SecurePay | Station 3 | Reveal client priorities through conversation |
| Jordan | Senior Developer | Station 5 | Provide investigation context for strategy choice |
| Alex | QA Lead | Station 6 | Provide investigation context for full-cycle exercise |

---

## 10. Transition to Layer 2

When Layer 1 is complete, the following should carry forward into Layer 2:

- The **risk matrix** (with fire metaphors) becomes a persistent HUD element
- The **client profile card** remains accessible and may change per scenario in Layer 2
- The **four explanation mechanics** are reused for debriefs after Layer 2 scenarios, but with less scaffolding
- The **conversation/investigation mechanic** becomes a core optional action before every risk response decision
- The player's **Layer 1 performance** can optionally influence Layer 2 difficulty (e.g., fewer hints available if Layer 1 accuracy was high)
- The **strategy reference card** from Station 5 is accessible from the HUD as a quick-reference tool

Layer 2 design will be documented separately.
