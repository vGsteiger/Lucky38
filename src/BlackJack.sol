pragma solidity 0.4.26;

//  Blackjack smart contract to be deployed on Rinkeby testnet
//  Contributors:
//    Tim Keller and Viktor Gsteiger

// Current version: 30.10.2019
// TODOs for V1 due 04.11.2019

contract BlackJack {

  // DECLARATION START

  // Decided for a game struct to save the players
  struct Game {
    address _playerAddress;
    uint _currentBalance;
    uint _currentBet;
    uint _randomNumber;
    uint _cardTotal;
    bool _turn;
    bool _init;
    bool _freshlyDealt;
    bool _hasAce;
    Cards[22] _currentHand;
    Cards[22] _dealerHand;
  }

  // Struct to save a card
  struct Cards {
    uint256 _value;
    string _name;
  }

  uint private _numberOfGames; // Not important
  uint private _nonce; // To make random more unpredictable
  uint private _ethLimit = 1500000 wei; // Max amount a player can invest
  address private _owner; // Owner of the contract
  uint private _fees; // Casino funds (if over 100, owner can withdraw funds)

  // Easiest way to save the players
  mapping(address => Game) games;

  // DECLARATION END

  // ----------

  // CONSTRUCTOR
  // Used for contract deployment to determine the owner
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

  // Only owner can use these functions
  modifier onlyOwner() {
      require(msg.sender == _owner, "You are not the owner.");
      _;
  }

  // To be able to only use a function after or before a game
  modifier outRound() {
    require(games[msg.sender]._turn == false, "Game running.");
    _;
  }

  // Only an initialised player can use those functions
  modifier onlyInitialisedPlayer() {
    require(games[msg.sender]._init == true, "You are not logged in yet.");
    _;
  }

  // Not sure if needed?
  modifier isPlayer() {
    require(games[msg.sender]._playerAddress == msg.sender, "You are not the right player.");
    _;
  }

  modifier madeBet() {
      require(games[msg.sender]._currentBet > 0, "You have to make a bet to play.");
      _;
  }

  // MODIFIERS END

  // Functions

  //TODO: stand, determine winner (partially done)

  // Invest money into the contract, as long as it's not more than limit
  function payContract() outRound public payable {
    require((games[msg.sender]._currentBalance+msg.value) <= _ethLimit, "Too much invested.");
    require(msg.value > 49, "Not enough invested.");
    uint value = msg.value;
    _fees += 5; // To pay the casino fees
    if (games[msg.sender]._init == false) {
      setPlayer(msg.sender,value-5); // Initialise the player
    } else {
      games[msg.sender]._currentBalance += (msg.value-5); // If player already initialised, update their balance
    }
  }

      function() external payable {
          // Fallback function, unused!
    }

    // Function to initialise a new player
    function setPlayer(address _address, uint256 _investment) private {
        games[_address]._playerAddress = _address; // Address to identify the player
        games[_address]._currentBalance = _investment; // Current balance on the contract
        games[_address]._currentBet = 0; // Bet is zero, because new player
        games[_address]._init = true; // Player is initialised and can now access more functions
        clearCards();
      }

    // One can make the bet higher before the game, but not change it if in a game
  function placeBet(uint256 bet) onlyInitialisedPlayer isPlayer outRound public returns (string) {
    // Check whether bet not too small or too big
    require(bet >= 2 wei && bet <= 500 wei, "Bet limit is 1 wei - 10000 wei.");
    // Check if bet not larger than player funds
    require(games[msg.sender]._currentBalance >= bet, "You can not afford to play this expensive.");
    games[msg.sender]._currentBalance -= bet; // Adjust player funds
    games[msg.sender]._currentBet += bet; // Adjust current bet
  }

  function deal() onlyInitialisedPlayer outRound madeBet public returns (string) {
    // Set the stage for a game
    games[msg.sender]._turn = true;
    clearCards();
    games[msg.sender]._cardTotal = 0;
    _numberOfGames++;

    // Player card 1:
    (games[msg.sender]._currentHand[0]._value,games[msg.sender]._currentHand[0]._name) = randomCard();

    // Internally handle Ace, player does only know he has an Ace but does not need to know more
    if (games[msg.sender]._currentHand[0]._value == 1) {
        games[msg.sender]._currentHand[0]._value = 11;
    }

    // Player card 2:
    (games[msg.sender]._currentHand[1]._value,games[msg.sender]._currentHand[1]._name) = randomCard();

    // Internally handle Ace, player does only know he has an Ace but does not need to know more
    if (getCurrentCardValue() + 11 < 22 && games[msg.sender]._currentHand[1]._value == 1) {
        games[msg.sender]._currentHand[1]._value = 11;
    }

    // Dealer card 1:
    (games[msg.sender]._dealerHand[0]._value,games[msg.sender]._dealerHand[0]._name) = randomCard();
    // Handle dealer Ace
    if (games[msg.sender]._dealerHand[0]._value == 1) {
        games[msg.sender]._dealerHand[0]._value = 11;
    }

    // Dealer card 2:
    (games[msg.sender]._dealerHand[1]._value,games[msg.sender]._dealerHand[1]._name) = randomCard();
    // Internally handle possible Ace 2 of dealer, player does only know he has an Ace but does not need to know more
    if (getCurrentCardValue() + 11 < 22 && games[msg.sender]._dealerHand[1]._value == 1) {
        games[msg.sender]._dealerHand[1]._value = 11;
    }

    // Handle if draw
    if(getCurrentCardValue() == 21 && getCurrentDealerCardValue() == 21) {
        games[msg.sender]._currentBalance += games[msg.sender]._currentBet;
        games[msg.sender]._currentBet = 0;
        games[msg.sender]._turn = false;
        return "Draw, you get your money back.";
    }

    // Handle if won
    if(getCurrentCardValue() == 21) {
        _fees -= 5;
        games[msg.sender]._currentBalance += games[msg.sender]._currentBet + 5;
        games[msg.sender]._currentBet = 0;
        games[msg.sender]._turn = false;
        return "BlackJack! You won!";
    }
    return "Your turn, how do you want to proceed? You can either hit another card or stand.";
    }

    function hit() inRound  onlyInitialisedPlayer public returns (string) {
        uint currentCard = 0;
        while(games[msg.sender]._currentHand[currentCard]._value != 0) {
            currentCard++;
        }
        (games[msg.sender]._currentHand[currentCard]._value,games[msg.sender]._currentHand[currentCard]._name) = randomCard();

        if (games[msg.sender]._currentHand[currentCard]._value == 1 && getCurrentCardValue() + 11 < 22) {
            games[msg.sender]._currentHand[currentCard]._value = 11;
        }

        if (getCurrentCardValue() == 21 && getCurrentDealerCardValue() == 21) {
            games[msg.sender]._currentBalance += games[msg.sender]._currentBet;
            games[msg.sender]._currentBet = 0;
            games[msg.sender]._turn = false;
            return "Draw, you get your money back.";
        }

        if (getCurrentCardValue() == 21) {
            games[msg.sender]._currentBalance += games[msg.sender]._currentBet + 5;
            games[msg.sender]._currentBet = 0;
            games[msg.sender]._turn = false;
            return "BlackJack! You won!";
        }

        if (getCurrentCardValue() > 21 && games[msg.sender]._hasAce == false) {
            _fees += games[msg.sender]._currentBet;
            games[msg.sender]._currentBet = 0;
            games[msg.sender]._turn = false;
            return "You lost. You will get nothing back.";
        }

        if (getCurrentCardValue() > 21) {
            currentCard = 0;
            while (games[msg.sender]._currentHand[currentCard]._value != 0) {
                if(games[msg.sender]._currentHand[currentCard]._value == 11) {
                    if(getCurrentCardValue() - 10 < 22) {
                        games[msg.sender]._currentHand[currentCard]._value = 1;
                        if (getCurrentCardValue() == 21 && getCurrentDealerCardValue() == 21) {
                            games[msg.sender]._currentBalance += games[msg.sender]._currentBet;
                            games[msg.sender]._currentBet = 0;
                            games[msg.sender]._turn = false;
                            return "Draw, you get your money back.";
                        }

                        if (getCurrentCardValue() == 21) {
                            games[msg.sender]._currentBalance += games[msg.sender]._currentBet + 5;
                            games[msg.sender]._currentBet = 0;
                            games[msg.sender]._turn = false;
                            return "BlackJack! You won!";
                        }
                    }
                }
            }
            if(getCurrentCardValue() > 21) {
                _fees += games[msg.sender]._currentBet;
                games[msg.sender]._currentBet = 0;
                games[msg.sender]._turn = false;
                return "You lost. You will get nothing back.";
            }
        }

        return "Got another card, your choice now, hit or stand?";
    }

    function stand() inRound  onlyInitialisedPlayer public returns (string) {
        games[msg.sender]._freshlyDealt = false;

        if (getCurrentDealerCardValue() == 21) {
            _fees += games[msg.sender]._currentBet;
            games[msg.sender]._currentBet = 0;
            games[msg.sender]._turn = false;
            return "The dealer had BlackJack. You lost. You will get nothing back.";
        }
        uint counter = 2;
        do {
            (games[msg.sender]._dealerHand[counter++]._value,games[msg.sender]._dealerHand[counter++]._name) = randomCard();
            if(games[msg.sender]._dealerHand[counter++]._value == 1 && getCurrentDealerCardValue() + 10 < 18) {
                games[msg.sender]._dealerHand[counter++]._value = 11;
            }

        } while (getCurrentDealerCardValue() < 17);

        if (getCurrentDealerCardValue() > 21) {
            games[msg.sender]._currentBalance += games[msg.sender]._currentBet + 5;
            games[msg.sender]._currentBet = 0;
            games[msg.sender]._turn = false;
            return "You won! The dealer had more than 21";
        }
        if(getCurrentDealerCardValue() == getCurrentCardValue()) {
            games[msg.sender]._currentBalance += games[msg.sender]._currentBet;
            games[msg.sender]._currentBet = 0;
            games[msg.sender]._turn = false;
            return "Draw, you get your money back.";
        }
        if(getCurrentDealerCardValue() < getCurrentCardValue()) {
            games[msg.sender]._currentBalance += games[msg.sender]._currentBet + 5;
            games[msg.sender]._currentBet = 0;
            games[msg.sender]._turn = false;
            return "You won! You had more than the dealer";
        }
        if(getCurrentCardValue() < getCurrentDealerCardValue()) {
            _fees += games[msg.sender]._currentBet;
            games[msg.sender]._currentBet = 0;
            games[msg.sender]._turn = false;
            return "You lost. You had less than the dealer.";
            }
    }

    // Function to handle Card creation with name and value
  function randomCard() private returns (uint, string) {
    uint value = uint(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty,_nonce++)))%14);
    if (value == 1) {
        games[msg.sender]._hasAce == true;
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
    // To keep random more random and unpredictable
    if (_nonce > 60000) {
        _nonce = value;
    }
  }

  // clear cards for a new game/set them all to zero
  function clearCards() private {
    for(uint i = 0;i < games[msg.sender]._currentHand.length; i++) {
    games[msg.sender]._hasAce = false;
      games[msg.sender]._currentHand[i]._value = 0;
      games[msg.sender]._dealerHand[i]._value = 0;
    }
  }

  // Calculate the player card values for win evaluations
  function getCurrentCardValue() inRound private view returns (uint) {
      uint value = 0;
      for(uint i = 0;i < games[msg.sender]._currentHand.length; i++) {
          value += games[msg.sender]._currentHand[i]._value;
      }
      return value;
  }

  // Calcuate the dealer card values for win evaluations
  function getCurrentDealerCardValue() private view returns (uint) {
      uint value = 0;
      for(uint i = 0;i < games[msg.sender]._dealerHand.length; i++) {
          value += games[msg.sender]._dealerHand[i]._value;
      }
      return value;
  }

  // Function to change the Aces value
  //function changeAceValue(uint i) inRound public returns (string) {
