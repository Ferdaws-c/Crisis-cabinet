# Crisis Cabinet — Layer 3 Design Document
## "The Proving Ground"

**Document version:** 1.0
**Date:** April 23, 2026
**Game engine:** Godot 4.4 (GDScript)
**Project context:** SecurePay — continued from Layer 2. Same project, same team, new pressures.
**Prerequisite:** Layer 2 complete (`layer2_complete == true`)

---

## 1. Layer 3 Overview

### Purpose

Layer 3 is the final test. The player has learned the frameworks (Layer 1) and practiced them under realistic conditions (Layer 2). Layer 3 asks: can the player make sound risk management decisions when the frameworks alone aren't enough — when stakeholders disagree, evidence conflicts, information is incomplete, and professional judgment is required?

By the end of Layer 3, the player should have experienced:

- Managing risk when stakeholder priorities conflict and there is no single "correct" optimization target
- Assessing risks where evidence is ambiguous and expert opinions disagree
- Making decisions that involve professional and ethical dimensions beyond pure risk calculus
- Operating independently without scaffolding, hints, or guided explanations
- Defending their decisions under stakeholder scrutiny

### Design Principles

1. **Ambiguity is the teacher.** Layer 3 deliberately presents situations where the "right" answer is genuinely unclear. The player must develop judgment, not just apply a formula.
2. **Conflict is structural, not dramatic.** Competing priorities aren't presented through dramatic confrontation — they're embedded in the mechanics. Two profile cards with conflicting stat bars. Two NPCs with different reads. The player feels the tension through the tools, not through exposition.
3. **Show, never explain.** Every new element (stakeholder conflict, ambiguity, ethical dimensions) is experienced through existing interactive mechanics — conversations, profile cards, the register, the dashboard. Nothing is introduced through text descriptions.
4. **Scaffolding is removed, not replaced.** Layer 3 doesn't add new tutorial elements. It removes old ones. No hints, shorter debriefs, less direct NPC dialogue. The player operates on their own.
5. **Ethical dimensions emerge naturally.** Professional responsibility moments are embedded within normal risk decisions. The game never labels them — the debrief names them after the player has already chosen.

### Narrative Context

SecurePay launched at the end of Layer 2 (successfully or after a retry). Layer 3 picks up immediately after launch. The app is live, users are onboarding, and Dana is preparing for the next phase of growth. But a new development disrupts the plan: SecurePay's parent company is in acquisition talks with a larger financial institution — MidBank. This isn't a new project — it's the same project under new pressure.

The acquisition creates a second stakeholder whose priorities conflict with Dana's. It introduces new risks that are harder to assess because the acquisition itself is uncertain. And it raises professional questions about what the team owes to users, to Dana, and to the acquiring company.

The player manages SecurePay through four post-launch phases: Stabilization, Growth, Due Diligence, and Transition. The existing four risk rooms are reused for these phases.

### Physical Layout in the Game

Layer 3 uses the same four risk rooms, now representing post-launch phases:

- Room 1 → Stabilization Phase
- Room 2 → Growth Phase
- Room 3 → Due Diligence Phase
- Room 4 → Transition Phase

The HUD retains the Project Health Dashboard and Risk Register from Layer 2. A second client profile card slot is added to accommodate the conflicting stakeholder.

---

## 2. New Mechanics

### 2.1 — Conflicting Stakeholder Priorities

**Primary design (no new character assets required):**

Dana's priorities shift after the acquisition talks begin. In Layer 1 and Layer 2, Dana's profile card was stable: high budget tolerance, low schedule flexibility, high quality standards, high scope flexibility. In Layer 3, Dana receives pressure from MidBank's board and her own investors, and her priorities change.

**How this is communicated to the player:**

At the start of Growth Phase (Room 2), Dana has a conversation with the player where her language has shifted:

> **Dana:** "I just got off a call with MidBank's CFO. They're looking at our burn rate very carefully. I know I said budget wasn't an issue before, but... we need to show financial discipline now. Every dollar we spend is under a microscope."

After this conversation, Dana's profile card visually updates — the player watches the stat bars shift:

- Budget Tolerance: High → **Low** (animated shift downward)
- Schedule Flexibility: Low → **Medium** (slight upward shift — the hard market deadline has passed, post-launch timeline is more flexible)
- Quality Standards: High → **Very High** (MidBank has strict compliance requirements)
- Scope Flexibility: High → **Low** (MidBank wants to see the full feature set as part of valuation)

