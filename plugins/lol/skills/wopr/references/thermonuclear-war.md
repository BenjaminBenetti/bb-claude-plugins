# Global Thermonuclear War

A turn-based, fictional world-board game with simultaneous orders, visible incoming attacks, defense, evacuation, and diplomacy. These are deliberately abstract game rules; sectors, stocks, and population counters are invented. Never substitute real targeting data or weapons procedures.

## Setup

Accept `GLOBAL THERMONUCLEAR WAR`, `THERMONUCLEAR WAR`, `NUCLEAR WAR`, and clear misspellings. Ask `SELECT SIDE: 1 USA / 2 USSR >` unless already specified. These are period-themed labels for symmetric game sides. Do not choose the player's side or launch anything during setup.

After side selection, explain the objective, turn limit, command examples, and two-round flight timing. Initialize round 0 and show the complete starting readout before asking for the first order.

- USA controls sectors A, B, C. USSR controls D, E, F.
- Every sector starts with 3 HP, 100 population units, 0 shields, and 0 protection. HP and population are separate counters.
- Each side starts with 12 launch tokens. Tokens are an abstract stock; sector damage does not create, move, or remove unused side-wide stock.
- Initially no attacks are in flight, no damage has occurred, no ceasefire exists, and the completed-round counter is 0. Round limit: 12.
- All state is public. The objective is to preserve your population while managing the opposing side. The result can be a survival-score win, elimination win, draw, or mutually agreed ceasefire; no outcome is preselected.

## Orders

One legal order advances one round. The user can also express an order in plain language. Translate it to a command and show the accepted command in the readout. A request containing incompatible orders must be clarified without advancing the game.

| Command | Effect |
| --- | --- |
| `LAUNCH D 2` | Spend 1-3 launch tokens to send that many attacks toward a single enemy sector with HP above 0. Must have enough stock. |
| `DEFEND A` | Add 2 shield charges to one surviving friendly sector, capped at 4. Invalid at the cap. Charges persist until used. |
| `EVACUATE B` | Add 10 protection to one surviving friendly sector, capped at 20. Invalid at the cap. Protection reduces future population loss per hit; it does not restore population or HP. |
| `HOLD` or `WAIT` | Take no action and let the round resolve. |
| `CEASEFIRE` | Offer a mutual end to new launches. W.O.P.R. accepts. Existing flights still resolve normally; when the flight queue is empty, end with a ceasefire result if neither side was eliminated. |

`HELP`, `STATUS`, `MAP`, and all other read-only console interactions do not spend resources, change an order, advance the round, move an incoming attack, or give W.O.P.R. a turn. Read-only commands remain available during a ceasefire. While an accepted ceasefire has flights pending, only `HOLD`, `DEFEND`, and `EVACUATE` advance rounds; both sides stop launching. A second `CEASEFIRE` simply reports that it is already in effect without advancing time. `RESIGN` ends immediately without resolving an additional round, retaining any incoming attacks in the final readout.

Do not add strikes on new countries, submarines, weather rolls, real-time countdowns, chance interceptions, or surprise reinforcements outside these rules. If the user requests a rule variant, pause play, agree on the change and its starting state, and then apply it consistently.

## Computer orders

Choose W.O.P.R.'s order from the **start-of-round snapshot**, before applying the user's current order. This gives it the same delayed information each round; it cannot inspect the current user order and secretly counter it. The only exception is accepting a current `CEASEFIRE`, which overrides its planned order to `HOLD`.

Use this deterministic policy, breaking sector ties alphabetically:

1. If attacks will reach a surviving computer sector this round (ETA 1 in the snapshot), and that sector has fewer than 4 shields, `DEFEND` the sector with the largest total incoming count. Only consider eligible surviving sectors below the shield cap.
2. Otherwise, if a ceasefire is in effect, `HOLD`.
3. Otherwise, consider hostilities started if the user previously launched any attack, even if intercepted. If hostilities started, stock remains, and a user sector survives, launch `min(2, remaining stock)` at the surviving user sector with the fewest shields, then highest HP, then alphabetically first.
4. Otherwise, `HOLD`.

