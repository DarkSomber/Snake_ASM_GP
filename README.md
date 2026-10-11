# Snake (x86 Assembly) — Feature Guide

A 16-bit x86 assembly Snake game (`.model small`, 80x25 text mode, drawn straight into video memory at `B800h`).
Source file: `Snake.asm`

Eat the red `*` food to grow and score. The game speeds up as your score climbs, and you win at a score of 255.
This document covers the features added on top of the basic game.

---

## Controls

| Key | Where | Action |
|---|---|---|
| Arrow keys | In game | Steer the snake (180° reversals are ignored) |
| `P` | In game | Pause and show the leaderboard |
| `Esc` | In game | Quit |
| `P` / `Esc` | Pause screen | Resume / quit |
| Up / Down | Name entry | Change the selected letter |
| Left / Right | Name entry | Move between the 5 letter slots |
| `Enter` | Name entry | Confirm the name |
| `Esc` | Name entry | Skip saving this run |
| `Space` / `Esc` | Death screen | Play again / exit |

---

## Pickups and obstacles

| Thing | Look | What it does |
|---|---|---|
| Food | red `*` | +1 length, +1 score |
| Immunity fruit | cyan `#` | Temporary invincibility (see below) |
| Shortening fruit | yellow `S` | Cuts the snake shorter |
| Rocks | gray `^` | Kill the snake on contact |
| Missiles | `!`, `X`, `-` / `|`, `*` | Random hazards (see below) |

### Immunity fruit (`I`)
- Lasts `immunity_duration` frames (50, about 3 seconds at the starting speed).
- While immune the snake passes through its **own body**, **rocks**, and **missiles and explosions**.
- The screen border still kills you.
- **Colour fade:** the head and body turn cyan when you eat the fruit. As the timer runs down the colour fades away **one cell at a time, tail first**, and the head is the last cell to turn green again.
- A new immunity fruit appears when the effect ends.
- If the effect ends while your head is on a rock or on your own body, you die immediately.

### Shortening fruit (`S`)
- Removes `shrink_amount` bytes from the tail (2 bytes = 1 cell).
- The snake never gets shorter than `min_snake_len` (4 bytes = 2 cells).
- The cut-off cells are erased from the screen.
- A new `S` appears right after you eat one.

### Rocks (`R`)
- `num_rocks` (10) rocks are placed when a game starts.
- They never spawn on the snake, the food, either fruit, or each other.
- Row 3, where the snake starts heading right, is kept rock-free (`start_lane_begin` / `start_lane_end`), so a rock can't kill you on the first move.
- The food and both fruits also avoid rocks when they respawn.
- Hitting a rock ends the game unless you're immune.

### Missiles
1. A **warning** appears: a flashing red `!` at the launch edge and a red `X` marking where the missile will explode.
2. The missile **flies** across the screen (`-` horizontally, `|` vertically). Touching it is fatal.
3. It **explodes** into a plus-shaped blast of white `*` that lasts about 10 frames. Touching any cell of the blast is fatal.

Direction, launch position and fuse (10–59 frames) are random. A new missile can appear roughly 1 frame in 16 when none is active.

### Redrawing
Missiles and explosions erase the cells they pass over, so food, fruits and rocks are redrawn every frame. Nothing disappears from the screen while still being live on the map.

---

## Leaderboard and name entry

### After you die
A panel opens in the middle of the screen:

1. **Game over** — shows your score and asks for your name.
2. **Name entry** — five slots, each holding a blank or a letter A–Z.
   - Up / Down change the highlighted letter (the cycle is blank, A to Z, back to blank).
   - Left / Right move between slots, and `Enter` confirms.
   - A name can be 1 to 5 letters. An all-blank name is saved as `ANON`.
   - `Esc` skips saving.
3. **Leaderboard** — shown after you confirm. `Space` plays again, `Esc` exits.

### Leaderboard rules
- Holds a maximum of **5** entries.
- Displayed **highest score first**. The top score is highlighted in yellow and empty slots show dashes.
- It keeps the **5 most recent runs**. When a 6th run is saved, the **oldest** one is deleted and replaced by the newest, even if the old one had a higher score.
- Equal scores are shown in the order they were played.
- It is only visible on the **death screen** and while the game is **paused**.

### Pause (`P`)
Freezes the game and shows the leaderboard over the middle of the screen. Pressing `P` again restores the covered game cells exactly as they were. `Esc` quits.

---

## Tuning constants

All near the top of the `.data` section.

| Constant | Default | Meaning |
|---|---|---|
| `immunity_duration` | 50 | Immunity length in frames |
| `immune_head_color` / `immune_body_color` | `0Bh` / `03h` | Snake colours while immune |
| `shrink_amount` | 2 | Bytes cut by the shortening fruit (2 per cell) |
| `min_snake_len` | 4 | Shortest snake the fruit leaves (bytes) |
| `num_rocks` | 10 | Number of rocks |
| `rock_icon` | `'^'` | Rock glyph |
| `max_scores` | 5 | Leaderboard size |
| `name_len_max` | 5 | Name length |
| `missile_state_warning`, `warning_frames`, `missile_max_steps_*` | see source | Missile warning time and range |

---

## Known quirks

- **Hex score:** the in-game score label (bottom right) shows two **hex** digits, as in the original game. The leaderboard shows **decimal** (000–255), so a score of 16 shows as `10` in game and `016` on the board.
- **No saving to disk:** the leaderboard lives in memory. It survives pressing `Space` to play again, but is lost when you exit the program.
- **Winning:** reaching score 255 ends the game with the win message and does not offer a leaderboard entry.
- **Generated labels:** labels named `JFIX_SKIP_n` were added to extend conditional-jump range for the assembler. Don't remove them.
