# Known Issues & Planned Improvements

## Bugs - Layout & Resolution

### Content Overflow in Station Overlays
**Affected:** Stations 3, 4, 5, and their sub-components  
**Description:** Some content panels extend beyond the viewport boundaries, causing text to be cut off at screen edges and buttons to be unreachable. This occurs because UI panels size to their content rather than constraining to the available viewport space.

**Specific cases:**
- **Station 3, Impact Assessment (Risk 3):** Long risk title ("Compliance review reveals...") pushes the impact grid and dimension labels off the left edge
- **Station 3, Priority Lens:** Dana's profile card and three risk summaries overflow vertically, explanatory text partially off-screen
- **Station 3, Contrast Exercise:** Dana's and Government profile cards overlap instead of sitting side by side
- **Station 4, Matrix Summary:** Summary text overlaps with the matrix display - two text blocks render on top of each other
- **Station 5, Strategy Exploration:** The RippleEffect ("Impact Cascade") during strategy exploration renders off-screen with its Continue button unreachable
- **Station 5, Strategy Panels:** Four strategy panels can overflow the viewport width

**Root cause:** Content panels use CenterContainer which sizes to content rather than constraining to viewport. Panels lack `SIZE_EXPAND_FILL` flags and text elements lack `autowrap_mode`.

**Fix approach:** Replace CenterContainer with MarginContainer (full-rect anchors with margins), set equal stretch ratios on sibling panels, ensure all dynamic text has autowrap enabled.

---

## Improvements - Planned

### Dialogue System Redesign
**Priority:** High  
**Description:** Current NPC dialogue shows one response at a time - previous messages disappear when new ones appear. Should be redesigned as a scrollable chat-style log where:
- NPC messages stack on the left with avatar
- Player's chosen responses appear on the right
- Full conversation history is visible by scrolling up
- Especially important for Station 3 where the player needs to remember Dana's earlier responses

### Typewriter Text Effect
**Priority:** High  
**Description:** Dialogue and explanation text should appear character-by-character (fast) with a subtle blip sound per character, giving a "typing" feel. Implementation: use `RichTextLabel.visible_characters` with a Timer.

### NPC Conversation Greetings
**Priority:** Medium  
**Description:** NPCs should open conversations with context-appropriate greetings instead of jumping straight to player choices. Each NPC should have a unique opening line per situation.

### Character Talking Animation
**Priority:** Medium  
**Description:** NPC avatars should have a simple 2-frame talking animation (mouth open/close) while their text is being displayed. Currently avatars are static placeholder squares with initials.

### Dialogue Blip Sounds
**Priority:** Medium  
**Description:** Each NPC should have a distinct short audio blip that plays per character during the typewriter effect. Different pitch/tone per character for personality.

### Text Line Spacing
**Priority:** Low  
**Description:** The pixel font (Press Start 2P) has very tight default line spacing. All text elements need increased `line_spacing` (approximately 6-8px) for readability.

### Skip Mode for Demos
**Priority:** Medium  
**Description:** A debug/demo mode that adds a "Skip Station" button to every station overlay and a "Skip to Layer 2" option in the Training Wing. Essential for presentations where specific sections need to be demonstrated without playing through everything.

### Back Navigation Within Stations
**Priority:** Low  
**Description:** Add a "Back" button to each step within a station so the player can revisit previous steps. Currently progression is one-way only.

### Contextual Impact Sub-Labels
**Priority:** Low  
**Description:** The four impact dimensions (Cost, Schedule, Quality, Scope) are the same labels for every risk. Adding contextual sub-text per scenario would reduce repetition. Example: "Cost Impact (recruitment, onboarding)" vs "Cost Impact (vendor penalties, workarounds)".

### Training Wing Tileset
**Priority:** Medium  
**Description:** The Training Wing corridor currently uses placeholder colored rectangles. It needs proper tileset art matching the existing game's pixel art rooms.

### NPC Character Sprites & Avatars
**Priority:** Medium  
**Description:** All NPCs currently show as colored squares with first-initial letters. Need actual character sprite art or pixel portraits.

---

## Working Features

- All 6 Layer 1 teaching stations functional end-to-end
- Sequential station gating (complete one to unlock the next)
- Training Wing corridor with player navigation
- HUD with phase/station progress display
- All reusable UI components (chains, evidence, ripples, matrix, profiles, dialogue, resources, resolution)
- Game state management (health, budget, capacity, risk register)
- Data-driven scenarios (JSON-based, extensible)
- NPC branching dialogue system
- Fire metaphor risk classification system
- Client priority profile system
- Pixel art theme with teal/dark palette
- Main menu -> Training Wing flow
