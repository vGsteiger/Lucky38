pragma solidity 0.4.4;

//  Blackjack smart contract to be deployed on Rinkeby testnet
//  Contributors:
//    Tim Keller and Viktor Gsteiger

// Current version: 22.10.2019
// TODOs for V1 due 04.11.2019

contract BlackJack {

  // DECLARATION START

  // Habe mich dafür entschieden, weil wir so ganz einfach ein Spiel pro
  // Spieler haben können, sonst haben wir ja bald ein Problem mit
  // verschiedenen Spielern.
  struct Game {
    address _playerAddress;
    uint256 _currentBalance;
    uint256 _currentBet;
    uint256 _randomNumber;
    bool _turn;
    bool _init;
    Card _currentHand[22];
  }

  struct Card {
    uint256 _value;
  }

  uint private _numberOfGames;
  uint private _nonce;
  uint private _ethLimit = 1500000 wei;

  // So speichern wir am einfachsten die verschiedenen Spieler:
  mapping(address => Game) games;

  // DECLARATION END

  // ----------

  // CONSTRUCTOR
   constructor() public {
       _nonce = 1;
       _numberOfGames = 0;
   }

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
    require(games[msg.sender]._init == true, "You are not logged in yet.");
    _;
  }

  modifier isPlayer() {
    require(games[msg.sender]._playerAddress == msg.sender, "You are not the right player.");
    _;
  }

  // MODIFIERS END

  // Functions

  //TODO: deal, hit, stand, showTable

  // Contract bezahlen:
  function payContract() outRound isPlayer public payable returns (string) {
    // Nur der Spieler darf sich selber Geld zuweisen
    Game game = games[msg.sender];

    require((game._currentBalance+msg.value) <= _ethLimit, "Too much invested.")

    setPlayer(msg.sender,msg.value);

    return "Contract paid.";

  }

  function placeBet(uint256 bet) onlyInitialisedPlayer isPlayer outRound public returns (string) {
    // Check ob Wette im Rahmen
    require(bet >= 1 wei && bet <= 10000 wei, "Bet limit is 1 wei - 10000 wei.");
    // Check ob Wette nicht zu hoch
    require(games[msg.sender]._currentBalance >= bet, "You can not afford to play this expensive.");
    // Balance des Spielers aktualisieren
    games[msg.sender]._currentBalance -= bet;
    // Aktuelle Wette aktualisieren
    games[msg.sender]._currentBet += bet;
    // Runde starten
    games[msg.sender]._turn = true;
    // Anzahl Spiele erhöhen
    numberOfGames++;

    return deal();
  }

  function withdraw() onlyInitialisedPlayer isPlayer outRound public {
    uint256 balance = games[msg.sender]._currentBalance;
    games[msg.sender]._currentBalance = 0;
    address(msg.sender).transfer(balance);
  }

  // Funktion, welche beim Einzahlen ausgeführt wird.
  function setPlayer(address _address, uint256 _investment) public {
    var game = games[_address];
    if(game._init == false) {
      game._playerAddress = _address;
      game._currentBalance = _investment;
      game._currentBet = 0;
      game._init = true;
    } else {
      game._currentBalance += _newBet;
    }
  }

  function countCards() public onlyInitialisedPlayer returns (uint) {
    Card cards[] = games[msg.sender]._currentHand;
    uint amount = 0;
    for (uint i = 0; i < cards.length; i++) {
      amount = amount + cards[i];
    }
    return amount;
  }

  function getNumberOfGames() public returns (uint){
    return numberOfGames;
  }

  function random() private returns (uint) {
  uint random = uint(keccak256(now, msg.sender, _nonce)) % 14;
  nonce++;
  return random;
  }
}
