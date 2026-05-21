# Fruit Merge — Feature Roadmap

## Guiding principles
- Ship small, ship often. One focused update beats one mega-update.
- Audio before polish. Silence kills retention faster than missing features.
- No backend until there are users to justify it.

---

## Status legend
- `[ ]` Not started
- `[~]` In progress
- `[x]` Done

---

## Already built (baseline)
- [x] Core merge physics + game loop
- [x] 10 fruit types (cherry → watermelon)
- [x] Combo system (1.5s window, score multiplier)
- [x] Shaker / Bomb / Sniper power-ups
- [x] Coin economy + power-up store
- [x] XP + level system (Rookie → Watermelon King)
- [x] Player profile (name, avatar, stats)
- [x] High score persistence
- [x] Danger line + game over
- [x] Watermelon win condition + celebration overlay
- [x] Vibration feedback (guarded by settings toggle)
- [x] Shaker UX consistency (tap-to-confirm like Bomb/Sniper)
- [x] Reset high score actually resets
- [x] Evolution bar, lucky drop, combo banner

---

## Phase 1 — Feel (Weeks 1–2)
*Goal: game should feel alive*

- [ ] **Audio implementation**
  - Create `assets/audio/` folder
  - Add sounds: drop, merge, combo, game-over, win, button tap, background music
  - Initialize `AudioPlayer` instances in `AudioManager`
  - Replace all stub methods (call sites already in place)
  - Register assets in `pubspec.yaml`
  - Note: `audioplayers` package already in pubspec

---

## Phase 2 — Strategy (Weeks 3–4)
*Goal: give skilled players more control*

- [ ] **Undo button** (1–2 uses per game)
  - Industry standard in merge games (Threes, 2048, Suika)
  - Store last-dropped fruit state, restore on tap
  - Show remaining undo count in HUD

- [ ] **Next-next fruit preview**
  - Show 2 upcoming fruits instead of 1 (like Tetris)
  - Adds strategic depth, zero new mechanics
  - Small HUD change

---

## Phase 3 — Retention (Weeks 5–6)
*Goal: give players a reason to open the app daily*

- [ ] **Daily challenges**
  - Examples: "Merge 5 Oranges", "Score 500 in one game", "Use no power-ups"
  - 3 challenges per day, reset at midnight
  - Coin reward on completion

- [ ] **Daily login streak**
  - Streak counter persisted in `StorageService`
  - Increasing coin reward (day 1: 10 coins, day 7: 100 coins)
  - Streak broken if player misses a day

---

## Phase 4 — Content (Weeks 7–8)
*Goal: visual freshness, complete the store*

- [ ] **Candy theme** (first unlockable theme)
  - Replace fruit names/colors/emoji with candy equivalents
  - Gummy Bear → Lollipop → ... → Giant Cake
  - Unlock via coins in store (existing store UI, just needs wiring)

- [ ] **Magnet power-up**
  - Pulls two same-type fruits together for an immediate merge
  - Fills gap in power-up trio: Bomb (destroy) + Shaker (randomize) + Sniper (upgrade) + Magnet (assist)
  - Add to store, add `magnetCount` to `StorageService`

---

## Phase 5 — Depth (Weeks 9–10)
*Goal: replayability for all skill levels*

- [ ] **Difficulty modes**
  - Easy: wider jar (`sidePad = 20`)
  - Normal: current (`sidePad = 40`)
  - Hard: narrower jar (`sidePad = 60`) + danger line slightly lower
  - Separate high scores per difficulty
  - Zero new mechanics — just change constants

- [ ] **Tutorial / first-run onboarding**
  - 3-tap overlay on first launch
  - Show fruit evolution order, explain merge mechanic
  - "Don't let fruits cross the red line"
  - Dismiss forever after first view (`StorageService.hasSeenTutorial`)

---

## Phase 6 — Competition (Weeks 11–12)
*Goal: social hooks, no backend yet*

- [ ] **Local leaderboard** (device only)
  - Top 10 scores stored locally with date + fruit achieved
  - No backend, no auth, no privacy concerns

- [ ] **Social sharing**
  - Screenshot score card + "I reached 🍉 Watermelon!" text
  - Uses `share_plus` package (no backend needed)
  - Add share button to game-over and win overlays

---

## Phase 7 — Scale (Month 4+)
*Only build these once there are real users*

- [ ] **Cloud leaderboard** (Firebase or Supabase)
  - Global rankings
  - Requires auth (anonymous OK for leaderboards)

- [ ] **Galaxy / Neon themes** (already locked in store UI)

- [ ] **PvP Battle Mode**
  - Two players merge simultaneously
  - Merges send "junk" fruits to opponent
  - Requires real-time backend — do not attempt before Phase 6

---

## Parking lot (ideas, not committed)
- Accelerometer shake as alternative to Shaker button
- Seasonal themes (Halloween, Ramadan, Eid)
- Replay of best session
- Achievement badges ("First Watermelon", "100 Merges", etc.)
- Accessibility: colorblind mode, larger tap targets