//    require(games[msg.sender]._currentHand[i-1]._value == 1 || games[msg.sender]._currentHand[i-1]._value == 11, "Not an Ace!");
  //  if(games[msg.sender]._currentHand[i-1]._value == 1) {
    //  games[msg.sender]._currentHand[i-1]._value = 11;
     // return "The value of your ace is now 11.";
  //  } else {
  //    games[msg.sender]._currentHand[i-1]._value = 1;
   //   return "The value of your ace is now 1.";
  //  }
 // }

  // public functions to get information relevant to the game
  function getPlayerCardName(uint i) inRound public view returns (string) {
            require(i > 0 && i < 23, "Wrong number!");
      return games[msg.sender]._currentHand[i-1]._name;
  }
  function getDealerCardName(uint i) inRound public view returns (string) {
      require(i > 0 && i < 23, "Wrong number!");
      if(games[msg.sender]._freshlyDealt == false) {
          return games[msg.sender]._dealerHand[i-1]._name;
      }
      require (i == 1, "You are not yet allowed to see the other dealers cards");
      return games[msg.sender]._dealerHand[0]._name;
  }
  // Get the current general funds of the player
  function getPlayerFunds() public view returns (uint) {
      return games[msg.sender]._currentBalance;
  }
  function getCurrentBet() public view returns (uint) {
      return games[msg.sender]._currentBet;
  }
    function getNumberOfGames() public view returns (uint){
      return _numberOfGames;
  }

  // Withdraw function for the owner/players
  function clearCasino() public onlyOwner {
      if (_fees > 100) {
          _owner.transfer(_fees-100);
      }
  }
    function withdraw() onlyInitialisedPlayer isPlayer outRound public {
    address(msg.sender).transfer(games[msg.sender]._currentBalance);
    games[msg.sender]._currentBalance = 0;
  }
}
