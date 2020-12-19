pragma solidity 0.6.6;

import "./Credits.sol";

/// @title Inital Token Offering (ITO)
/// @dev ITO is the contract for managing the Credits' crowdsale
// allowing investors to purchase Credits for Ether. 

// TO DO...
// [ ] MAKE INTO A SLOW DRIP INSTEAD OF EVERYONE GETS AT ONCE (i.e. 10% day 1, 40% end of week 1, 40% end of week 2)
// [X] MAKE TOKENS CLAIMABLE FOR CREDITS  

contract CreditsITO is Credits {
    using SafeMath for uint256;

    Credits credits;                                      // The token being sold

    address payable ito_Collector;                        // Where eth funds are transfered to
    uint256 public conversionRate_EthToCredibytes;        // How many credibytes a buyer gets per eth.
    uint256 public conversionRate_CredibytesToCredits;    // How many credits per credibytes (always a multiplier)
    uint256 public totalEthRaised;                        // Amount of eth raised
    uint256 public minEthRequirement;                     // minimum amount of eth required to buy credibytes

    mapping(address => uint256) public credibyteBalance;
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

   constructor(address payable _itoCollector) public {
    ito_Collector = _itoCollector;
    deploymentDate = now;
    timelockActivationDate = deploymentDate.add(2 weeks);
    hasFinalised = false;
    conversionRate_EthToCredibytes = 10000;
    conversionRate_CredibytesToCredits = 3;
    minEthRequirement = 0 ether; 
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
  function setRate_CredibytesToCredits(uint _newRate) public onlyOwner {
    conversionRate_CredibytesToCredits = _newRate;
  }

  /// @notice Allows owner to update the minimum amount of eth to partake in the ITO.
  /// @param _newMinimumRequirement the new minimum amount of eth to partake in the ITO.
  function updateMinimumRequirement(uint _newMinimumRequirement) public onlyOwner {
      minEthRequirement = _newMinimumRequirement;
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
    require(users[msg.sender].credibyteBalance != 0, "No credibytes remaining.");
    uint256 _convertedAmount = convertedCredibytes();                       // checks how many credits user will receive
    commenceConversion(_convertedAmount);                                   // transfers credits to user
    emit CredibytesRedeption(msg.sender, _convertedAmount, now);
    return (_convertedAmount, true);
  }

  // Transfers wei to designated collector & transfers credits to beneficiary. 
  function buyCredibytes_withETH(address _beneficiary) ito_Timelock public payable {
    uint256 ethAmount = msg.value;                                                              // ethAmount becomes msg.value
    
    _preValidatePurchase(_beneficiary, ethAmount);                                              // validates tx isn't sending 0 wei
    uint256 credibyteAmount = _getCredibyteAmount(ethAmount);                                   // calculates the amount of credits to be created
    
    _forwardFunds(ethAmount);                                                                   // transfers eth to itoCollector
    totalEthRaised = totalEthRaised.add(ethAmount);                                             // updates state: totalEthRaised

    _processPurchase(_beneficiary, credibyteAmount);                                            // transfers credits to beneficiary
    credibyteBalance[_beneficiary] = credibyteBalance[_beneficiary].add(credibyteAmount);       // updates balance of credits purchased

      if(hasParticipated[_beneficiary] != true) {                                               // adds users to hasParticipated if they haven't
        participants.push(_beneficiary);
        hasParticipated[_beneficiary] = true;
      }                         
    emit CredibytesPurchase(msg.sender, _beneficiary, ethAmount, credibyteAmount); 
  }

  // If unlocked, call buyCredits_forWei.
  // If locked, revert tx.
  receive() override external payable {
    if(now <= timelockActivationDate) {
      buyCredibytes_withETH(msg.sender); 
    } else { revert(); }
  }

//  ----------------------------------------------------
//     convertCredibytesToCredits Internal Functions 
//  ----------------------------------------------------

  // calculates how many credits the user will be receiving according to their creditbytes balance
  function convertedCredibytes() view internal returns(uint256) {
    return users[msg.sender].credibyteBalance.mul(conversionRate_CredibytesToCredits);
  }

  function commenceConversion(uint256 _convertedAmount) internal {
    users[msg.sender].credibyteBalance = 0;                                                               // sets user's credibyte balance to 0
    users[creditsContract].creditBalance = users[creditsContract].creditBalance.sub(_convertedAmount);    // deducts credits from owner wallet
    remainingUnheldCredits = users[creditsContract].creditBalance;                                        // updates remaining unheld credits
    users[msg.sender].creditBalance = users[msg.sender].creditBalance.add(_convertedAmount);              // gives user converted credits amount
    totalCreditsHeld = totalCreditsSupply.sub(remainingUnheldCredits);                                    // updates total credits held
  }

//  ----------------------------------------------------
//       buyCredibytes_forETH Internal Functions 
//  ----------------------------------------------------

  function _preValidatePurchase(address _beneficiary, uint256 _ethAmount) ito_Timelock view internal  {
    require(_beneficiary != address(0), "Unable to purchase credibytes for deployer");
    require(msg.value >= minEthRequirement, "Does not meet the minimum purchasing requirement - refer to minEthRequirement.");
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
  
  function _forwardFunds(uint256 ethAmount) ito_Timelock internal {
    ito_Collector.transfer(ethAmount);
  }
}
