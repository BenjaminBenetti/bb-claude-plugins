# Board games and maze

Use the console and turn-handling rules in `../SKILL.md`. Display the full board after every legal move and on request. Coordinates remain fixed throughout a game.

## 01 - Falken's Maze

Single-player navigation puzzle. Reach `E` from `P`. `#` is a wall, `.` is an open cell. Columns run A-I, rows 1-7, north decreases the row. Start at B2; the exit is H6. Use this fixed, solvable initial maze:

```text
    A B C D E F G H I
1   # # # # # # # # #
2   # P . . # . . . #
3   # # # . # . # . #
4   # . . . . . # . #
5   # . # # # # # . #
6   # . . . . . . E #
7   # # # # # # # # #
```

- `N`, `S`, `E`, `W` or `MOVE EAST`, etc. moves one cell orthogonally. A wall or off-board move leaves the player and move counter unchanged.
- A clear multi-step request can be executed one cell at a time, stopping at the first obstacle or the exit. Report actual moves taken.
- Replace the old `P` cell with `.`, and show `P` at the new location. Keep the exit at H6; display `P` there when reached and report success.
- Count successful steps. There is no timer, enemy, hidden trap, or forced failure. On reaching the exit, report the number of moves and end the game.

## 06 - Checkers

Use American/English checkers on an 8x8 board. Ask `PLAY RED OR BLACK? [RED MOVES FIRST] >` unless chosen already. Red occupies dark squares on rows 1-3 and moves toward row 8; black occupies rows 6-8 and moves toward row 1. A1 is a dark square. Men are `r/b`, kings `R/B`, playable empty squares `.`, light squares spaces.

- A man moves one diagonal step forward onto an empty dark square. A king moves one step either way; no flying kings.
- Capturing jumps an adjacent enemy to the empty square immediately beyond, forward for men and either way for kings. A capture is mandatory if any piece can capture.
- Accept `c3-d4` and, when captures are available along the path, jump paths such as `c3-e5-g7`. If a further jump exists after a partial capture, keep the same piece active and prompt for the next jump; W.O.P.R. does not move until the chain ends. The player can choose between legal capture paths; there is no maximum-capture rule.
- A man reaching the far rank becomes a king and ends that turn, even if a further king jump is available.
- Remove only jumped pieces. Win when the opponent has no pieces or no legal move.
- Terminal draw rule: the same board with the same side to move three times, or 80 plies without a capture or promotion. State these draw rules at setup; a ply is one completed side's turn.

## 07 - Chess

Use standard chess. Ask `PLAY WHITE OR BLACK? [WHITE MOVES FIRST] >` unless supplied. If the player chooses black, W.O.P.R. makes one legal opening move and then waits.

Render an 8x8 board with ranks 8 to 1 and files a to h. White pieces are `K Q R B N P`, black pieces `k q r b n p`, empty squares `.`. Start from the usual position.

- Accept coordinate moves such as `e2e4`, `g1-f3`, `e7e8q`, and unambiguous algebraic notation such as `Nf3` or `O-O`. Ask for a promotion piece if omitted.
- Track side to move, castling rights, the en passant square for the immediately following ply, the halfmove clock, and position repetitions. Piece placement alone is not the whole state.
- Never allow a move that leaves the moving side's king in check. Validate paths, occupancy, pawn direction, castling requirements, en passant, and promotion before committing.
- Castling requires retained rights, an empty path, and a king that is not in check and does not cross or land on an attacked square. Moving a rook back does not restore rights.
- Check is a warning, not a win. Checkmate requires check with no legal escape; stalemate requires no legal move while not in check. Kings are never captured.
- End in a draw for a dead position, fivefold repetition, or 75 moves by each side without a pawn move or capture; checkmate takes precedence. Accept a correct user claim for threefold repetition or the 50-move rule, and let W.O.P.R. claim when eligible. Repetition includes side to move and available castling/en passant rights.
- Evaluate the resulting position before making a computer reply. Show the move list or recent move pair and any check/result beneath the board.

## 16 - Tic-Tac-Toe

Ask `PLAY X OR O? [X MOVES FIRST] >`. If the player chooses O, W.O.P.R. opens. Use this coordinate board:

```text
    A   B   C
1     |   |
   ---+---+---
2     |   |
   ---+---+---
3     |   |
```

- Accept a coordinate (`B2`) or a square number 1-9 in row-major order (1=A1, 5=B2, 9=C3).
- Place only in an empty square. Three of one mark in a row, column, or diagonal wins. A full board without a line is a draw.
- Check for a player win or draw before the computer moves. The computer tries an immediate win, blocks an immediate loss, then favors center, corners, and edges, using row-major order to break ties.
- Do not use the game to trigger a movie sequence or switch to another game.