The player now has two states of the same profile card visible — a "Before" and "After" — and must recalibrate every risk assessment they've been making. A risk they classified as a Campfire because Dana could absorb the budget hit might now be a Wildfire because she can't.

**Optional expansion (new character — implement if team has capacity):**

Instead of Dana's priorities shifting, a new NPC is introduced — **"Katherine, MidBank's Integration Director."** Katherine has her own profile card with priorities that directly conflict with Dana's original profile:

| Dimension | Dana (Original) | Katherine (MidBank) |
|-----------|-----------------|---------------------|
| Budget Tolerance | High | Low |
| Schedule Flexibility | Low | High |
| Quality Standards | High | Very High |
| Scope Flexibility | High | Low |

Both profile cards are visible simultaneously. When the player assesses impact, they see how the same risk registers differently on each card. The game never explains the conflict — the conflicting bars speak for themselves.

Katherine's conversations are brief (2-3 exchanges per phase she appears in) and focus purely on MidBank's perspective. She's professional, not antagonistic — she simply has different priorities.

**If the optional expansion is not implemented:** All references to Katherine in the phase designs below are replaced with Dana-post-shift. The mechanic is identical — conflicting profile cards — the only difference is whether it's two characters or one character with changed priorities.

### 2.2 — Ambiguous Risks

In Layers 1 and 2, every risk had a determinable probability and impact. The player could assess them with confidence if they used the right evidence. In Layer 3, 3-4 risks across the four phases are deliberately ambiguous — the available evidence points in different directions, and the player must make a judgment call.

**How ambiguity is presented:**

Ambiguous risks enter the register the same way as normal risks — auto-populated with an "Unassessed" status. The difference is in the investigation phase. When the player investigates an ambiguous risk, they talk to two NPCs who give conflicting assessments.

Example:

> **Jordan:** "The new database migration? I've done three of these before. It's routine — maybe a 20% chance anything goes wrong."
>
> **Alex:** "I looked at the data volumes we're moving. This is twice the size of anything we've migrated before. I'd put the failure risk at 60%, honestly."

The risk entry in the register does not auto-suggest a probability. Instead of the usual Low/Medium/High selector with evidence columns confirming or denying, the player sees both NPC assessments displayed as conflicting indicators — one pointing toward Low, the other toward High. The player must place the risk on the matrix themselves with no validation.

**How ambiguity resolves:**

During phase resolution, the probability roll uses a "true" probability that was hidden from the player (defined in the scenario data). The debrief reveals this value and which NPC's read was closer:

"The actual probability of the database migration failing was 45%. Jordan underestimated based on his past experience with smaller datasets. Alex overestimated because she was focused on the data volume without accounting for the improved tooling available. The truth was between their assessments. In situations like this, experienced PMs weigh multiple perspectives and look for the factors each person might be over- or under-weighting."

**Design constraint:** Ambiguous risks are never the highest-impact risks in a phase. The player should be able to survive a wrong call on an ambiguous risk — the teaching comes from seeing the resolution, not from being punished for an impossible assessment.

### 2.3 — Ethical and Professional Dimensions

2-3 decisions across Layer 3 contain a hidden ethical or professional dimension that is not labeled or flagged. These look like normal risk response choices — one option is cheaper/faster, the other is more expensive/slower. The ethical dimension is revealed only through investigation.

**How ethical dimensions are embedded:**

The player sees a standard risk with standard response options. If they investigate (talk to the relevant NPC), one line of dialogue adds a human or professional dimension that changes the calculus:

Example — Risk: "Automated monitoring system has a known gap in fraud detection for transactions under $10."

Response options visible without investigation:
- Mitigate: Fix the gap. Cost: $25K, 3 person-weeks.
- Accept: The gap affects only small transactions. Expected loss: ~$2K/month. Statistically insignificant.

If the player investigates by talking to Alex:

> **Alex:** "Technically the financial exposure is tiny. But those small transactions? They're mostly from users in our basic tier — students, low-income users. If someone exploits this, those are the people who can least afford to lose even $10. And if it gets out that we knew and didn't fix it... that's not a good look for a banking app."

Now "Accept" has a different weight. The financial risk calculus hasn't changed — $2K/month is still small. But the player knows there's a human cost and a reputational dimension that the numbers don't capture.

**The player still chooses freely.** Accept is still a valid option. The game doesn't punish them for choosing it — the debrief simply names what was at stake:

"You chose to accept the fraud detection gap. Financially, this was efficient — the mitigation cost far exceeded the expected loss. However, the affected users were disproportionately from vulnerable demographics, and the decision carried reputational risk that isn't captured in the budget numbers. In professional practice, risk decisions often involve considerations beyond the quantitative framework — stakeholder welfare, professional ethics, and long-term trust."

