//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Credits.sol";
import "./lib/Permissioned.sol";

/// @title Inital Token Offering (ITO)
/// @dev ITO is the contract for managing the Credits' crowdsale
// allowing investors to purchase Credits for Ether. 

// TO DO...
// [X] MAKE INTO A SLOW DRIP INSTEAD OF EVERYONE GETS AT ONCE (i.e. 25% at the start of each month for 4 months)
// [X] MAKE TOKENS CLAIMABLE FOR CREDITS  
// [ ] MAKE MODIFIER "SOLD OUT" FOR REMAINING CREDIBYTES REMAINING, THAT ARE ABLE TO BE PURCHASED
// [ ] MAKE A CREDITS TOTAL SUPPLY 
// [ ] FIX TRANSFERFROM & TRANSFER FUNCTION SO DEVS CANT DRAIN SUPPLY

contract CreditsITO is Permissioned {
  using SafeMath for uint256;

  Credits credits;                                      // The token being sold

  uint256 public conversionRate_EthToCredits;           // How many credibytes a buyer gets per eth.
  uint256 private _totalEthRaised;                        // Amount of eth raised
  uint256 public minEthRequirement;                     // minimum amount of eth required to buy credibytes
  uint256 public remaining_itoCreditsSupply;             // the remaining credibytes that are available for purchase
  uint256 public itoTotalParticipants;                  // the amount of ito user participants 
    
    
  event CreditBondPurchase(                             // Event for credibytes purchase logging
    address indexed purchaser,                          // who paid for the credits
    address indexed beneficiary,                        // who received the credits
    uint256 ethAmount,                                  // ethers paid for credits
    uint256 credibyteAmount                             // amount of credits purchased
  );
  event CreditBondRedemption(                           // Event for credibytes redemption
    address indexed redeemer,                           // user redeeming
    uint256 indexed creditsAmount,                      // amount of credits getting redeemed from credibytes
    uint256 time                                        // time of redemption
  );    
  event developerEthWithdrawal(                         // event for developer withdrawing eth
    address indexed to,                                 // address the developer is sending the eth to
    uint256 indexed amount,                             // the amount of eth being sent
    uint256 indexed timeOfWithdrawal                    // the block timestamp of the withdrawal
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
    conversionRate_EthToCredits = 10000;
    minEthRequirement = 1 ether;                                                // the minimum amount required to purchase credibytes
    
    users[address(this)].hasContractAccess = true;                                // is given contract access for contractApprove()
    remaining_itoCreditsSupply = 85000000;                                       // 8,500,000 credits available
  }


//  ----------------------------------------------------
//                      Dashboard 
//  ----------------------------------------------------

  /// @notice Allows owner to update the eth to credibytes conversion rate.
  /// @param _newRate new eth to credibytes conversion rate.
  function setRate_EthToCredits(uint _newRate) public onlyOwner {
    conversionRate_EthToCredits = _newRate;
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
//        ITO Timelock, Dev Functions, Modifiers
//  ----------------------------------------------------

  uint256 public deploymentDate;              // The block when the timer begins counting from.
  uint256 public timelockActivationDate;      // The block when the contract locks/stops functioning.
  bool public hasFinalised;

  // If: now <= timelockActivationDate, continue functionality of ITO.
  modifier ito_Timelock {
    require(
        block.timestamp <= timelockActivationDate || hasFinalised != true, 
        "ERROR: ITO phase is over: contract locked & no longer functional."
      );
    _;
  }
  
  // Allows the 
  modifier canRedeem {
    require(
        block.timestamp >= timelockActivationDate || hasFinalised == true, 
        "ERROR: ITO phase is currently underway: can redeem once finalised or timelock has activated."
      );
    _;
  }

  // Prevents developer(s) from withdrawing credits instantly after the ito has finished
  modifier creditsTimeLock {
    require(
      timelockActivationDate >= timelockActivationDate + 26 weeks, 
      "ERROR: Wait until timelock period is over to access functionality."
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
      users[address(this)].creditBalance = users[address(this)].creditBalance.sub(_amount);
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

  // Allows the user to conver their credits to credits.
  function redeemCredits() canRedeem public returns (uint256 convertedAmount, bool sucess){
    require(users[msg.sender].creditBondBalance != 0, "ERROR: No credits remaining.");
    uint256 _conversionAmount = validateConversion();                                           // checks how many credits user will receive
    commenceConversion(_conversionAmount);                                                      // transfers credits to user
    emit CreditBondRedemption(msg.sender, _conversionAmount, block.timestamp);
    return (_conversionAmount, true);
  }

  // Transfers eth to designated collector & transfers credits to beneficiary. 
  function buyCreditBond_withETH(address _beneficiary) ito_Timelock public payable {
    uint256 ethAmount = msg.value;                                                              // ethAmount becomes msg.value
    
    _preValidatePurchase(_beneficiary, ethAmount);                                              // validates tx isn't sending 0 wei
    uint256 creditBondAmount = _getCreditsAmount(ethAmount);                                   // calculates the amount of credits to be created
    
    _totalEthRaised = _totalEthRaised.add(ethAmount);                                             // updates state: totalEthRaised

    _processPurchase(_beneficiary, creditBondAmount);                                            // transfers credits to beneficiary                       
    emit CreditBondPurchase(msg.sender, _beneficiary, ethAmount, creditBondAmount); 
  }

  // Views the inputted user's credibyte balance
  function viewCreditBondBalance(address user) external view returns (uint256 _creditBondBalance) {
    return users[user].creditBondBalance;
  }

  // Views how many remaining credibytes there are for purchase, with the total eth value of the remaining
  function viewRemainingCreditsForPurchase() external view returns (
    uint256 remainingCredibytesForPurchase, 
    uint256 ethValueOfRemainingCredibytesForPurchase
    ) {
    return(
      remaining_itoCreditsSupply,
      remaining_itoCreditsSupply.div(10000)
    );
  }
  
  function viewEthRaised() external view returns (uint256 totalEthRaised, uint256 ethCurrentlyLocked){
      return (_totalEthRaised, address(this).balance);
  }

  // If unlocked, call buyCredits_forEth || If locked, revert tx.
  receive() external payable {
    if(block.timestamp <= timelockActivationDate) {
      buyCreditBond_withETH(msg.sender); 
    } else { revert(); }
  }


//  ----------------------------------------------------
//         Redeem Credits Internal Functions 
//  ----------------------------------------------------

  function validateConversion() internal 
    returns(
      uint256 currentCredibyteConversion 
    ) {
    require (
      users[msg.sender].remainingTimeUntilNextConversion <= block.timestamp || users[msg.sender].redemptionCounter == 0,
      "ERROR: Must wait the remaining time until next redeption."
    );
    require (
      users[msg.sender].creditBondBalance != 0,
      "ERROR: Insufficient credibyte balance to redeem."
    );
        if(users[msg.sender].redemptionCounter == 0) {
          users[msg.sender].redemptionCounter = users[msg.sender].redemptionCounter.add(1);       // adds 1 onto the user's current redemption counter
          users[msg.sender].remainingTimeUntilNextConversion = block.timestamp + 4 weeks;         // adds 1 month until user's next redemption activation
          return users[msg.sender].creditBondBalance.div(4);                                       // i.e. balance = 1000, calculates 250
        } 
          else if (users[msg.sender].redemptionCounter == 1) {
            users[msg.sender].redemptionCounter = users[msg.sender].redemptionCounter.add(1);     // adds 1 onto the user's current redemption counter
            users[msg.sender].remainingTimeUntilNextConversion = block.timestamp + 4 weeks;       // adds 1 month until user's next redemption activation
            return users[msg.sender].creditBondBalance.div(3);                                     // i.e. balance = 750, calculates 250 
        } 
          else if (users[msg.sender].redemptionCounter == 2) {
            users[msg.sender].redemptionCounter = users[msg.sender].redemptionCounter.add(1);     // adds 1 onto the user's current redemption counter
            users[msg.sender].remainingTimeUntilNextConversion = block.timestamp + 4 weeks;       // adds 1 month until user's next redemption activation
            return users[msg.sender].creditBondBalance.div(2);                                     // i.e. balance = 500, calculates 250  
        } 
          else if (users[msg.sender].redemptionCounter == 3) {
            users[msg.sender].redemptionCounter = users[msg.sender].redemptionCounter.add(1);     // adds 1 onto the user's current redemption counter
            users[msg.sender].remainingTimeUntilNextConversion = 0;     
            users[msg.sender].fullyConverted = true;
            return users[msg.sender].creditBondBalance;                                            // i.e. balance = 250, calculates remaining       
        }
    }

  function commenceConversion(uint256 _conversionAmount) internal {
    users[msg.sender].creditBondBalance = 0;                                                                  // sets user's credibyte balance to 0
    credits.contractApprove(address(credits), msg.sender, _conversionAmount);
    credits.transferFrom(address(credits), msg.sender, _conversionAmount);                                    // transfers credits from to caller
  }


//  ----------------------------------------------------
//         buyCredits_forETH Internal Functions 
//  ----------------------------------------------------

  function _preValidatePurchase(address _beneficiary, uint256 _ethAmount) ito_Timelock view internal {
    require(
        remaining_itoCreditsSupply >= (_ethAmount.mul(conversionRate_EthToCredits)).div(1000000000000000000), // (1 eth * 10,000)/ 1 eth = 10,000 credibytes
        "ERROR: Insufficent remaining credibyte supply to purchase, check remaining supply and adjust purchase amount."
      );
    require(
        _beneficiary != address(this) && _beneficiary != address(credits),
        "ERROR: Unable to purchase credibytes for itoContract or creditsContract."
      );
    require(
        _ethAmount >= minEthRequirement, 
        "ERROR: Does not meet the minimum purchasing requirement: refer to minEthRequirement."
      );
  }

  function _getCreditsAmount(uint256 _ethAmount) ito_Timelock internal view returns (uint256) {
    return (_ethAmount.mul(conversionRate_EthToCredits)).div(1000000000000000000);   // (1 eth * 10,000)/ 1 eth = 10,000 credibytes
  }


  // Calls _deliverTokens.
  function _processPurchase(address _beneficiary, uint256 _bondAmount) ito_Timelock internal {
    _deliverCreditsBond(_beneficiary, _bondAmount);

  }

  // Updates credibyte balance
  function _deliverCreditsBond(address _beneficiary, uint256 _bondAmount) ito_Timelock internal {
    remaining_itoCreditsSupply = remaining_itoCreditsSupply.sub(_bondAmount);
    users[_beneficiary].creditBondBalance = users[_beneficiary].creditBondBalance.add(_bondAmount);
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
