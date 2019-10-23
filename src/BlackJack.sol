pragma solidity ^0.4.25;

//  Blackjack smart contract to be deployed on Rinkeby testnet
//  Contributors:
//    Tim Keller and Viktor Gsteiger

// Current version: 22.10.2019
// TODOs for V1 due 04.11.2019

contract BlackJack {

  // DECLARATION START

  address private _playerAddress;

  // TODO: Ist noch nicht ausgefleischt, wäre aber eine schöne
  // Version, die Karten zu speichern
  struct Hand {

  }

  bool private _turn;

  uint256 private _currentBalance;
  uint256 private _randomNumber;

  // DECLARATION END

  // ----------

  // MODIFIERS START

  // Modifiers
  // Control whether Address is in fact player
  modifier isPlayer() {
    require(msg.sender == _playerAddress);
    _;
  }

  // To be able to only use a function during a game
  modifier inRound() {
    require(_turn == true, "No game running.");
    _;
  }

  // To be able to only use a function after or before a game
  modifier outRound() {
    require(_turn == false, "Game running");
    _;
  }

  // MODIFIERS END

  // Functions
  //TODO: randomNumber, placeBet, cashOut, deal, hit, stand, showTable
}