**Design constraint:** Ethical dimensions never determine pass/fail. They are teaching moments, not traps. A player who accepts the risk doesn't fail — they receive a richer debrief. The game respects that reasonable professionals can disagree on these decisions.

### 2.4 — Reduced Scaffolding

Layer 3 removes the following support systems:

| Element | Layer 1 | Layer 2 | Layer 3 |
|---------|---------|---------|---------|
| Hint buttons | Available after 8 seconds | Not present | Not present |
| Evidence columns after assessment | Always shown | Always shown | Not shown — player assesses without confirmation (except during debrief) |
| "Correct/incorrect" feedback after matrix placement | Immediate correction | No immediate feedback, covered in debrief | No immediate feedback, covered in debrief |
| Debrief length | Full explanation at every step | Comprehensive end-of-phase debrief | Shortened debrief — key insights only, no step-by-step walkthrough |
| NPC dialogue directness | NPCs give clear, actionable information | NPCs give useful but less explicit information | NPCs give partial, sometimes conflicting information — player must interpret |
| Risk register auto-suggestions | Matrix category auto-suggested from probability + impact | Matrix category auto-suggested | No auto-suggestion — player classifies entirely on their own |
| Strategy tradeoff notes | Shown before choosing | Shown before choosing | Shown only for options the player hovers over for 3+ seconds — encouraging deliberation without hand-holding |

**The effect on gameplay:** Layer 3 feels faster and more demanding. The player spends less time reading explanations and more time making decisions. The tools are all still there — the matrix, the register, the dashboard, the conversations — but the game stops guiding the player through them. This is the difference between a student working through a textbook problem with the answer key open and a professional making decisions in a real meeting.

---

## 3. Phase-by-Phase Design

### 3.1 — Phase 1: Stabilization

**Narrative context:** SecurePay has been live for two weeks. The initial launch went according to however Layer 2 ended. Now the team is in stabilization mode — fixing post-launch bugs, monitoring performance, and handling the first wave of real user feedback. The acquisition talks with MidBank are a rumor at this point — not yet confirmed.

**Phase resources:**
- Contingency budget: Starting fresh for Layer 3 (difficulty-dependent, same scale as Layer 2)
- Team capacity: 10 person-weeks (smaller than Layer 2 Planning — the team is also handling live operations)

**Risks surfaced in this phase:**

4 auto-populated risks:

| ID | Title | Source | Base Probability | Primary Impact | Notes |
|----|-------|--------|-----------------|----------------|-------|
| STAB-01 | Post-launch performance degradation under higher-than-expected user load | Operations monitoring alert | 55% | Quality: High, Stakeholder Trust: Medium | Straightforward risk — uses Layer 2 mechanics, eases the player into Layer 3 |
| STAB-02 | Customer support team overwhelmed by onboarding questions, response times increasing | Support team report | 70% | Stakeholder Trust: Medium, Quality: Low | Campfire-level risk — tests whether the player correctly deprioritizes it |
| STAB-03 | A competitor publishes a negative comparison article highlighting SecurePay's missing features | Market intelligence report | 40% | Stakeholder Trust: Medium, Scope: Low | First test of judgment — impact depends heavily on how the player weights reputation |
| STAB-04 | Key infrastructure vendor announces end-of-life for a critical service component within 6 months | Vendor notification | 35% | Schedule: Medium, Cost: Medium, Quality: Low | Volcano-type risk — low immediate probability, high future impact if ignored |

**1 hidden risk:**

| ID | Title | Hint Source | Base Probability | Primary Impact |
|----|-------|-------------|-----------------|----------------|
| STAB-H1 | Internal data shows a pattern of failed transactions during peak hours that hasn't been reported to the team | Alex mentions: "I've been seeing some weird spikes in the error logs around lunchtime. Probably nothing — the monitoring system flags false positives all the time." | 50% | Quality: High, Stakeholder Trust: High (if it becomes public) |

This hidden risk connects to the ethical dimension in later phases — the failed transactions affect real users, and the player's decision about whether to investigate now or wait has implications beyond the technical.

**Player actions in Stabilization:**

Standard Layer 2 flow — assess, classify, respond, allocate — but without evidence columns confirming assessments and without auto-suggested matrix categories. The player operates the tools independently.

**NPCs available:**

