# Lucky 38 Smart Contract

Welcome to the most exciting casino smart contract of the Lucky 38 Casino.
This smart contract consists of a runnable version of Blackjack which will be deployed on the Rinkeby Testnet.

## Rules of the game:

1. A player joins a game and invests a sum of ether (more than 49 and less than 1'500'000 wei), which is his playing capital. Of this sum, 5% will get collected as a fee to the casino.
2. The player then chooses a bet between 2 and 500 wei for the new game. The player can top up this amount as far as the player wants until he has no more funds.
3. Furthermore, the player can start the game with the function deal. He will get dealt two cards as well as the dealer. The Ace will be accounted for automatically. If the player reached blackjack he then has won and receives his bet back plus 5% of the bet, which will be the thing that happens every time the player wins.
4. If the dealer received an ace in his first card, the player can then insure his game. If he has his game insured and the dealer receives a blackjack, then the player doesn't loose his bet.
5. Now the player can choose to either get dealt another card or stand to receive the result of the game.
6. If the player chose to hit another card, that card will get evaluated by the contract and either the player wins with a blackjack and the dealer doesn't, the game ends in a draw with both the dealer and the player having a blackjack (then the player just receives his bet back, which will be the action every time the game ends in a draw), busts because he went over 21 (in which case the player will loose his bet) or can take up another card.
7. If the player chose to stand the game will get evaluated and the player either wins because he had blackjack and the dealer did not or he won because he had more than the dealer. Or the game ends in a draw if both had the same card value. Or the player looses if he had less than the dealer.
8. The player can then either cash out or play again.

## Interface
The game can be played via remix by connecting to the contract address and having a metamask add on on the rinkeby testnet with sufficient funds. 

## Demo
The demo will be aviable soon.

## About the Project:
This was a project for the lecture 52354-01 Smart Contracts and Decentralized Blockchain Applications in the autumn semester of 2019.

### Team members:
  * Tim Keller 17-057-282
  * Viktor Gsteiger 18-054-700
