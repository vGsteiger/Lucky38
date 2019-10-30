pragma solidity 0.4.26;

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
    uint _currentBalance;
    uint _currentBet;
    uint _randomNumber;
    uint _cardTotal;
    bool _turn;
    bool _init;
    Cards[22] _currentHand;
  }

  struct Cards {
    uint256 _value;
    string _name;
  }

  uint private _numberOfGames;
  uint private _nonce;
  uint private _ethLimit = 1500000 wei;
  address private _owner;

  // So speichern wir am einfachsten die verschiedenen Spieler:
  mapping(address => Game) games;

  // DECLARATION END

  // ----------

  // CONSTRUCTOR
   constructor() public {
       _nonce = 1;
       _numberOfGames = 0;
       _owner = msg.sender;
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
  function payContract() outRound public payable {
    require((games[msg.sender]._currentBalance+msg.value) <= _ethLimit, "Too much invested.");

    setPlayer(msg.sender,msg.value);

  }

      function() external payable {
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
    _numberOfGames++;

    return deal(msg.sender);
  }

  function deal(address _address) internal returns (string) {
    clearCards(_address);
    games[_address]._cardTotal = 0;
    _numberOfGames++;

    // Player card 1:
    (games[_address]._currentHand[0]._value,games[_address]._currentHand[0]._name) = random();

    if (games[_address]._currentHand[0]._value == 1) {
        games[_address]._currentHand[0]._value = 11;
    }

    // Player card 2:
  }

  function withdraw() onlyInitialisedPlayer isPlayer outRound public {
    uint256 balance = games[msg.sender]._currentBalance;
    games[msg.sender]._currentBalance = 0;
    address(msg.sender).transfer(balance);
  }

  // Funktion, welche beim Einzahlen ausgeführt wird.
  function setPlayer(address _address, uint256 _investment) private {
    if(games[_address]._init == false) {
      games[_address]._playerAddress = _address;
      games[_address]._currentBalance = _investment;
      games[_address]._currentBet = 0;
      games[_address]._init = true;
    } else {
      games[_address]._currentBalance += _investment;
    }
  }

  function getNumberOfGames() public view returns (uint){
      return _numberOfGames;
  }

  function random() private returns (uint, string) {
    uint value = uint(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty,_nonce++)))%14);
    if (value == 1) {
        return (value, 'Ace');
    } else if (value == 2) {
        return (value, 'Two');
    } else if (value == 3) {
        return (value, 'Three');
    } else if (value == 4) {
        return (value, 'Four');
    } else if (value == 5) {
        return (value, 'Five');
    } else if (value == 6) {
        return (value, 'Six');
    } else if (value == 7) {
        return (value, 'Seven');
    } else if (value == 8) {
        return (value, 'Eight');
    } else if (value == 9) {
        return (value, 'Nine');
    } else if (value == 10) {
        return (value, 'Ten');
    } else if (value == 11) {
        return (10, 'Jack');
    } else if (value == 12) {
        return (10, 'Queen');
    } else if (value == 13) {
        return (10, 'King');
    }
    if (_nonce > value) {
        _nonce = (value % 3) -1;
    }
  }

  function clearCards(address _address) private {
    for(uint i = 0;i < games[_address]._currentHand.length; i++) {
      games[_address]._currentHand[i]._value = 0;
    }
  }

  function getPlayerFunds() public view returns (uint) {
      return games[msg.sender]._currentBalance;
  }

}