| Character | Information |
|-----------|------------|
| Jordan | Technical details on STAB-01 and STAB-04, hints at STAB-H1 through a separate mention of "intermittent issues" |
| Alex | Details on STAB-02 and STAB-03, the direct hint source for STAB-H1 |
| Dana | Brief check-in — positive and relieved about launch, no acquisition pressure yet |

**Phase resolution:**

Standard probability rolls and consequence cascades. Transition to Growth Phase.

### 3.2 — Phase 2: Growth

**Narrative context:** SecurePay's user base is growing. Dana is pushing for feature expansion to increase valuation. And now the acquisition talks with MidBank are confirmed — Dana tells the player directly.

**This phase introduces the conflicting stakeholder mechanic.**

**The priority shift conversation:**

At the start of Growth Phase, Dana has a mandatory conversation:

> **Dana:** "I need to tell you something. MidBank is in serious talks to acquire us. This is good news — but it changes things."

> **Player choice 1:** "How does this affect the project?"
>
> **Dana:** "MidBank's CFO is watching our numbers. Every dollar we spend, they're evaluating. I know I told you before that budget wasn't an issue — but now it is. We need to look financially disciplined."

> **Player choice 2:** "What about the launch timeline pressure?"
>
> **Dana:** "That's actually eased up. We're live, users are growing. The pressure now is showing MidBank that we're stable and mature, not that we're fast. Take the time to do things right."

> **Player choice 3:** "What does MidBank care about most?"
>
> **Dana:** "Compliance. Security. Full feature coverage. They want to see a product they can integrate into their platform without risk. They've been very clear about that."

After this conversation, Dana's profile card updates with animated stat bar shifts (as described in Section 2.1). The player now operates under the new priority landscape.

**Phase resources:**
- Contingency budget: Remaining from Stabilization
- Team capacity: 10 person-weeks

**Risks surfaced in this phase:**

4 auto-populated risks, including the first ambiguous risk:

