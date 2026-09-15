# Tactical games

These are compact, fictional board games. State the selected game's objective and its terminal variant at setup. Use invented units, square coordinates, and abstract resource counters throughout.

## 09-13 - Shared tactical engine

Use a 5x5 grid, columns A-E left to right and rows 1-5 top to bottom. The player controls `P1` at A5 and `P2` at B5; W.O.P.R. controls `W1` at E1 and `W2` at D1. All positions, HP, shields, and supplies are public. An empty cell is `.`, an impassable cell `#`, and an unoccupied objective `O`. If a unit occupies an objective, show the unit on the board and list the underlying objective below it.

Each side starts with 8 shared supply, 0 points, and no shields. Round limit is 12. Apply the chosen scenario:

| Game | Player / computer HP per unit | Movement per action | Fire range | Impassable cells | Objectives | Points to win |
| --- | --- | --- | --- | --- | --- | --- |
| 09 Fighter Combat | 2 / 2 | 2 / 2 | 2 / 2 | None | C3 | 3 |
| 10 Guerrilla Engagement | 2 / 3 | 2 / 1 | 1 / 1 | C2, C4 | C3 | 3 |
| 11 Desert Warfare | 3 / 3 | 1 / 1 | 2 / 2 | B2, D4 | C3 | 3 |
| 12 Air-to-Ground Actions | 2 / 3 | 2 / 1 | 2 / 1 | None | B3, D3 | 4 |
| 13 Theaterwide Tactical Warfare | 3 / 3 | 1 / 1 | 2 / 2 | C2, C4 | B3, D3 | 4 |

Distances are Manhattan distance: column difference plus row difference. Movement is orthogonal through empty, passable cells, up to the unit's allowance. Pieces cannot share a cell or move through other pieces. Fire uses distance only; these abstract games do not add line-of-sight or diagonal-movement rules.

### Player commands

- `MOVE P1 B4`: move the named unit to a reachable cell. If several paths work, use a shortest legal path. Moving zero cells is not a move; use `WAIT`.
- `FIRE P1 W2`: spend 1 supply to deal 1 damage to the named enemy within range. If the target has a shield, consume that shield instead of HP. Zero-HP units are removed immediately.
- `GUARD P1`: give that unit one shield, retained until hit. Maximum one shield per unit; guarding an already-shielded unit is invalid.
- `RESUPPLY`: restore 2 shared supply, capped at 8. Invalid if already at 8.
- `WAIT`: take no action.

One legal player command consumes one round, with one computer command in response. Invalid moves and console commands consume nothing. There are no free extra attacks or moves.

### Resolve a round

1. Validate the player's action. If legal, increment the round once and perform it. If all computer units are destroyed, end immediately with a player win; the winning action still counts as a round.
2. W.O.P.R. takes one legal action using the policy below. If all player units are destroyed, end immediately with a computer win.
3. Each side gains 1 point for each objective occupied by one of its surviving units. Unoccupied objectives have no owner; there is no retained capture after leaving a cell.
4. If either side reaches its points-to-win threshold, that side wins; if both do in the same round, higher points wins, equal points draws. Otherwise, after round 12 compare `3 * points + surviving HP`; higher wins, equal draws.
5. Redraw the full grid, unit HP/shields, side supplies/points, round, last actions, and next prompt. A final result also includes the board.

### Computer policy

Evaluate after the player's action. Tie-break unit choices by ID and cells by row then column.

1. If a legal shot can destroy an unshielded enemy, take it.
2. Otherwise, if a legal shot is available and supply remains, shoot the enemy with the lowest HP, then lowest ID, using the lowest-ID eligible attacker.
3. If an enemy is in range but supply is zero, resupply.
4. Otherwise, move a unit toward the nearest objective it does not already occupy. Choose the reachable unit/objective pair with the shortest legal path, then unit ID, then objective in row-major order. Follow the path by up to its movement allowance. Treat occupied destinations as unavailable; break equal path choices in row-major order. Do not move a unit already on an objective unless it has a legal shot under steps 1-2.
5. If no such move exists, guard the lowest-ID unshielded unit; if all are shielded, resupply when below 8, else wait.

## 14 - Theaterwide Biotoxic and Chemical Warfare

Variant: **containment exercise**. This menu entry is a single-player abstract hazard-control puzzle on a 5x5 grid, with no agents, recipes, dispersal calculations, or real-world targeting. At setup show `CONTAINMENT EXERCISE - CLEAR THE BOARD` and explain the following rules.

- Columns A-E and rows 1-5 use the same orientation as above. Two response crews, `P1` at A5 and `P2` at E5, start with no contamination under them. Hazards `H` start at B2, D2, and C3. Other cells are empty `.`.
- There are two action points per round and at most 12 rounds. The player can spend both points with the same crew or split them. Prompt again after the first action; advance the round only after the second. No computer combat moves occur.
- `MOVE P1 B4` spends one point and moves up to two orthogonal steps through empty cells. Crews cannot enter a hazard, a sealed cell, or the other crew's cell.
- `CLEAN P1 B2` spends one point and removes a hazard exactly one orthogonal cell from that crew. It becomes empty. There is no consumable cleaning stock.
- `SEAL P1 A4` spends one point and permanently seals an adjacent empty cell, shown as `#`. Seals block both crew movement and hazard spread; occupied or contaminated cells cannot be sealed.
- `WAIT` spends one point. Invalid inputs, help, and map requests spend none.
- After any clean, if no hazards remain, win immediately. Otherwise, after the second action, spread **one** new hazard: collect empty cells orthogonally adjacent to any hazard and select the first by row then column. Crews and seals are ineligible. If no cell is eligible, no spread occurs. Then increment the round and restore two action points.
- Lose if contamination reaches 10 cells, or if hazards remain after the spread at the end of round 12. A sealed but uncleared hazard still counts as remaining. No automatic final cleaning occurs.
- After every action display the entire board, crew positions, hazard count, round, remaining action points, and the next prompt. Also display the final board on a win, loss, or resignation.
