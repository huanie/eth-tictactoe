Group: Yuhao Hu, Shidan Wen, Huan Thieu Nguyen
= TicTacToe
== Game Idea
- Two players access the game via contract address
- Player place symbol alternatively on a 3*3 grid
- Enable bet increase, surrender during the game. 
- Limited time for making a move 
- Only if three symbols in a row, column or diagonal, the game will be marked as a win 
- No free place or no possible to win, the game will be marked as a draw
- The potential winning possibility of the player will be displayed (not in smart contract, done in frontend)
- Player can choose to play against another player or against the computer 

== Smart Contract
- `dev`/Developer: those person deploying smart contracts, and they shall receive a commission fee from specific circumstances
- Game Hall: allows using the same smart contract to create multiple games
  - Simple (Game ID (`uint256`) #sym.arrow.r Game Session) mapping
- Game Session: State of the game in the game hall
  - 2 player addresses (`playerX`, `playerY`)
  - `board`: 3x3 board array (`Cell[3][3]`)
  - `turn`: address of the player that is allowed to place their marker
  - `state`: state of the game (running, waiting for another player, cancelled, draw, who won)
  - `lastMoveTime`: the time of the last move (for allowing automatic lose on idle)
  - `prizePool`: the total winning price (minus a variable fee) on win or half of it as draw price
  - `bet`: increases the prize pool, is kept to check the other player's bet, resets to 0 if both bets finished
  - `raiser`: remember who started the bet
  - `targetDeposit`: the amount of increased bet the opponent must match
  - `raisedDeadline`: deadline for matching the raised bet
- Game variables:
  - `moveTimeout`: maximum allowed time (60 seconds) for a player to make a move on the board
  - `feeBps`: the platform fee (2.5%) applied during payout and draw refunds
- Reentrancy protection: implement a simple reentrancy guard to prevent reentrancy attacks 

== Rules and play
- `createGame` creating a Game:
  - provide a entry requirement by staking currency
  - return a game ID
- `joinGame` joining a Game:
  - does the game exists?
  - is someone waiting for an opponent?
  - is the staked currency enough?
  - setup the game session to a runnable state
  - once the game state is set to playing, the first player will have 60 seconds to make his first move
- `cancelGame` canceling a Game:
  - the person that deploys the contract can cancel the game
  - does the game exist?
  - is someone waiting for a opponent?
  - only creator can cancel the game and the staked currency will be returned without fee
  - the state of the game will be set to cancelled

=== During the game
- `move` Move:
  - check the state of game, which should be playing 
  - make sure player can only move in their own turn 
  - make sure only the cells of the 3*3 board can be placed
  - make sure only the empty cell can be placed
  - after the movement check for a win or a draw
  - early termination check: check whether the game can still be won by at least one player, if there is no future winning possibility for both players, the game will be automatically marked as a draw
- `raise` Raise a bet
  - gamer can increase your bets during play.
  - If the opponent refuses to raise the stakes or Surrender, they are declared defeated
- `matchRaise` Match the bet
  - the opponent need to match it in certain time and raise the exactly the same amount of stakes
- `claimBetTimeout` Claim Bet Timeout
  - if one player increases the stacks, the opponent will have 60 seconds to match the bet, if exceeded, raiser will win
- `surrender` Surrender
  - If players feel their win rate is too low or they don't want to match the bet, they can surrender immediately
  - Surrendering will let the opponent win all money
- `claimTimeout` claim Timeout:
  - no move within 60 seconds, current turn will lose and the opponent will win

=== After the game
- Win or lose
  - `isWin`: three symbols in a raw, column and diagonal
  - `canPlayerStillWin`: whether a side can still form a line (any row/column/ diagonal with on opponent piece)
- Draw 
  - `isDraw`: there is no empty place
- `claim` Manually trigger payout/ refund
  - in case something goes wrong then the player can claim for a win and the corresponding fund will be transferred to the winner 
  - normally it is automatically settled
- Payout
  - `_payoutWinner`: Whether you win or lose, you need to pay the fee to the Dev account
  - `_refundDrawWithFee`: Even in draw situation, players need to pay the fee to the Dev account first and win the half the remaining winning price

== Probability of TicTacToe
- The theoretical maximum possible number of states appears to be 3^9 = 19,683 (with 3*3 slots and 3 different status), the actual number of it is significantly reduced once the game rules is taken into account:
  - Players take turns placing one piece at a time, alternating between X and O,For example, if there are 5 Xs on the board, there can be at most 4 Os
  - The game ends immediately when one player wins, and no further pieces can be placed
  - The game proceeds in a specific order: X moves first, followed by O, certain states (such as a board containing only O pieces without any X) are impossible to achieve
  - the actual number of legitimate states is then 5,478
- the Tic-Tac-Toe is also a perfectly symmetrical shape:
  - considering rotations and reflections of the board are equal, there are only 765 distinct states, which is quite simple for computers
- Based on the current situation of a player, we can use this to calculate how high the player's possibility of winning still is
  - we assume that the player's next move is completely random

== Events
Use events to update a frontend.
- GameCreated: For listing showing a game hall list
- GameJoined: To update the game hall list
- MoveMade: For the running game, update the board
- GameEnded: Update the game hall list and game interface
  - Surrendered: Same as GameEnded
  - Timeout: Same as GameEnded (someone did not make a move before timeout expires)
  - BetTimeout: Same as GameEnded (someone did not match the bet before the timout)
  - GameCancelled: Same as GameEnded
- Raised: Update the interface to let the other person know that it is time to increase their bet
- RaiseMatched: Show the person that started betting that the bet is matched

= Insights
External functions must be programmed in defensive fail-first principle otherwise the rules of the game will be broken.

== Timeout
- There is no `Timer(time).call(function)`
- Time of last function call must be stored (`block.timestamp`)
- Provide a claim timeout function where someone can manually claim the reward
- The client needs to do the timeout logic itself and call the claim function