| ID | Title | Source | Base Probability | Primary Impact | Special |
|----|-------|--------|-----------------|----------------|---------|
| GROW-01 | Scaling database architecture to handle 10x user growth requires significant refactoring | Jordan's technical assessment | 60% | Cost: High, Schedule: Medium | First risk the player must assess under the NEW priority profile — cost is now critical |
| GROW-02 | MidBank requests access to SecurePay's codebase for preliminary technical review | Katherine/Dana relays MidBank's request | 80% (near certain) | Quality: Medium (if code isn't clean), Stakeholder Trust: High (if they find issues) | The "risk" is really about preparation — the review will happen, the question is whether the team is ready |
| GROW-03 | Database migration to new scalable architecture may fail during transition | Technical planning report | **Ambiguous** (true probability: 45%) | Schedule: High, Quality: Medium, Cost: Medium | **AMBIGUOUS RISK — Jordan and Alex disagree** (see Section 2.2 for the conversation) |
| GROW-04 | New feature development velocity slower than projected due to technical debt from launch rush | Sprint velocity report | 65% | Schedule: Medium, Scope: Medium | Cascades from Layer 2 decisions — if the player cut corners in Layer 2, this probability is higher |

**Layer 2 decision echo:**

GROW-04's base probability is modified by the player's Layer 2 performance:
- If Layer 2 Quality Health ended "On Track" or better: base probability 50%
- If Layer 2 Quality Health ended "Declining": base probability 65%
- If Layer 2 Quality Health ended "Critical": base probability 80%

This is communicated to the player through Jordan's investigation dialogue: "We took on some technical debt to hit the launch date. It's catching up with us now." The severity of his concern varies based on how much debt was actually accumulated. The player connects their past decisions to current consequences without the game explicitly lecturing about it.

**NPCs available:**

| Character | Information |
|-----------|------------|
| Jordan | Details on GROW-01, GROW-03 (his optimistic assessment), GROW-04 |
| Alex | Details on GROW-02, GROW-03 (her pessimistic assessment) |
| Dana | Acquisition context, shifted priorities, pressure from MidBank |
| Sam (Vendor Contact) | Brief appearance — details on infrastructure options for GROW-01 |

### 3.3 — Phase 3: Due Diligence

**Narrative context:** MidBank's due diligence process is underway. External auditors are reviewing SecurePay's systems, finances, and processes. The team is under scrutiny. This is the most pressured phase — the player is managing ongoing operational risks while also preparing for an audit that could determine the company's future.

**Phase resources:**
- Contingency budget: Remaining from Growth
- Team capacity: 8 person-weeks (reduced — team members are being pulled into due diligence interviews and documentation)

**Risks surfaced in this phase:**

3-4 risks, including the ethical dimension risk and a second ambiguous risk:

| ID | Title | Source | Base Probability | Primary Impact | Special |
|----|-------|--------|-----------------|----------------|---------|
| DD-01 | Due diligence audit discovers undocumented technical shortcuts from the launch phase | Audit preliminary findings | 60% | Stakeholder Trust: Very High, Quality: Medium | Impact severity depends on Layer 2 decisions — more shortcuts taken = more audit findings |
| DD-02 | Automated monitoring gap in fraud detection for small transactions | System review report | 45% | Cost: Low (financially), Quality: Medium, Stakeholder Trust: High (if exploited and public) | **ETHICAL DIMENSION RISK** (see Section 2.3 — the fraud detection gap affecting vulnerable users) |
| DD-03 | Key team members receiving recruitment offers from MidBank's competitors who learned about the acquisition | Team rumor / Ravi mentions it | **Ambiguous** (true probability: 55%) | Schedule: High, Quality: Medium, Stakeholder Trust: Medium | **AMBIGUOUS RISK — Jordan downplays it, Ravi is worried** |
| DD-04 | MidBank may impose a technology stack migration as a condition of the acquisition | Katherine/Dana relays MidBank's preliminary requirements | 40% | Cost: Very High, Schedule: Very High, Scope: High | Volcano-type — enormous impact if it happens, uncertain probability |

**The ethical dimension in DD-02:**

DD-02 is presented as a standard risk with standard response options. The financial analysis clearly supports "Accept" — the expected loss from the fraud gap is approximately $2K/month, while fixing it costs $25K and 3 person-weeks. Under the new budget-constrained priorities, Accept looks optimal.

If the player investigates by talking to Alex, the ethical dimension surfaces through dialogue (as described in Section 2.3). Alex mentions the affected user demographics and the reputational risk of knowing about the gap and not fixing it.

If the player does NOT investigate, they never learn about the ethical dimension. They make a purely financial decision, and the debrief reveals what they missed:

"You chose to accept the fraud detection gap without investigating. Alex could have told you that the affected transactions disproportionately impact your most vulnerable users. While the financial exposure was small, the professional and reputational dimensions were significant — and they were available to you if you'd asked."

If the player investigates and still accepts, the debrief is different:

"You investigated, understood the full picture, and chose to accept based on the financial analysis. This is a defensible decision — the numbers support it. But it's worth noting that some risk decisions involve values that the numbers don't fully capture. There's no single right answer here, and the fact that you investigated before deciding shows strong professional practice regardless of the choice you made."

**The second ambiguous risk (DD-03):**

When the player investigates:

> **Jordan:** "People get offers all the time. I've had three this year alone and I'm still here. I wouldn't worry about it."
>
> **Ravi:** "I've heard at least two people on the team talking about it seriously. The uncertainty about the acquisition is making people nervous. They want to know if they'll still have jobs in six months."

Jordan's optimism comes from his own loyalty and seniority. Ravi is closer to the junior team members who feel more vulnerable. The true probability is 55% — Ravi's read is closer to reality, but the player doesn't know that.

**Stakeholder pressure escalation:**

Due Diligence includes a mandatory Dana conversation that is harder than the Monitoring conversation in Layer 2. Dana is visibly stressed, and her questions are more pointed:

> **Dana:** "MidBank's auditors found [X] issues in the preliminary review. I need you to tell me honestly — are there more surprises coming?"

The player's response options:

- (If the player addressed most technical debt and audit-related risks): "We've been proactive about cleaning things up. There may be minor findings, but nothing that should derail the deal." → Trust: stable
- (If the player has unresolved issues): "There are a few areas I'm still working on. Here's what they are and here's my plan." → Trust: slight decrease but honest
- (Regardless of state): "Nothing to worry about — we're in great shape." → Trust: significant decrease if audit later reveals issues the player knew about

**If Katherine is implemented (optional expansion):**

Katherine also has a mandatory conversation in this phase, separately from Dana. Katherine's questions are different — more clinical and process-oriented:

> **Katherine:** "Walk me through your risk management process. How do you identify and track risks?"

The player's response options reference the risk register directly — the game checks how many risks the player has assessed, how many they investigated, and how complete their register is. A thorough register earns Katherine's confidence. A sparse one raises concerns.

This creates a meta-teaching moment: the player realizes that the risk register they've been building isn't just a gameplay tool — it's a professional artifact that stakeholders evaluate.

### 3.4 — Phase 4: Transition

**Narrative context:** The acquisition is moving forward. The team is preparing to transition SecurePay into MidBank's platform. This is the final phase — the last set of decisions the player makes.

**Phase resources:**
- Contingency budget: Whatever remains (likely tight)
- Team capacity: 6 person-weeks (heavily reduced — team members are being reassigned, onboarding MidBank counterparts, handling transition documentation)

**Risks in this phase:**

Like Closing in Layer 2, Transition introduces no new risks. It is about resolving what's open and making final strategic decisions.

**Open risk resolution:**

All risks still in "Active" or "Response Planned" status need final disposition:
- Resolve: confirm the response worked
- Accept residual: acknowledge remaining exposure and document it
- Escalate: flag for MidBank's team to handle post-transition

Each disposition affects the final outcome. Escalating too many risks signals to MidBank that the project was poorly managed. Resolving risks the player didn't actually address is dishonest and may be caught in the outcome.

**Final strategic decisions:**

**Decision 1 — Transition scope:**
"MidBank wants to integrate SecurePay's core systems within 3 months of acquisition close. Given the current state of the project, what's your recommendation?"
- Option A: Agree to the timeline — it's aggressive but achievable if nothing goes wrong
- Option B: Propose a 5-month timeline with phased integration milestones — more realistic, shows maturity
- Option C: Flag that the timeline is unrealistic given current technical debt and outstanding risks — honest but may jeopardize the deal

The "correct" answer depends on actual project state. If the player managed well and resolved most risks, Option A or B might both work. If there's significant unresolved debt, Option C is the responsible choice even though it's uncomfortable.

**Decision 2 — Team transition:**
"Three of your team members have been offered positions at MidBank. Two others have not and will need to find new roles. How do you handle this?"
- Option A: Focus on ensuring knowledge transfer for MidBank — prioritize the transition over the individuals
- Option B: Advocate for the two team members who weren't offered positions — spend political capital to push MidBank to include them
- Option C: Be transparent with the full team about the situation and let them make their own decisions

This decision has no direct impact on project health metrics — it is purely about professional values. The debrief discusses it in terms of leadership and team responsibility.

**Decision 3 — The honest handover:**
"You're preparing the final project handover document for MidBank. What do you include?"
- Option A: Comprehensive handover including all known issues, outstanding risks, and areas of concern — complete transparency
- Option B: Polished handover focusing on achievements and current state, with known issues mentioned briefly — professional but selective
- Option C: Handover focused entirely on positive metrics and successful delivery — omit outstanding issues to present the best possible picture

This decision ties together the ethical thread running through Layer 3. Option A is the most professionally responsible. Option C is the most tempting under acquisition pressure. Option B is the common middle ground. The debrief discusses professional integrity in project handovers.

**Final stakeholder conversation:**

A closing conversation with Dana (and Katherine if implemented) where the player presents their handover and defends their decisions. This mirrors the Monitoring stakeholder pressure from Layer 2 but with higher stakes and less room for deflection. The available dialogue options are shaped entirely by the player's actual decisions and project state — a player who managed honestly has strong, confident options; a player who cut corners has to navigate carefully.

---

## 4. Project Outcome and Debrief

### 4.1 — Outcome Simulation

The outcome sequence is structured similarly to Layer 2 but has a different focus. Instead of "did the app launch successfully," the question is "what is the legacy of your management?"

**The outcome is built from five components:**

**Acquisition result:**
- Based on overall project health and stakeholder trust: does the acquisition proceed smoothly, proceed with concerns, or face complications?
- If Stakeholder Trust (combined Dana + Katherine/MidBank) is high: "The acquisition closes on schedule. MidBank's leadership cites SecurePay's strong technical foundation and transparent management as key factors."
- If Trust is medium: "The acquisition closes, but MidBank negotiates a reduced valuation based on technical findings from due diligence."
- If Trust is low: "The acquisition is delayed for additional review. MidBank is uncertain about the risks they've inherited."

**Product health:**
- Based on Quality Health and unresolved risks: what is the state of SecurePay as a product going into integration?

**Team outcome:**
- Based on team-related decisions (morale risks, transition decisions): how does the team emerge from the project?

**Professional reputation:**
- Based on the honesty and quality of the player's stakeholder communication and handover: how is the player perceived as a PM?

**Ethical footprint:**
- Based on decisions with ethical dimensions (DD-02, transition decisions): a brief reflection on the human impact of the player's choices, without judgment.

### 4.2 — Layer 3 Debrief

The Layer 3 debrief is **shorter and more reflective** than Layer 2's. It does not walk through every risk step by step. Instead, it focuses on three sections:

**Section 1 — Key Judgment Calls:**

The debrief identifies the 3-4 decisions where the player's judgment was most tested — the ambiguous risks, the ethical dimension, and the stakeholder conflict moments. For each one, it shows:

- What the player chose
- What the actual outcome was
- What alternative perspectives existed
- No "correct answer" — framed as "here's what was at stake and how different approaches would have played out"

This section uses the Ripple Effect animation for each key decision, showing the consequence chain that followed.

**Section 2 — Ambiguity Retrospective:**

For each ambiguous risk, the debrief reveals the true probability and explains why the evidence was conflicting:

"The database migration failure risk had a true probability of 45%. Jordan's experience led him to underestimate because his past migrations were smaller. Alex's caution led her to overestimate because she focused on data volume without weighing the improved tooling. The skill isn't knowing who's right — it's knowing what each person might be over- or under-weighting, and triangulating."

**Section 3 — Growth Reflection:**

A comparison between the player's Layer 2 and Layer 3 performance — not as a score comparison, but as a qualitative reflection:

- "In Layer 2, you investigated 4 out of 8 available risks. In Layer 3, you investigated 6 out of 7. Your instinct to gather information before deciding has strengthened."
- "In Layer 2, you spent 70% of your contingency budget in the first phase. In Layer 3, you distributed resources more evenly across phases."
- "You identified 1 out of 2 hidden risks in Layer 2, and 1 out of 1 in Layer 3."

This section teaches the player to reflect on their own growth — a metacognitive skill that's valuable beyond the game.

### 4.3 — Final Performance Summary

The summary screen shows:

**Overall Management Profile:**

Instead of a single grade, the player receives a profile description based on their patterns across Layer 3:

| Profile | Condition |
|---------|-----------|
| "Strategic and Thorough" | Investigated most risks, balanced resources well, maintained trust, addressed ethical dimensions |
| "Efficient and Decisive" | Made fast decisions, allocated resources pragmatically, accepted calculated risks, may have missed ethical nuances |
| "Cautious and Conservative" | Over-invested in mitigation, strong quality outcomes but budget pressure, may have over-prepared for unlikely risks |
| "Reactive Manager" | Under-investigated, responded to crises rather than preventing them, trust fluctuated based on outcomes rather than preparation |
| "Under Pressure" | Struggled with resource constraints, multiple dimensions declined, but showed learning from Layer 2 patterns |

These profiles are not pass/fail — they reflect management styles, each with strengths and weaknesses. The debrief briefly notes what each style's strengths and blind spots are.

**Cumulative statistics across Layers 2 and 3:**

- Total risks managed
- Investigation rate
- Hidden risks identified
- Risks that triggered vs. total active risks
- Resources spent vs. available
- Health dimensions that reached Critical at any point
- Stakeholder conversations where the player was honest vs. deflective

---

## 5. Failure Conditions

### Trigger Conditions

Same structure as Layer 2 with one addition:

**Condition 1 — Dual Critical:** Two or more health dimensions reach Critical simultaneously.

**Condition 2 — Trust Collapse:** Stakeholder Trust reaches "Lost Confidence" while any other dimension is at second-lowest state or below.

**Condition 3 — Budget Exhaustion:** Contingency budget reaches zero AND a new risk triggers requiring budget to respond.

**Condition 4 (new) — Acquisition Collapse:** If Stakeholder Trust (specifically the MidBank/acquisition dimension) reaches Critical during Due Diligence or Transition, MidBank pulls out of the acquisition. This is a distinct failure mode that can occur even if the other health dimensions are acceptable — teaching that stakeholder management is its own critical dimension.

### Failure Sequence

Same as Layer 2: emergency meeting, debrief with "Breaking Point" analysis, restart options. Layer 3 restart options:

- Restart Layer 3 from the beginning
- Restart from the phase where failure occurred (with previous phase decisions preserved)

Layer 3 failure debriefs include a comparison to the player's Layer 2 performance, highlighting whether the failure was caused by new Layer 3 challenges (ambiguity, conflicting priorities) or by repeating Layer 2 mistakes.

### Fairness Safeguards

All Layer 2 safeguards apply. Additional safeguards for Layer 3:

- Ambiguous risks are never the sole cause of failure — even a worst-case assessment of an ambiguous risk should leave the player recoverable
- The ethical dimension risk (DD-02) never triggers failure conditions — it exists purely for teaching, not for punishment
- The stakeholder priority shift occurs early enough in Layer 3 (start of Growth Phase) that the player has two full phases to adjust before the highest-pressure phases (Due Diligence and Transition)
- If the player is approaching Acquisition Collapse, Dana or Katherine proactively signals concern in their next conversation, giving the player a chance to course-correct

---

## 6. Data Requirements

### New fields needed in GameManager.gd

```
# Layer 3 state
var layer3_complete: bool = false
var acquisition_active: bool = false

# Dual stakeholder profiles
var client_profile_original: Dictionary = {}
var client_profile_shifted: Dictionary = {}
var stakeholder_conflict_active: bool = false

# Ambiguity tracking
var ambiguous_risks: Array = []
var ambiguity_results: Array = []

# Ethical dimension tracking
var ethical_decisions: Array = []

# Layer comparison data
var layer2_performance_summary: Dictionary = {}
var layer3_performance_summary: Dictionary = {}

# Management profile
var management_profile: String = ""
var profile_factors: Dictionary = {
    "investigation_rate": 0.0,
    "resource_distribution_variance": 0.0,
    "trust_trend": "",
    "ethical_awareness": false,
    "proactive_vs_reactive_ratio": 0.0
}
```

### New scenario data fields for Layer 3 risks

In addition to the Layer 2 schema, Layer 3 risks may include:

```
{
    "ambiguous": true,
    "true_probability": 45,
    "conflicting_assessments": {
        "optimistic": {
            "npc": "jordan",
            "estimate": 20,
            "reasoning": "Past experience with similar but smaller migrations"
        },
        "pessimistic": {
            "npc": "alex",
            "estimate": 60,
            "reasoning": "Data volume is unprecedented for this team"
        }
    },
    "ethical_dimension": {
        "present": true,
        "revealed_through": "alex",
        "description": "Fraud gap disproportionately affects vulnerable users",
        "debrief_if_investigated": "...",
        "debrief_if_not_investigated": "..."
    },
    "layer2_echo": {
        "affected_by": "layer2_quality_health",
        "modifier_map": {
            "on_track": 0,
            "declining": 15,
            "critical": 30
        }
    }
}
```

### New Scenes Required

| Scene | Purpose |
|-------|---------|
| `DualProfileCard.tscn` | Displays two client profile cards side by side (or before/after for the single-character variant) |
| `ProfileShiftAnimation.tscn` | Animated transition showing stat bars changing when priorities shift |
| `AmbiguousAssessment.tscn` | Modified risk assessment UI showing conflicting NPC indicators instead of evidence columns |
| `AcquisitionOutcome.tscn` | End-of-Layer-3 outcome sequence focused on acquisition result |
| `ManagementProfile.tscn` | Final summary screen showing the player's management profile |
| `GrowthReflection.tscn` | Layer 2 vs. Layer 3 comparison debrief component |

Reused from Layer 2 (no modifications needed): `RiskRegisterPanel.tscn`, `HealthDashboard.tscn`, `PhaseResolution.tscn`, `ResourceAllocationUI.tscn`, `NPCDialogue.tscn`, `RippleEffect.tscn`, `RiskMatrix.tscn`, `ClientProfileCard.tscn`, `DebriefScreen.tscn`, `CascadeMap.tscn`, `FailureSequence.tscn`.

### NPC Roster for Layer 3

| Character | Phases Active | Role |
|-----------|--------------|------|
| Dana | All phases | Primary stakeholder — priorities shift in Growth Phase |
| Jordan | All phases | Technical lead — tends toward optimism in ambiguous assessments |
| Alex | All phases | QA lead — tends toward caution, source of ethical dimension reveals |
| Sam (Vendor Contact) | Stabilization, Growth | Infrastructure and vendor perspective |
| Ravi (Junior Developer) | Due Diligence, Transition | Team morale and ground-level perspective, source of hidden risk hints |
| Katherine (Optional) | Growth, Due Diligence, Transition | MidBank's Integration Director — conflicting priorities |

---

## 7. Transition to Post-Game

When Layer 3 is complete, the game has delivered its full teaching arc:

- **Layer 1:** Learned the vocabulary and frameworks
- **Layer 2:** Applied them under realistic conditions with scaffolded support
- **Layer 3:** Exercised judgment when the frameworks alone weren't sufficient

The post-game experience should include:

- The **final management profile** and cumulative statistics
- An option to **replay any layer** with different difficulty settings or different choices
- An option to **review all debriefs** from Layers 2 and 3 as a study reference
- A **certificate or completion summary** that could be submitted as part of the course deliverable (if applicable)

The design of the post-game screen will be covered in the unified style pass after all layers are designed.
