import json, sys, io, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

base = r'd:\antigravity Projects\Crisis cabinet\Readme\exported files'
game_root = r'd:\antigravity Projects\Crisis cabinet'

# Load the GPPT export
with open(os.path.join(base, 'crisis_cabinet_gppt_json_backup.json'), encoding='utf-8') as f:
    export = json.load(f)

# Load the real game scenarios
with open(os.path.join(game_root, 'gppt_crisis_cabinet_v2.json'), encoding='utf-8') as f:
    game_data = json.load(f)

state = export['state']

# ─────────────────────────────────────────────────────────────
# FIX 1: Team Members — remove AI Agent, fix names
# ─────────────────────────────────────────────────────────────
state['teamMembers'] = [
    {
        "name": "Ferdaws",
        "surname": "Qaem",
        "email": "2300001530@stu.iku.edu.tr",
        "role": "Lead Developer / Programmer"
    },
    {
        "name": "Abdelmagied",
        "surname": "Farhouda",
        "email": "abod3zv@gmail.com",
        "role": "Game Designer"
    },
    {
        "name": "Mohamed",
        "surname": "Sallam",
        "email": "2300000497@stu.iku.edu.tr",
        "role": "Tester"
    }
]
print("✅ FIX 1: Team members updated (AI Agent removed, names corrected)")

# ─────────────────────────────────────────────────────────────
# FIX 2: Scenarios — replace Smart-Fill placeholders with real game scenarios
# ─────────────────────────────────────────────────────────────
# Map game scenarios into GPPT scenario format
phase_map = {
    "SC-01": "Planning",  "SC-02": "Planning",  "SC-03": "Planning",
    "SC-04": "Executing", "SC-05": "Executing",  "SC-06": "Executing",
    "SC-07": "Monitoring","SC-08": "Monitoring", "SC-09": "Monitoring",
    "SC-10": "Closing",   "SC-11": "Closing",    "SC-12": "Closing"
}
category_map = {
    "SC-01": "Tiger",    "SC-02": "Puppy",      "SC-03": "Alligator",
    "SC-04": "Tiger",    "SC-05": "Puppy",      "SC-06": "Kitten",
    "SC-07": "Tiger",    "SC-08": "Alligator",  "SC-09": "Puppy",
    "SC-10": "Alligator","SC-11": "Tiger",       "SC-12": "Kitten"
}

gppt_scenarios = []
for i, s in enumerate(game_data['scenarios'], 1):
    gid = s['id']          # e.g. SC-01
    sid = f"S{i:02d}"      # GPPT format: S01, S02...
    gppt_scenarios.append({
        "id": sid,
        "gameId": gid,
        "phase": phase_map.get(gid, "Planning"),
        "tuslerCategory": category_map.get(gid, "Tiger"),
        "title": s['title'],
        "probability": s['prob'],
        "impact": s['impact'],
        "urgency": s.get('urgency', 'Medium'),
        "setup": s['setup'],
        "lessonText": s['lesson_text'],
        "correctStrategy": s['objective'],
        "winCondition": s['winCondition']
    })

state['scenarios'] = gppt_scenarios
print(f"✅ FIX 2: {len(gppt_scenarios)} real game scenarios injected (replaced Smart-Fill placeholders)")

# Print the scenario alignment for verification
print()
print("  Scenario alignment check:")
print(f"  {'GPPT ID':<8} {'Game ID':<8} {'Phase':<12} {'Category':<12} {'Strategy':<10} {'Title'}")
print(f"  {'-'*8} {'-'*8} {'-'*12} {'-'*12} {'-'*10} {'-'*35}")
for s in gppt_scenarios:
    print(f"  {s['id']:<8} {s['gameId']:<8} {s['phase']:<12} {s['tuslerCategory']:<12} {s['correctStrategy']:<10} {s['title'][:40]}")

# ─────────────────────────────────────────────────────────────
# FIX 3: Project title and key metadata corrections
# ─────────────────────────────────────────────────────────────
state['projectTitle'] = "Crisis Cabinet: IT Project Risk Management Simulation"
state['organisation'] = "Department of Computer Engineering, Istanbul Kültür University"
state['courseCode'] = "COM0463"
state['domain'] = "IT Project Risk Management — PMBOK Chapter 11 & Tusler Risk Matrix"
state['deliverableArea'] = "Windows PC educational simulation game (Godot 4.4.1, GL Compatibility renderer)"
print()
print("✅ FIX 3: Project metadata verified and corrected")

# ─────────────────────────────────────────────────────────────
# FIX 4: Difficulty levels — add real game values
# ─────────────────────────────────────────────────────────────
state['difficultyLevels'] = {
    "Easy":   {"budget": 200000, "padsPerRoom": 1, "totalScenarios": 4,  "scheduleDays": 120},
    "Medium": {"budget": 150000, "padsPerRoom": 2, "totalScenarios": 8,  "scheduleDays": 120},
    "Hard":   {"budget": 100000, "padsPerRoom": 3, "totalScenarios": 12, "scheduleDays": 120},
    "tileCost": 500,
    "lowBudgetThreshold": "20% of starting budget"
}
print("✅ FIX 4: Difficulty system (Easy/Medium/Hard) added with real budget values")

# ─────────────────────────────────────────────────────────────
# FIX 5: Credits / Team in ideaBrief
# ─────────────────────────────────────────────────────────────
state['ideaBrief']['title'] = "Crisis Cabinet: IT Project Risk Management Simulation"
state['ideaBrief']['domain'] = "IT Project Management — PMBOK Chapter 11 Risk Management"
state['ideaBrief']['audience'] = "3rd and 4th year Computer Engineering students (COM0463)"
print("✅ FIX 5: Idea brief updated")

# ─────────────────────────────────────────────────────────────
# FIX 6: Reward structure — reflect actual game scoring
# ─────────────────────────────────────────────────────────────
state['rewardStructure'] = {
    "baseXPPerScenario": 110,
    "streakMultiplier": "1.0 + (streak * 0.1)",
    "losePoints": 0,
    "compositeScore": "point_score + (budget / 10) + xp_score - (total_play_time * 5)",
    "tiers": {
        "Elite":        {"condition": "Score >= 85% of maximum possible", "reward": "CEO commendation scene + Gold badge"},
        "Professional": {"condition": "Score 60-84% of maximum",          "reward": "Standard debrief + Silver badge"},
        "Trainee":      {"condition": "Score < 60%",                       "reward": "Audit Report + improvement recommendations"}
    },
    "scoreboard": "Top 10 stored in user://scoreboard.json"
}
print("✅ FIX 6: Reward structure updated to match actual game scoring")

# ─────────────────────────────────────────────────────────────
# Write corrected JSON
# ─────────────────────────────────────────────────────────────
export['state'] = state
export['_audit']['patchedAt'] = '2026-05-05T22:48:00Z'
export['_audit']['patchNote'] = 'Patched to align with Crisis Cabinet v1.0 final game build: real scenarios, correct team members, actual scoring system.'

out_path = os.path.join(base, 'crisis_cabinet_gppt_json_backup.json')
with open(out_path, 'w', encoding='utf-8') as f:
    json.dump(export, f, ensure_ascii=False, indent=2)

print()
print(f"✅ DONE — Updated JSON saved to:")
print(f"   {out_path}")
print(f"   Size: {os.path.getsize(out_path):,} bytes")
