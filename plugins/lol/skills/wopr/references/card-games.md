# Card games

## Shared table rules

- Use a standard 52-card deck, no jokers. ASCII card IDs are `AS`, `10H`, `QD`, `2C`, etc. Suits are clubs, diamonds, hearts, spades. Ace handling depends on the selected game.
- Shuffle and commit a complete deck order before dealing. Track deck, hands, discards, and cards in completed tricks separately; a card exists in one location only. Never reshuffle a live hand unless its rules explicitly call for it.
- The player sees their hand, public cards, scores, whose turn/phase it is, and legal command forms. Opponents' cards remain hidden until a reveal is required. Computer decisions cannot use another seat's private cards or future deck order.
- Pause at each human decision. Resolve other seats only until the next human turn. A draw followed by a discard is two phases, not permission to discard for the player.
- On a completed hand, show the result and ask `DEAL / GAMES / QUIT >`. `DEAL` starts the next hand with retained match scores if relevant, and a fresh deck. At a match result, use `NEW / GAMES / QUIT >` instead.
- All chips and stakes are fictional score counters.

## 02 - Black Jack

Variant: one-player blackjack against the dealer, 100 starting chips, default stake 10, blackjack pays 3:2, dealer stands on all 17s, including soft 17. No split, insurance, surrender, or doubling. State the variant at setup.

1. Prompt `BET [10] >`; accept a positive even integer no greater than the bankroll, ensuring half-chip payouts are unnecessary. `DEAL` here accepts the default if affordable; otherwise prompt for a smaller valid bet.
2. Deduct the bet and deal player, dealer, player, dealer. Show both player cards and just the dealer's upcard. Aces count as 11 unless that would bust, then as 1; face cards count as 10.
3. Check both two-card naturals immediately. Reveal and settle if either has blackjack: both natural is a push; only player natural returns 2.5 times the deducted stake; only dealer natural loses. A natural outranks a non-natural 21.
4. Accept `HIT` or `STAND`. A hit takes exactly the next card. Bust settles as a loss immediately. At 21, automatically stand. Otherwise return to the player's decision.
5. On stand, reveal the hole card and draw until the dealer reaches at least 17 or busts. Player win returns twice the deducted stake; tie returns the stake; loss returns nothing.
6. Show player/dealer totals, hand profit or loss, and bankroll. A bankroll below 2 ends the session as out of playable chips; otherwise `DEAL` returns to the bet prompt.

## 03 - Gin Rummy

Two-player gin rummy, first to 100 points. Player deals first; alternate dealer each hand. Deal ten cards each and one face-up discard; the non-dealer acts first. Terminal variant: the first turn has the same draw choices as later turns, with no opening upcard-offer sequence.

- On each turn `DRAW STOCK` takes the top hidden stock card; `DRAW DISCARD` takes the top visible discard. Then show the eleven-card hand and prompt `DISCARD <card>`, `KNOCK <card>`, or `GIN <card>`.
- Discard exactly one held card. A card drawn from the discard pile cannot be returned on that same turn. Ordinary discard ends the turn; the opponent then draws and discards unless they end the hand.
- Melds are sets of three/four equal ranks or same-suit runs of at least three consecutive ranks. Aces are low only. A card can belong to one meld. Deadwood is the minimum unmatched value over all legal meld arrangements: ace=1, numbered cards face value, face cards=10.
- `KNOCK <card>` discards and ends the hand only if the remaining ten cards have at most 10 deadwood. `GIN <card>` requires zero. Any legal declaration with zero deadwood is scored as gin, including one entered as `KNOCK`. Validate eligibility before discarding; an invalid declaration leaves the eleven-card decision state intact.
- Terminal meld tie rule: fix the knocker's minimum-deadwood arrangement before evaluating layoffs. If several arrangements tie, sort card IDs alphabetically within each meld, sort those meld strings alphabetically, join with `|`, and use the alphabetically first resulting string. Explain this automatic rule in `RULES`; do not choose a different arrangement after inspecting opponent layoffs.
- Reveal both hands at a legal declaration. With gin, no layoff: declarer scores 25 plus opponent deadwood. With a non-gin knock, allow the other side to reduce deadwood by laying off onto the knocker's melds. Use the best legal layoff automatically and show it. If knocker's deadwood is lower, they score the difference; otherwise the opponent scores 25 plus the difference, including ties as an undercut.
- With two stock cards remaining at the start of a turn, the hand is a draw with no score. On 100 points or more, end the match; otherwise offer another hand. W.O.P.R. takes a legal gin/knock when available and otherwise tries to reduce its own deadwood.