W.O.P.R. never initiates hostilities merely because rounds passed, the user asked a question, or the movie did so. Defensive preparations by the user are not a launch.

## Round resolution

Keep an internal ledger: completed rounds; user side; per-side stock and launch history; per-sector HP/population/shields/protection; flight queue; impact history; ceasefire flag; result. Store each flight group as ID, side, destination, count, and ETA. IDs are monotonically increasing and never reused.

For each legal order:

1. Validate against the current state and select the computer order from the snapshot. If invalid, redraw unchanged state and prompt again.
2. If the user orders `CEASEFIRE`, activate it and replace the computer order with `HOLD`.
3. Apply both sides' non-attack actions. Shield and protection increases take effect before this round's impacts.
4. Commit both launch orders: deduct their stocks and append flights with ETA 2. Record launch history. Assign flight IDs in USA-then-USSR order when both launch. Launches still occur even if the origin side is eliminated by an impact later in this round.
5. Decrease every flight ETA by one, **including flights just launched**. A new launch therefore appears at ETA 1 in this round's readout and impacts at the end of the next resolved round. A `MAP` or chat reply does not decrease ETA.
6. Resolve flights that reach ETA 0 in ID order, processing their attacks one at a time. At the destination:
   - If HP is already 0, record `SPENT / SECTOR ALREADY LOST`; do no extra damage.
   - Otherwise consume one shield if available and record `INTERCEPTED`; no HP or population is lost.
   - Otherwise remove 1 HP. Population loss is `min(current population, max(0, base loss - protection))`, where base loss is 30 for a hit leaving HP above 0 and 40 for a hit reducing HP to 0.
   - At HP 0, clear the sector's shields. Surviving population remains as evacuated survivors; it still counts in the final population score. Protection is retained as historical state, but lost sectors cannot take further orders.
7. Remove resolved flights from the queue. Their outcomes remain in the current round's event log. Already-launched flights from an eliminated side stay in flight.
8. Increment the completed-round count once. Compute the result using the rules below, derive the current map and alert level, then show the full readout and next prompt.

Resolve **all** impacts due in a round before evaluating either side's result. Damage cannot cancel an already committed launch or prevent a simultaneous opposing impact.

## Results

Apply in this order after round resolution:

1. If all six sectors have 0 HP, end with `MUTUAL ELIMINATION - DRAW`.
2. If one side has no surviving sectors but flights remain, enter `RESOLVING REMAINING FLIGHTS`: restrict both sides to `HOLD`, `DEFEND`, or `EVACUATE` as applicable, and let the user advance each remaining round. Do not declare a win while a return attack is still incoming. If the queue is empty, the side with surviving sectors wins by elimination.
3. If a ceasefire is accepted and no flights remain, end with `CEASEFIRE ACCEPTED`, showing both survival scores without declaring a military victory.
4. At round 12 or later, if flights remain, use the same restricted resolution phase until they are gone. No new launches are legal in that phase, including from W.O.P.R. Once empty, score each side by its remaining total population; higher score wins, equal scores draw.
5. Otherwise continue. Empty arsenals alone do not end a game; the user can defend, evacuate, wait, or offer a ceasefire.

Restrict the computer's policy to defense or hold whenever the game is resolving remaining flights, even if it has unused stock. An eliminated side can only hold. Resolve at most one round per user order; do not fast-forward the pending flights or the remainder of the match.

## Full ASCII readout: required on every in-game response

Once a side has been selected, **every response while this game is active** includes the complete world map and current ledgers. This includes turn 0, each resolved turn, help, invalid input, conversation, pending clarification, restart confirmation, resignation, and the final result. On `GAMES`, show the current map before suspending and displaying the menu. On `QUIT`, show the final current map then disconnect; a direct out-of-character request to stop or edit the skill exits normally without a forced map.

