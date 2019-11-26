pragma solidity 0.4.26;

//  Blackjack smart contract to be deployed on Rinkeby testnet
//  Contributors:
//    Tim Keller and Viktor Gsteiger

// Current version: 21.11.2019
// TODOs for V3 due 25.11.2019

contract BlackJack {

  // DECLARATION START
  
  //Events 

  //Event for String messages
  event Message(address player, string message);

  // Decided for a game struct to save the players
  struct Game {
    address _playerAddress;
    uint _currentBalance;
    uint _currentBet;
    uint _randomNumber;
    uint _cardTotal;
    uint _currentInsurance;
    uint _insurance;
    bool _deal;
    bool _turn;
    bool _init;
    bool _hasAce;
    bool _insured;
    Cards[22] _currentHand;
    Cards[22] _dealerHand;
  }

  // Struct to save a card
  struct Cards {
    uint256 _value;
    string _name;
  }

  uint private _numberOfGames; // Number of played games on this contract
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

  // Check if the message sende is a valid player
  modifier isPlayer() {
    require(games[msg.sender]._playerAddress == msg.sender, "You are not the right player.");
    _;
  }

  // Check, if a player already made a bet
  modifier madeBet() {
      require(games[msg.sender]._currentBet > 0, "You have to make a bet to play.");
      _;
  }

  // MODIFIERS END

  // FUNCTIONS START

  // PAYMENT FUNCTIONS START

  // Invest money into the contract, as long as it's not more than limit
  function payContract() outRound public payable {
    require((games[msg.sender]._currentBalance+msg.value) <= _ethLimit, "Too much invested.");
    require(msg.value > 49, "Not enough invested.");
    uint currentFee = ((msg.value/100)*5);
    _fees += currentFee; // To pay the casino fees
    if (games[msg.sender]._init == false) {
      setPlayer(msg.sender,msg.value-currentFee); // Initialise the player
    } else {
      games[msg.sender]._currentBalance += (msg.value-currentFee); // If player already initialised, update their balance
    }
  }

    function() external payable {
          // Fallback function, unused!
    }

    // PAYMENT FUNCTIONS END

    // BET FUNCTIONS START

    // One can make the bet higher before the game, but not change it if in a game
  function placeBet(uint256 bet) onlyInitialisedPlayer isPlayer outRound public returns (string) {
    // Check whether bet not too small or too big
    require(bet >= 2 wei && bet <= 500 wei, "Bet limit is 1 wei - 10000 wei.");
    // Check if bet not larger than player funds
    require(games[msg.sender]._currentBalance >= bet, "You can not afford to play this expensive.");
    games[msg.sender]._currentBalance -= bet; // Adjust player funds
    games[msg.sender]._currentBet += bet; // Adjust current bet
  }

  // BET FUNCTIONS END

  // GAME FUNCTIONS START

  function deal() onlyInitialisedPlayer outRound madeBet public returns (string) {
    // Set the stage for a game
    games[msg.sender]._insured == false;
    games[msg.sender]._turn = true;
    games[msg.sender]._deal = true;
    clearCards();
    games[msg.sender]._cardTotal = 0;
    _numberOfGames++;

    // Player card 1:
    (games[msg.sender]._currentHand[0]._value,games[msg.sender]._currentHand[0]._name) = randomCard();

    // Internally handle Ace, player does only know he has an Ace but does not need to know more
    if (games[msg.sender]._currentHand[0]._value == 1) {
        games[msg.sender]._hasAce = true;
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
    if (getCurrentDealerCardValue() + 11 < 22 && games[msg.sender]._dealerHand[1]._value == 1) {
        games[msg.sender]._dealerHand[1]._value = 11;
    }

    // Handle if won
    if(getCurrentCardValue() == 21 && getCurrentDealerCardValue()!= 21) {
        uint currentWin = ((games[msg.sender]._currentBet/100)*5);
        _fees -= currentWin;
        games[msg.sender]._currentBalance += games[msg.sender]._currentBet + currentWin;
        games[msg.sender]._currentBet = 0;
        games[msg.sender]._turn = false;
        games[msg.sender]._deal = false;
        emit Message(msg.sender, "BlackJack! You won!");
        return "BlackJack! You won!";
    }
    emit Message(msg.sender, "Your turn, how do you want to proceed? You can either hit another card or stand.");
    return "Your turn, how do you want to proceed? You can either hit another card or stand.";
  }

    // Does not return String atm/something is buggy
    function hit() inRound  onlyInitialisedPlayer public returns (string) {
        uint currentCard = 0;
        games[msg.sender]._deal = false;

        // Iterate until we are at the current cards:
        while(games[msg.sender]._currentHand[currentCard]._value != 0) {
            currentCard++;
        }

        // Create new card:
        (games[msg.sender]._currentHand[currentCard]._value,games[msg.sender]._currentHand[currentCard]._name) = randomCard();

        if (games[msg.sender]._currentHand[currentCard]._value == 1) {
          games[msg.sender]._hasAce = true;
        }

        // Internally handle Ace (not relevant for player):
        if (games[msg.sender]._currentHand[currentCard]._value == 1 && getCurrentCardValue() + 11 < 22) {
            games[msg.sender]._currentHand[currentCard]._value = 11;
        }

        // Both Blackjack:
        if (getCurrentCardValue() == 21 && getCurrentDealerCardValue() == 21) {
            games[msg.sender]._currentBalance += games[msg.sender]._currentBet;
            games[msg.sender]._currentBet = 0;
            games[msg.sender]._turn = false;
            if(games[msg.sender]._insured == true) {
              cashOutInsurance();
            }
            emit Message(msg.sender, "Draw, you get your money back.");
            return "Draw, you get your money back.";
        }

        // Player BlackJack:
        if (getCurrentCardValue() == 21) {
            uint currentWin = ((games[msg.sender]._currentBet/100)*5);
            _fees -= currentWin;
            games[msg.sender]._currentBalance += games[msg.sender]._currentBet + currentWin;
            games[msg.sender]._currentBet = 0;
            games[msg.sender]._turn = false;
            insuranceToCasino();
            emit Message(msg.sender, "BlackJack! You won!");
            return "BlackJack! You won!";
        }

        // If player bust and no chance to change an ace to 1:
        if (getCurrentCardValue() > 21 && games[msg.sender]._hasAce == false) {
            _fees += games[msg.sender]._currentBet;
            games[msg.sender]._currentBet = 0;
            games[msg.sender]._turn = false;
            insuranceToCasino();
            emit Message(msg.sender, "You lost. You will get nothing back.");
            return "You lost. You will get nothing back.";
        }

        // If bust but player has an ace:
        if (getCurrentCardValue() > 21) {
            currentCard = 0;
            // Go through all cards:
            while (games[msg.sender]._currentHand[currentCard]._value != 0) {
                // Check if currentCard is an Ace with value 11:
                if(games[msg.sender]._currentHand[currentCard]._value == 11) {
                    // Check if changing the Ace to 1 would change anything:
                    if(getCurrentCardValue() - 10 < 22) {
                        games[msg.sender]._currentHand[currentCard]._value = 1;
                        // Check if changing Ace gave player a BlackJack and dealer has a BlackJack:
                        if (getCurrentCardValue() == 21 && getCurrentDealerCardValue() == 21) {
                            games[msg.sender]._currentBalance += games[msg.sender]._currentBet;
                            games[msg.sender]._currentBet = 0;
                            games[msg.sender]._turn = false;
                            if(games[msg.sender]._insured == true) {
                              cashOutInsurance();
                            }
                            emit Message(msg.sender, "Draw, you get your money back.");
                            return "Draw, you get your money back.";
                        }
                        // Check if now has Blackjack to win:
                        if (getCurrentCardValue() == 21) {
                            uint currentWin1 = ((games[msg.sender]._currentBet/100)*5);
                            _fees -= currentWin1;
                            games[msg.sender]._currentBalance += games[msg.sender]._currentBet + currentWin1;
                            games[msg.sender]._currentBet = 0;
                            games[msg.sender]._turn = false;
                            insuranceToCasino();
                            emit Message(msg.sender, "BlackJack! You won!");
                            return "BlackJack! You won!";
                        }
                    }
                }
            }
            // If changing all the Aces didn't help, player lost:
            if(getCurrentCardValue() > 21) {
                _fees += games[msg.sender]._currentBet;
                games[msg.sender]._currentBet = 0;
                games[msg.sender]._turn = false;
                insuranceToCasino();
                emit Message(msg.sender, "Draw, you get your money back.");
                return "You lost. You will get nothing back.";
            }
        }
        // If not lost or won, new card or stand:
        emit Message(msg.sender, "Got another card, your choice now, hit or stand?");
        return "Got another card, your choice now, hit or stand?";
    }

    // Function for the player to take no more card. Now the dealer has to take cards
    // as long as his cards value is below 17.
    function stand() inRound  onlyInitialisedPlayer public returns (string) {
        games[msg.sender]._deal = false;

        if (getCurrentDealerCardValue() == 21 && getCurrentCardValue() == 21) {
          games[msg.sender]._currentBalance += games[msg.sender]._currentBet;
          games[msg.sender]._currentBet = 0;
          games[msg.sender]._turn = false;
          if(games[msg.sender]._insured == true) {
            cashOutInsurance();
          }
          emit Message(msg.sender, "Draw, you get your money back.");
          return "Draw, you get your money back.";
        }
        // If the dealer got blackjack (player gets checked in hit/deal) he wins.
        if (getCurrentDealerCardValue() == 21) {
            _fees += games[msg.sender]._currentBet;
            games[msg.sender]._currentBet = 0;
            games[msg.sender]._turn = false;
            if(games[msg.sender]._insured == true) {
              cashOutInsurance();
            }
            emit Message(msg.sender, "The dealer had BlackJack. You lost. You will get nothing back.");
            return "The dealer had BlackJack. You lost. You will get nothing back.";
        }
        uint counter = 2;

        // Dealer has to take cards until his cards have the value 17 or more
        while (getCurrentDealerCardValue() < 17) {
            (games[msg.sender]._dealerHand[counter++]._value,games[msg.sender]._dealerHand[counter++]._name) = randomCard();
            if(games[msg.sender]._dealerHand[counter++]._value == 1 && getCurrentDealerCardValue() + 10 < 18) {
                games[msg.sender]._dealerHand[counter++]._value = 11;
            }

        }

        // Dealer busts (player gets checked after hit, it's not possible for the player to have more than 21 after deal)
        if (getCurrentDealerCardValue() > 21) {
            uint currentWin = ((games[msg.sender]._currentBet/100)*5);
            _fees -= currentWin;
            games[msg.sender]._currentBalance += games[msg.sender]._currentBet + currentWin;
            games[msg.sender]._currentBet = 0;
            games[msg.sender]._turn = false;
            insuranceToCasino();
            emit Message(msg.sender, "You won! The dealer had more than 21");
            return "You won! The dealer had more than 21";
        }

        // Draw
        if(getCurrentDealerCardValue() == getCurrentCardValue()) {
            games[msg.sender]._currentBalance += games[msg.sender]._currentBet;
            games[msg.sender]._currentBet = 0;
            games[msg.sender]._turn = false;
            insuranceToCasino();
            emit Message(msg.sender, "Draw, you get your money back.");
            return "Draw, you get your money back.";
        }

        // Player won with more points
        if(getCurrentDealerCardValue() < getCurrentCardValue()) {
            uint currentWin2 = ((games[msg.sender]._currentBet/100)*5);
            _fees -= currentWin2;
            games[msg.sender]._currentBalance += games[msg.sender]._currentBet + currentWin2;
            games[msg.sender]._currentBet = 0;
            games[msg.sender]._turn = false;
            insuranceToCasino();
            emit Message(msg.sender, "You won! You had more than the dealer");
            return "You won! You had more than the dealer";
        }

        // Dealer won with more points
        if(getCurrentCardValue() < getCurrentDealerCardValue()) {
            _fees += games[msg.sender]._currentBet;
            games[msg.sender]._currentBet = 0;
            games[msg.sender]._turn = false;
            insuranceToCasino();
            emit Message(msg.sender, "Draw, you get your money back.");
            return "You lost. You had less than the dealer.";
            }
    }

  // GAME FUNCTIONS END

  // INSURANCE FUNCTION START

  // Insure the game if dealers first card was an ace
  function insureGame() public inRound onlyInitialisedPlayer returns (string) {
    require(games[msg.sender]._deal, "You can only insure game after deal");
    require(games[msg.sender]._dealerHand[0]._value == 1 || games[msg.sender]._dealerHand[0]._value == 11, "Dealer does not have an ace.");
    games[msg.sender]._insured = true;
    games[msg.sender]._insurance = games[msg.sender]._currentBet / 2;
    games[msg.sender]._currentBalance -= games[msg.sender]._insurance;
  }

  // INSURANCE FUNCTION END

  // PUBLIC WITHDRAWAL FUNCTIONS START

  // Withdraw function for the owner/players
  function clearCasino() onlyOwner public {
      if (_fees > 100) {
          _owner.transfer(_fees-100);
      }
  }

  // Withdraw the players balance:
    function withdraw() onlyInitialisedPlayer isPlayer outRound public {
    address(msg.sender).transfer(games[msg.sender]._currentBalance);
    games[msg.sender]._currentBalance = 0;
  }

  // PUBLIC WITHDRAWAL FUNCTIONS END

  // PUBLIC GETTERS START

  // public functions to get information relevant to the game
  function getPlayerCardName(uint i) inRound public view returns (string) {
    require(i >= 0 && i < 22, "Wrong number!");
    return games[msg.sender]._currentHand[i-1]._name;
  }

  // Get the cards of the dealer. It's only possible to get the dealers first card before standing.
  function getDealerCardName(uint i) inRound public view returns (string) {
      require(i >= 0 && i < 22, "Wrong number!");
      if(games[msg.sender]._deal == true) {
              return games[msg.sender]._dealerHand[0]._name;
      } else {
        return games[msg.sender]._dealerHand[i-1]._name;
    }
  }

  // Get the current general funds of the player
  function getPlayerFunds() public view returns (uint) {
      return games[msg.sender]._currentBalance;
  }

  // Get current bet
  function getCurrentBet() public view returns (uint) {
      return games[msg.sender]._currentBet;
  }

  // Get current number of games
    function getNumberOfGames() public view returns (uint){
      return _numberOfGames;
  }

  // PUBLIC GETTERS END

  // PRIVATE FUNCTIONS START

  // Calcuate the dealer card values for win evaluations
  function getCurrentDealerCardValue() private view returns (uint) {
      uint value = 0;
      for(uint i = 0;i < games[msg.sender]._dealerHand.length; i++) {
          value += games[msg.sender]._dealerHand[i]._value;
      }
      return value;
  }

  // Calculate the player card values for win evaluations
  function getCurrentCardValue() inRound private view returns (uint) {
      uint value = 0;
      for(uint i = 0;i < games[msg.sender]._currentHand.length; i++) {
          value += games[msg.sender]._currentHand[i]._value;
      }
      return value;
  }

  // Function to cash out the insurance in case of loosing if player had insurance
  function cashOutInsurance() private {
    if(games[msg.sender]._insured == true){
    games[msg.sender]._currentBalance += games[msg.sender]._insurance * 2;
    games[msg.sender]._insurance = 0;
    _fees -= games[msg.sender]._insurance;
    }
  }

  // Function to withdraw insurance if player lost or won
  function insuranceToCasino() private {
    if(games[msg.sender]._insured == true) {
    _fees += games[msg.sender]._insurance;
    games[msg.sender]._insurance = 0;
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

  // Function to initialise a new player
  function setPlayer(address _address, uint256 _investment) private {
      games[_address]._playerAddress = _address; // Address to identify the player
      games[_address]._currentBalance = _investment; // Current balance on the contract
      games[_address]._currentBet = 0; // Bet is zero, because new player
      games[_address]._init = true; // Player is initialised and can now access more functions
      clearCards();
  }

  // PRIVATE FUNCTIONS END

  // FUNCTIONS END

}
