//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Credits.sol";

/// @title Inital Token Offering (ITO)
/// @dev ITO is the contract for managing the Credits' crowdsale
// allowing investors to purchase Credits for Ether. 

// TO DO...
// [X] MAKE INTO A SLOW DRIP INSTEAD OF EVERYONE GETS AT ONCE (i.e. 25% at the start of each month for 4 months)
// [X] MAKE TOKENS CLAIMABLE FOR CREDITS  
// [ ] MAKE MODIFIER "SOLD OUT" FOR REMAINING CREDIBYTES REMAINING, THAT ARE ABLE TO BE PURCHASED
// [ ] MAKE A CREDITS TOTAL SUPPLY 
// [ ] FIX TRANSFERFROM & TRANSFER FUNCTION SO DEVS CANT DRAIN SUPPLY

contract CreditsITO is Credits {
  using SafeMath for uint256;

  Credits credits;                                      // The token being sold

  uint256 public conversionRate_EthToCredibytes;        // How many credibytes a buyer gets per eth.
  uint256 public conversionRate_CredibytesToCredits;    // How many credits per credibytes (always a multiplier)
  uint256 public totalEthRaised;                        // Amount of eth raised
  uint256 public minEthRequirement;                     // minimum amount of eth required to buy credibytes

  address payable itoContract = address(this);          // the address that holds the credits & credibytes total supply
  uint256 public remaining_credibyteSupply;             // the remaining credibytes that are available for purchase

  uint256 public itoTotalParticipants;                  // the amount of ito user participants 
    
    
  event CredibytesPurchase(                             // Event for credibytes purchase logging
    address indexed purchaser,                          // who paid for the credits
    address indexed beneficiary,                        // who received the credits
    uint256 ethAmount,                                  // ethers paid for credits
    uint256 credibyteAmount                             // amount of credits purchased
  );
  event CredibytesRedemption(                           // Event for credibytes redemption
    address indexed redeemer,                           // user redeeming
    uint256 indexed creditsAmount,                      // amount of credits getting redeemed from credibytes
    uint256 time                                        // time of redemption
  );    
  event developerEthWithdrawal(                         // event for developer withdrawing eth
    address indexed to,                                 // address the developer is sending the eth to
    uint256 indexed amount,                             // the amount of eth being sent
    uint256 indexed timeOfWithdrawal                    // the block timestamp of the withdrawal
  );
  event ethDepositToDeveloper(                          // event for developer receiving eth
    address indexed from,                               // address that sent the eth
    uint256 indexed amount,                             // the amount of eth being sent
    uint256 indexed timeOfDeposit                       // the block timestamp of the deposit
  );
  event developerCreditsWithdrawal(                     // event for developer withdrawing credits (helps users prepare for a dump if need be)
    address indexed to,                                 // the address receiving the credits
    uint256 indexed amount,                             // the amount of credits being withdrawn
    uint256 indexed timeOfWithdrawal                    // the block timestamp of the withdrawal
  );

  constructor() {
    deploymentDate = block.timestamp;
    timelockActivationDate = deploymentDate + 4 weeks;
    hasFinalised = false;
    conversionRate_EthToCredibytes = 10000;
    conversionRate_CredibytesToCredits = 3;
    minEthRequirement = 1 ether;
    credits.approve(itoContract, 300000 * 10**18);
    credits.transferFrom(creditsContract, itoContract, 300000 * 10**18);
    remaining_credibyteSupply = users[itoContract].creditBalance.div(conversionRate_CredibytesToCredits);
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

  function finalise() public onlyOwner {    // Allows owner to finish the ITO before the timelock.
    hasFinalised = true;
  }



//  ----------------------------------------------------
//                      ITO Timelock 
//  ----------------------------------------------------

  uint256 public deploymentDate;              // The block when the timer begins counting from.
  uint256 public timelockActivationDate;      // The block when the contract locks/stops functioning.

  bool public hasFinalised;

  // If: now <= timelockActivationDate, continue functionality of ITO.
  modifier ito_Timelock {
    require(
        block.timestamp <= timelockActivationDate || hasFinalised != true, 
        "ITO phase is over: contract locked & no longer functional."
      );
    _;
  }
  
  // Allows the 
  modifier canRedeem {
    require(
        block.timestamp >= timelockActivationDate || hasFinalised == true, 
        "ITO phase is currently underway: can redeem once finalised or timelock has activated."
      );
    _;
  }


//  ----------------------------------------------------
//         Developer Funds Functions + Timelock
//  ----------------------------------------------------

  // Prevents developer(s) from withdrawing credits instantly after the ito has finished
  modifier creditsTimeLock {
    require(
      timelockActivationDate >= timelockActivationDate + 26 weeks, 
      "Error: Wait until timelock period is over to access functionality"
      );
    _;
  }

  // Allows users to view when the dev. timelock is over
  function viewTimeLockStatus() external view returns (
      uint256 timelockCommenced, 
      uint256 timelockCompletition, 
      uint256 timeRemaining
    ) { 
    return (
      timelockActivationDate,
      timelockActivationDate + 26 weeks,
      (timelockActivationDate + 26 weeks).sub(block.timestamp)
    );
  }

  // Allows the developer to withdraw "x" amount of  the remaining, unsold credits, or send them to the credits contract
  function developerCreditsWithdraw(address _to, uint256 _amount) permissionRequired creditsTimeLock external {
      users[itoContract].creditBalance = users[itoContract].creditBalance.sub(_amount);
      users[_to].creditBalance = users[_to].creditBalance.add(_amount);
      emit developerEthWithdrawal(_to, _amount, block.timestamp);
  } 

  // Allows the developer to withdraw a desired amount of ETH to their desired address
  function developerEthWithdraw(address payable _to, uint256 _amount) permissionRequired external {
      _to.transfer(_amount);
      emit developerEthWithdrawal(_to, _amount, block.timestamp);
  } 


//  ----------------------------------------------------
//                 External Functions 
//  ----------------------------------------------------

  // Allows the user to conver their credibytes to credits.
  function convertCredibytesToCredits() canRedeem public returns (uint256 convertedAmount, bool sucess){
    require(users[msg.sender].credibyteBalance != 0, "No credibytes remaining.");
    uint256 _conversionAmount = validateConversion();                                           // checks how many credits user will receive
    commenceConversion(_conversionAmount);                                                      // transfers credits to user
    emit CredibytesRedemption(msg.sender, _conversionAmount, block.timestamp);
    return (_conversionAmount, true);
  }

  // Transfers wei to designated collector & transfers credits to beneficiary. 
  function buyCredibytes_withETH(address _beneficiary) ito_Timelock public payable {
    uint256 ethAmount = msg.value;                                                              // ethAmount becomes msg.value
    
    _preValidatePurchase(_beneficiary, ethAmount);                                              // validates tx isn't sending 0 wei
    uint256 credibyteAmount = _getCredibyteAmount(ethAmount);                                   // calculates the amount of credits to be created
    
    _forwardFunds(ethAmount);                                                                   // transfers eth to itoCollector
    totalEthRaised = totalEthRaised.add(ethAmount);                                             // updates state: totalEthRaised

    _processPurchase(_beneficiary, credibyteAmount);                                            // transfers credits to beneficiary                       
    emit CredibytesPurchase(msg.sender, _beneficiary, ethAmount, credibyteAmount); 
  }

  // Views the inputted user's credibyte balance
  function viewCredibyeBalance(address user) external view returns (uint256 _credibyteBalance) {
    return users[user].credibyteBalance;
  }

  // Views how many remaining credibytes there are for purchase, with the total eth value of the remaining
  function viewRemainingCredibytesForPurchase() external view returns (
    uint256 remainingCredibytesForPurchase, 
    uint256 ethValueOfRemainingCredibytesForPurchase
    ) {
    return(
      users[itoContract].credibyteBalance,
      (users[itoContract].credibyteBalance.div(conversionRate_EthToCredibytes)).mul(1 ether)
    );
  }

  // If unlocked, call buyCredits_forWei || If locked, revert tx.
  receive() override external payable {
    if(block.timestamp <= timelockActivationDate) {
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

  function validateConversion() internal 
    returns(
      uint256 currentCredibyteConversion 
    ) {
    require (
      users[msg.sender].remainingTimeUntilNextConversion <= block.timestamp || users[msg.sender].redemptionCounter == 0,
      "Error: Must wait the remaining time until next redeption."
    );
    require (
      users[msg.sender].credibyteBalance != 0,
      "Error: Insufficient credibyte balance to redeem."
    );
        if(users[msg.sender].redemptionCounter == 0) {
          users[msg.sender].redemptionCounter = users[msg.sender].redemptionCounter.add(1);       // adds 1 onto the user's current redemption counter
          users[msg.sender].remainingTimeUntilNextConversion = block.timestamp + 4 weeks;         // adds 1 month until user's next redemption activation
          return users[msg.sender].credibyteBalance.div(4);                                       // i.e. balance = 1000, calculates 250
        } 
          else if (users[msg.sender].redemptionCounter == 1) {
            users[msg.sender].redemptionCounter = users[msg.sender].redemptionCounter.add(1);     // adds 1 onto the user's current redemption counter
            users[msg.sender].remainingTimeUntilNextConversion = block.timestamp + 4 weeks;       // adds 1 month until user's next redemption activation
            return users[msg.sender].credibyteBalance.div(3);                                     // i.e. balance = 750, calculates 250 
        } 
          else if (users[msg.sender].redemptionCounter == 2) {
            users[msg.sender].redemptionCounter = users[msg.sender].redemptionCounter.add(1);     // adds 1 onto the user's current redemption counter
            users[msg.sender].remainingTimeUntilNextConversion = block.timestamp + 4 weeks;       // adds 1 month until user's next redemption activation
            return users[msg.sender].credibyteBalance.div(2);                                     // i.e. balance = 500, calculates 250  
        } 
          else if (users[msg.sender].redemptionCounter == 3) {
            users[msg.sender].redemptionCounter = users[msg.sender].redemptionCounter.add(1);     // adds 1 onto the user's current redemption counter
            users[msg.sender].remainingTimeUntilNextConversion = 0;     
            users[msg.sender].fullyConverted = true;
            return users[msg.sender].credibyteBalance;                                            // i.e. balance = 250, calculates remaining       
        }
    }

  function commenceConversion(uint256 _conversionAmount) internal {
    users[msg.sender].credibyteBalance = 0;                                                                  // sets user's credibyte balance to 0
    credits.approve(msg.sender, _conversionAmount);
    credits.transferFrom(creditsContract, msg.sender, _conversionAmount);                                    // transfers credits from to caller
    // users[creditsContract].creditBalance = users[creditsContract].creditBalance.sub(_conversionAmount);   // deducts credits from owner wallet
    // remainingUnheldCredits = users[creditsContract].creditBalance;                                        // updates remaining unheld credits
    // users[msg.sender].creditBalance = users[msg.sender].creditBalance.add(_conversionAmount);             // gives user converted credits amount
    // totalCreditsHeld = totalCreditsSupply.sub(remainingUnheldCredits);                                    // updates total credits held
  }


//  ----------------------------------------------------
//       buyCredibytes_forETH Internal Functions 
//  ----------------------------------------------------

  function _preValidatePurchase(address _beneficiary, uint256 _ethAmount) ito_Timelock view internal {
    require(
        remaining_credibyteSupply >= (_ethAmount.mul(conversionRate_EthToCredibytes)).div(1000000000000000000), 
        "insufficent remaining credibyte supply to purchase, check remaining supply and adjust purchase amount."
      );
    require(
        _beneficiary != address(0),
        "Unable to purchase credibytes for deployer"
      );
    require(
        _ethAmount >= minEthRequirement, 
        "Does not meet the minimum purchasing requirement - refer to minEthRequirement."
      );
  }

  function _getCredibyteAmount(uint256 _ethAmount) ito_Timelock internal view returns (uint256) {
    return ((_ethAmount.mul(conversionRate_EthToCredibytes)).div(1 ether));
  }

  // Transfers eth (msg.value) to developerContract
  function _forwardFunds(uint256 ethAmount) ito_Timelock internal {
    itoContract.transfer(ethAmount);
    emit ethDepositToDeveloper(msg.sender, msg.value, block.timestamp);
  }

  // Calls _deliverTokens.
  function _processPurchase(address _beneficiary, uint256 _credibyteAmount) ito_Timelock internal {
    _deliverCredibytes(_beneficiary, _credibyteAmount);

  }

  // Updates credibyte balance
  function _deliverCredibytes(address _beneficiary, uint256 _credibyteAmount) ito_Timelock internal {
    users[_beneficiary].credibyteBalance = users[_beneficiary].credibyteBalance.add(_credibyteAmount);
    if(users[_beneficiary].redemptionCounter != 0 || users[_beneficiary].fullyConverted != false) {
      users[_beneficiary].redemptionCounter = 0;
      users[_beneficiary].fullyConverted = false;
    }
    if(users[_beneficiary].hasParticipatedInITO != true) {                                    // adds users to hasParticipated if they haven't
      users[_beneficiary].hasParticipatedInITO = true;
      itoTotalParticipants = itoTotalParticipants.add(1);
    }
  }
}