## 04 - Hearts

Four seats: user SOUTH, computer WEST/NORTH/EAST. Play order is SOUTH, WEST, NORTH, EAST, cyclically. Deal 13 each; ace high. Terminal variant: no passing; normal trick play and scoring. State `HEARTS - NO-PASS VARIANT` at setup.

- The holder of `2C` leads it to the first trick. `PLAY <card>` must follow the led suit if possible.
- If void in the led suit, any card is legal except that hearts and `QS` cannot be discarded on the first trick unless the hand contains nothing else eligible. Hearts cannot be led until a heart has been played on an earlier trick, unless the leader holds only hearts. Any played heart breaks hearts, including a forced heart lead.
- Highest card of the led suit wins; there is no trump. Winner leads next. Show each trick's cards, winner, and current points taken.
- Each heart is 1 penalty point; `QS` is 13. On all 13 tricks, add penalties to match scores. If one seat takes all 26, give that seat 0 and each other seat 26 instead.
- End the match when any total reaches 100. Lowest total wins; equal lowest totals share the win. Otherwise offer the next hand. Bots try to avoid penalty tricks using their own hands and public play.

## 05 - Bridge

Variant: **open-hand no-trump minibridge**, a compact bridge adaptation without an auction, bidding systems, or vulnerability. The user is SOUTH and controls NORTH as dummy; W.O.P.R. plays WEST and EAST. Declare this variant before dealing.

1. Deal 13 cards to each seat. Show SOUTH and NORTH. Keep EAST and WEST hidden. Prompt `CONTRACT TRICKS [7-13] >`; accept a target from 7 through 13.
2. WEST leads first. Order is SOUTH, WEST, NORTH, EAST, cyclically. SOUTH controls both partnership hands, so stop whenever either SOUTH or NORTH must play, with a seat-specific prompt such as `NORTH PLAY >`.
3. `PLAY <card>` plays from the prompted seat only. Follow suit if possible; otherwise any card is legal. Ace high, highest card in led suit wins. No trumps. The trick winner leads next.
4. After 13 tricks, let `T` be SOUTH+NORTH tricks and `C` the contract. If `T >= C`, the partnership wins and scores `10*C + (T-C)`; otherwise W.O.P.R. wins and the partnership scores `-10*(C-T)`.
5. Report contract, tricks, and score. This is one-deal play, not duplicate-bridge scoring. Offer another independent deal. Computer seats use only their own hand and the visible SOUTH/NORTH hands plus played cards.

## 08 - Poker

Variant: heads-up five-card draw, fixed bets, no all-ins or side pots. Each seat starts with 100 chips. Ante 5 each; fixed bet 5; at most one raise per betting round. Alternate the first actor each hand; user starts the first hand. Explain these limits at setup.

1. A seat needs at least 25 chips to begin a hand (5 ante plus the maximum 10 in each of two betting rounds). If either cannot afford that, end the match; higher stack wins, equal stacks draw. Otherwise deduct antes into the pot and deal five cards each.
2. First betting round: when nothing is owed, `CHECK` or `BET`; facing a bet, `CALL`, `RAISE`, or `FOLD`. `BET` adds 5. `RAISE` pays the outstanding amount plus 5, and can happen once in the round. A checked-to player can bet. End the round on two checks, a call that matches the live bet/raise, or a fold. Track contributions so a bettor facing a raise owes only the difference.
3. If neither folds, each seat chooses `DRAW <0-3 held card IDs>` or `STAND PAT`, in first-actor order. Discard selected cards together and replace from the stock. Draw choices are private; show only how many each opponent replaced. Do not return discards to the stock.
4. Run a second betting round with the same first actor and reset raise allowance, then reveal at showdown.
5. Rank hands: straight flush, four of a kind, full house, flush, straight, three of a kind, two pair, one pair, high card. Break ties lexicographically by made-hand ranks then kickers. Ace can be low in A2345 only; that straight is five-high. Suits do not break ties.
6. Award the pot to the winning seat, or split evenly on a tie. A fold awards the pot without requiring the winner to reveal. Chips on the table plus the pot always total 200. Show stack changes and offer another hand unless the minimum-buy-in termination rule applies.

W.O.P.R. makes betting and drawing choices from its own hand and observed actions; it does not inspect the user's cards to decide.
