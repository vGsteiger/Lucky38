pragma solidity ^0.4.25;

//  Blackjack smart contract to be deployed on Rinkeby testnet
//  Contributors:
//    Tim Keller and Viktor Gsteiger

// Current version: 22.10.2019
// TODOs for V1 due 04.11.2019

contract BlackJack {

  // DECLARATION START

  // Habe mich dafür entschieden, weil wir so ganz einfach ein Spiel pro
  // pro Spieler haben können, sonst haben wir ja bald ein Problem mit
  // verschiedenen Spielern.
  struct Game {
    uint256 _currentBalance;
    uint256 _randomNumber;
    bool _turn;
    bool _init;
  }

  private int numberOfGames;

  // So speichern wir am einfachsten die verschiedenen Spieler:
  mapping(address => Game) games;

  // DECLARATION END

  // ----------

  // MODIFIERS START

  // Modifiers

  // To be able to only use a function during a game
  modifier inRound() {
    require(games[msg.sender]._turn == true, "No game running.");
    _;
  }

  // To be able to only use a function after or before a game
  modifier outRound() {
    require(games[msg.sender]._turn == false, "Game running.");
    _;
  }

  modifier onlyInitialisedPlayer() {
    require(games[msg.sender]._init == true, "You are not logged in yet.")
  }

  // MODIFIERS END

  // Functions

  //TODO: randomNumber, placeBet, cashOut, deal, hit, stand, showTable

  // Funktion, welche beim ersten Einzahlen (bzw jedem weiteren) ausgeführt wird.
  function setPlayer(address _address, uint256 _newBet) {
    var game = games[_address];
    if(game._init == false) {
      game._currentBalance = _newBet;
      game._init = true;
    } else {
      game._currentBalance += _newBet;
    }
  }

  function getNumberOfGames() {
    return numberOfGames;
  }
}
