pragma solidity 0.6.6;

import "./Credits.sol";
import "./Permissioned.sol";
import "./InfoBot.sol";

/// @title Inital Token Offering (ITO)
/// @dev ITO is the contract for managing the Credits' crowdsale
// allowing investors to purchase Credits for Ether. 

// TO DO...
// [ ] MAKE INTO A SLOW DRIP INSTEAD OF EVERYONE GETS AT ONCE (i.e. 10% day 1, 40% end of week 1, 40% end of week 2)
// [X] MAKE TOKENS CLAIMABLE FOR CREDITS  

contract CreditsITO is Permissioned, InfoBot {
    using SafeMath for uint256;

    Credits public credits;                               // The token being sold

    address payable public ito_Collector;                 // Address where funds are transfered to
    uint256 public conversionRate_EthToCredibytes;        // How many credibytes a buyer gets per eth.
    uint256 public conversionRate_CredibytesToCredits;    // How many credits per credibytes (always a multiplier)
    uint256 public totalEthRaised;                        // Amount of eth raised

    mapping(address => uint256) public itoCreditsPurchased;
    mapping(address => bool) public hasParticipated;
    address[] public participants;
    
    /// @notice Event for token purchase logging
    event CredibytesPurchase(
      address indexed purchaser,     // who paid for the credits
      address indexed beneficiary,   // who received the credits
      uint256 value,                 // ethers paid for credits
      uint256 amount                 // amount of credits purchased
    );
    event CredibytesRedeption(
      address indexed redeemer,
      uint256 amount,
      uint256 date
    );

   constructor() public {
    ito_Collector = 0x3cdEb927aEA88104c459369113F36408de0bADB9;
    deploymentDate = now;
    timelockActivationDate = deploymentDate.add(2 weeks);
    hasFinalised = false;
    conversionRate_EthToCredibytes = 10000;
    conversionRate_CredibytesToCredits = 3;
  }

//  ----------------------------------------------------
//                      Dashboard 
//  ----------------------------------------------------


  /// @notice Allows owner to update the eth to credibytes conversion rate.
  /// @param _newRate new eth to credibytes conversion rate.
  function setRate_EthToCredibytes(uint _newRate) public onlyOwner {
    conversionRate_EthToCredibytes = _newRate;
  }

  /// @notice Allows owner to update the credibytes to credits conversion rate.
  /// @param _newRate new credibytes to credits conversion rate.
  function setRate_CredibytesToCredits (uint _newRate) public onlyOwner {
    conversionRate_CredibytesToCredits = _newRate;
  }

  /// @notice Allows owner to finish the ITO before the timelock.
  function finalise() public onlyOwner {
    hasFinalised = true;
  }

//  ----------------------------------------------------
//                      Timelock 
//  ----------------------------------------------------

  // The block when the contract locks/stops functioning.
  uint256 public timelockActivationDate;
  uint256 public deploymentDate;

  bool public hasFinalised;

  // If: now <= timelockActivationDate, continue functionality of ITO.
  modifier ito_Timelock {
      require(now <= timelockActivationDate, "ITO phase is over: contract locked & no longer functional.");
      require(hasFinalised != true, "The owner has finalised the ITO.");
      _;
  }

  modifier canRedeem {
      require(now >= timelockActivationDate, "ITO phase is currently underway: can redeem once finalised or timelock has activated.");
      require(hasFinalised == true, "The owner not finalised the ITO.");
      _;
  }

//  ----------------------------------------------------
//                 External Functions 
//  ----------------------------------------------------

  // Allows the user to conver their credibytes to credits.
  function convertCredibytesToCredits() canRedeem public returns (uint256 convertedAmount, bool sucess){
    require(users[msg.sender].credibyteBalance != 0, "No credibytes remaining");
    uint256 _convertedAmount = convertedCredibytes();                       // checks how many credits user will receive
    commenceConversion(_convertedAmount);                                   // transfers credits to user
    emit CredibytesRedeption(msg.sender, _convertedAmount, now);
    return (_convertedAmount, true);
  }

  // Transfers wei to designated collector & transfers credits to beneficiary. 
  function buyCredibytes_forETH(address _beneficiary) ito_Timelock public payable {
    uint256 ethAmount = msg.value;                                                              // ethAmount becomes msg.value
    
    _preValidatePurchase(_beneficiary, ethAmount);                                              // validates tx isn't sending 0 wei
    uint256 crdtsAmount = _getCredibyteAmount(ethAmount);                                       // calculates the amount of credits to be created
    
    _forwardFunds();                                                                            // transfers eth to itoCollector
    totalEthRaised = totalEthRaised.add(ethAmount);                                             // updates state: totalEthRaised

    _processPurchase(_beneficiary, crdtsAmount);                                                // transfers credits to beneficiary
    itoCreditsPurchased[_beneficiary] = itoCreditsPurchased[_beneficiary].add(crdtsAmount);     // updates balance of credits purchased

      if(hasParticipated[_beneficiary] != true) {                                               // adds users to hasParticipated if they haven't
        participants.push(_beneficiary);
        hasParticipated[_beneficiary] = true;
      }                         
    emit CredibytesPurchase(msg.sender, _beneficiary, ethAmount, crdtsAmount); 
  }

  // If unlocked, call buyCredits_forWei.
  // If locked, revert tx.
  receive() external payable {
    require(now <= timelockActivationDate, "ITO phase is over: contract locked & no longer functional.");
      buyCredibytes_forETH(msg.sender);   
  }

//  ----------------------------------------------------
//     convertCredibytesToCredits Internal Functions 
//  ----------------------------------------------------

  // calculates how many credits the user will be receiving according to their creditbytes balance
  function convertedCredibytes() view internal returns(uint256) {
    return users[msg.sender].credibyteBalance.mul(conversionRate_CredibytesToCredits);
  }

  function commenceConversion(uint256 _convertedAmount) internal {
    users[msg.sender].credibyteBalance = 0;
    users[owner].creditBalance = users[owner].creditBalance.sub(_convertedAmount);
    users[msg.sender].creditBalance = users[msg.sender].creditBalance.add(_convertedAmount);
  }

//  ----------------------------------------------------
//       buyCredibytes_forETH Internal Functions 
//  ----------------------------------------------------

  function _preValidatePurchase(address _beneficiary, uint256 _ethAmount) ito_Timelock view internal  {
    require(_beneficiary != address(0));
    require(_ethAmount != 0);
  }

  function _getCredibyteAmount(uint256 _ethAmount) ito_Timelock internal view returns (uint256) {
    return ((_ethAmount.mul(conversionRate_EthToCredibytes)).div(1000000000000000000));
  }

  // Calls _deliverTokens.
  function _processPurchase(address _beneficiary, uint256 _crdtsAmount) ito_Timelock internal {
    _deliverCredibytes(_beneficiary, _crdtsAmount);
  }

  // Transfers credits from credits.sol (the holder of the supply).
  function _deliverCredibytes(address _beneficiary, uint256 _crdtsAmount) ito_Timelock internal {
    users[_beneficiary].credibyteBalance = users[_beneficiary].credibyteBalance.add(_crdtsAmount);
  }
  
  function _forwardFunds() ito_Timelock internal {
    ito_Collector.transfer(msg.value);
  }
}