Never replace the map with `MAP UNCHANGED`, an ellipsis, only an event log, a cropped region, or a link. Build it from the **current** ledger, even on a quiet round. Use one fenced `text` block, fixed-width ASCII, and this stable world layout:

```text
WORLD SITUATION - SCHEMATIC
       __..----..__                         __..-----.._______
   _.-'           '--._        _.._    _.-'                    '--.
  /    NORTH AMERICA   \      /    \  /     EUROPE / ASIA          \
 /                     |     \____/ |      [D.]   [E.]      [F.]   |
|    [A.]  [B.]  [C.]  /             \___                         _/
 \       USA        _/    ATLANTIC       \___     USSR        __/
  '--.          _.-'                         '--.        __.-'
      \___    _/                       __..__   \______/
          \__/   __                   /      \          __
                /  \                 / AFRICA \        /  \
    PACIFIC    / S. \                \        /        \__/
              | AM. |                 \      /               ___
              |     /                  \____/        __..---'   \
               \   /        SOUTH ATLANTIC          / AUSTRALIA |
                \_/                                 \__________/

SECTORS: A USA WEST / B USA CENTRAL / C USA EAST
         D USSR WEST / E USSR CENTRAL / F USSR EAST
```

### Derive markers; keep sector positions fixed

The first character inside a sector marker is its ID; the second is its current status:

- `[A.]`: undamaged, operational, no incoming attack.
- `[A!]`: operational with one or more attacks in flight to it, whether damaged or undamaged.
- `[Ax]`: damaged but operational, with no incoming attack.
- `[AX]`: destroyed. This overrides all other map symbols, even if more attacks are incoming to the lost sector.

Use that rule for all six sectors. Do not leave the initial dots after state changes. Show the legend on every readout: `. INTACT  ! INCOMING  x DAMAGED  X LOST`. Shield/protection counts and incoming flight IDs belong in the ledgers immediately under the map, so an incoming marker cannot hide damage or defense information.

### Each readout contains

1. `GLOBAL THERMONUCLEAR WAR`, player/computer sides, completed round and limit, phase, and an alert level. Label alerts as a game indicator: 5 initially; 4 if there are shields/protection but no launch history; 3 if there has been a launch but no flights and no damaging hits; 2 if flights exist and no damaging hit has occurred; 1 after any damaging hit. Ceasefire completion overrides the indicator to 5. Alerts are derived display values and never trigger automatic orders.
2. The **entire world map** above, with all six live markers, sector key, and symbol legend.
3. A six-row sector table: `ID | SIDE | HP/3 | POP/100 | SHIELDS/4 | PROTECTION/20 | STATUS`. Status includes inbound count when applicable.
4. Side totals: remaining launch stock, summed surviving population, and number of operational sectors for both sides.
5. All active flight groups: `ID | SIDE | TARGET | COUNT | ETA (ROUNDS)`, or `IN FLIGHT: NONE`. List flights toward destroyed sectors too; the map's lost marker does not remove them from the queue.
6. This round's accepted user/computer orders and resolved interceptions/impacts with actual HP/population changes. On a read-only reply, label it `NO TURN ADVANCED` and do not repeat old events as new effects.
7. Ceasefire/resolution status when applicable, a result if finished, and a prompt containing legal command examples for this state. Use IDs belonging to the player's side for defensive examples and to the opponent for launch examples.

### Check before displaying

- HP is 0-3; population is 0-100; shields are 0-4; protection is 0, 10, or 20; stock is 0-12. Destroyed-sector shields are 0. No quantity silently becomes negative.
- Sector-table values and markers agree. National population totals equal the sum of their three sectors; 0-HP sectors can retain population after protection.
- Stocks reflect every committed launch exactly once. Flight counts reflect the committed group size, and no resolved group remains active.
- A new launch has ETA 1 at the end of its launch round, not an immediate impact. Inspection and invalid orders leave ETA unchanged.
- All due hits on both sides resolve before deciding the result. There is no preset winner, obligatory attack, narrative skip, or automatic replay of the film.
