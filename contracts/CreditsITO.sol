//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

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

contract CreditsIto is Permissioned {
  using SafeMath for uint256;

  // Attaches the address's info via struct (gas efficient)
  mapping(address => _userItoInfo) userItoInfo;

  // Contains a user's ito info
  struct _userItoInfo {
    uint256 _pendingCreditBalance;                       // users' amount of credits pending for redemption
    uint256 timeUntilNextRedemption;                     // user's amount of time until next redemption period after first redemption
    uint256 redemptionCounter;                           // the amount of times the user has redeemed (each redemption is 25% of total purchased - each month)
    uint256 remainingTimeUntilNextConversion;            // how long until next redemption conversion
    bool fullyConverted;                                 // whether the user has converted all credit bonds to credits
    bool hasParticipatedInITO;                           // whether user has participated in the ito
  }

  // Contains all ito info we reference
  struct _itoInfo{
    uint256 conversionRate_EthToCredits;               // How many credibytes a buyer gets per eth.
    uint256 _totalEthRaised;                           // Amount of eth raised
    uint256 minEthRequirement;                         // minimum amount of eth required to buy credibytes
    uint256 remaining_itoCreditsSupply;                // the remaining credibytes that are available for purchase
    uint256 itoTotalParticipants;                      // the amount of ito user participants 
    uint256 deploymentDate;                            // The block when the timer begins counting from.
    uint256 timelockActivationDate;                    // The block when the contract locks/stops functioning.
    bool hasFinalised;
  }   
    
  event CreditBondPurchase(                             // Event for credibytes purchase logging
    address indexed beneficiary,                        // who paid for the credits
    address indexed creditsBondAmount,                  // credits amount purchased  
    uint256 indexed timeOfPurchase                      // amount of credits purchased
  );
  event CreditBondRedemption(                           // Event for credibytes redemption
    address indexed beneficiary,                        // user redeeming
    uint256 indexed creditsBondAmount,                  // amount of credits getting redeemed from credibytes
    uint256 indexed timeOfRedemption                    // time of redemption
  );    
  event developerEthWithdrawal(                         // event for developer withdrawing eth
    address indexed to,                                 // address the developer is sending the eth to
    uint256 indexed amount,                             // the amount of eth being sent
    uint256 indexed timeOfWithdrawal                    // the block timestamp of the withdrawal
  );
  event developerCreditsWithdrawal(                     // event for developer withdrawing credits (helps users prepare for a dump if need be)
    address indexed beneficiary,                        // the address receiving the credits
    uint256 indexed amount,                             // the amount of credits being withdrawn
    uint256 indexed timeOfWithdrawal                    // the block timestamp of the withdrawal
  );

  constructor() {
    if(msg.sender == owner) {
            grantContractAccess(address(this));
        } 
    [_itoInfo].deploymentDate = block.timestamp;
    [_itoInfo].timelockActivationDate = deploymentDate + 4 weeks;
    [_itoInfo].hasFinalised = false;
    [_itoInfo].conversionRate_EthToCredits = 10000;                 // 10,000 credits per eth
    [_itoInfo].minEthRequirement = 1 ether;                         // the minimum amount required to purchase credit bonds
    [_itoInfo].remaining_itoCreditsSupply = 3000000;                // 300,000 credits available in ito
  }


//  ----------------------------------------------------
//                      Dashboard 
//  ----------------------------------------------------

  /// @notice Allows owner to update the eth to credits conversion rate.
  function setRate_EthToCredits(uint _newRate) public onlyOwner {
    [_itoInfo].conversionRate_EthToCredits = _newRate;
  }

  /// @notice Allows owner to update the minimum amount of eth to partake in the ITO.
  function updateMinimumRequirement(uint _newMinimumRequirement) public onlyOwner {
      [_itoInfo].minEthRequirement = _newMinimumRequirement;
  }

  // Allows owner to finish the Ito before the timelock is over
  function finalise() public onlyOwner { 
    [_itoInfo].hasFinalised = true;
  }



//  ----------------------------------------------------
//        ITO Timelock, Dev Functions, Modifiers
//  ----------------------------------------------------

  // If: now <= timelockActivationDate, continue functionality of ITO.
  modifier ito_Timelock {
    require(
        block.timestamp <= [_itoInfo].timelockActivationDate || [_itoInfo].hasFinalised != true, 
        "ERROR: ITO phase is over: contract locked & no longer functional."
      );
    _;
  }
  
  // If ito is underway, fail redemption attempt
  modifier canRedeem {
    require(
        block.timestamp >= [_itoInfo].timelockActivationDate || [_itoInfo].hasFinalised == true, 
        "ERROR: ITO phase is currently underway: can redeem once finalised or timelock has activated."
      );
    _;
  }

  // Prevents developer(s) from withdrawing credits instantly after the ito has finished
  modifier creditsTimeLock {
    require(
      [_itoInfo].timelockActivationDate >= [_itoInfo].timelockActivationDate + 26 weeks, 
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
      [_itoInfo].timelockActivationDate,
      [_itoInfo].timelockActivationDate + 26 weeks,
      ([_itoInfo].timelockActivationDate + 26 weeks).sub(block.timestamp)
    );
  }

  // Allows the developer to withdraw "x" amount of  the remaining, unsold credits, or send them to the credits contract
  // function developerCreditsWithdraw(address to, uint256 amount) permissionRequired creditsTimeLock external {
  //     userItoInfo(address(this)).creditBalance = users[address(this)].creditBalance.sub(amount);
  //     users[_to].creditBalance = users[_to].creditBalance.add(amount);
  //     emit developerEthWithdrawal(to, amount, block.timestamp);
  // } 

  // Allows the developer to withdraw a desired amount of ETH to their desired address
  function developerEthWithdraw(address payable to, uint256 amount) permissionRequired external {
      to.transfer(amount);
      emit developerEthWithdrawal(to, _amount, block.timestamp);
  } 


//  ----------------------------------------------------
//                 External Functions 
//  ----------------------------------------------------

  // Allows the user to conver their credits to credits.
  function redeemCredits() canRedeem public returns (uint256 convertedAmount, bool sucess){
    require(userItoInfo(msg.sender)._pendingCreditBalance != 0, "ERROR: No credits remaining.");
    uint256 _conversionAmount = validateConversion();                                           // checks how many credits user will receive
    commenceConversion(_conversionAmount);                                                      // transfers credits to user
    return (_conversionAmount, true);
    emit CreditBondRedemption(msg.sender, _conversionAmount, block.timestamp);
  }

  // Transfers eth to designated collector & transfers credits to beneficiary. 
  function buyCreditBond_withETH(address beneficiary) ito_Timelock public payable {
    uint256 ethAmount = msg.value;
    
    // validates tx isn't sending 0 wei
    _preValidatePurchase(beneficiary, ethAmount);

    // calculates the amount of credits to be created
    uint256 creditBondAmount = _getCreditsAmount(ethAmount);
    
    // updates state: totalEthRaised
    [_itoInfo]._totalEthRaised = _totalEthRaised.add(ethAmount);

    // transfers credits to beneficiary
    _processPurchase(beneficiary, creditBondAmount); 

    emit CreditBondPurchase(msg.sender, creditBondAmount, block.timestamp); 
  }

  // Views the inputted user's credibyte balance
  function viewCreditBondBalance(address user) external view returns (uint256 _creditBondBalance) {
    return userItoInfo(user)._pendingCreditBalance;
  }

  // Views how many remaining credibytes there are for purchase, with the total eth value of the remaining
  function viewRemainingCreditsForPurchase() external view returns (
      uint256 remainingCredibytesForPurchase, 
      uint256 ethValueOfRemainingCredibytesForPurchase
    ) {
    return(
      [_itoInfo].remaining_itoCreditsSupply,
      [_itoInfo].remaining_itoCreditsSupply.div(10000)
    );
  }
  
  function viewEthRaised() external view returns (uint256 totalEthRaised, uint256 ethCurrentlyLocked){
      return ([_itoInfo]._totalEthRaised, address(this).balance);
  }

  // If unlocked, call buyCredits_forEth || If locked, revert tx.
  receive() external payable {
    if(block.timestamp <= [_itoInfo].timelockActivationDate) {
      buyCreditBond_withETH(msg.sender); 
    } else { revert(); }
  }


//  ----------------------------------------------------
//         Redeem Credits Internal Functions 
//  ----------------------------------------------------

  function validateConversion() internal returns(uint256 currentCredibyteConversion) {
    require (
      userItoInfo(msg.sender).remainingTimeUntilNextConversion <= block.timestamp || userItoInfo(msg.sender).redemptionCounter == 0,
      "ERROR: Must wait the remaining time until next redeption."
    );
    require (
      userItoInfo(msg.sender)._pendingCreditBalance != 0,
      "ERROR: Insufficient credibyte balance to redeem."
    );

    if(userItoInfo(msg.sender).redemptionCounter == 0) {
      userItoInfo(msg.sender).redemptionCounter = userItoInfo(msg.sender).redemptionCounter.add(1);     // adds 1 onto the user's current redemption counter
      userItoInfo(msg.sender).remainingTimeUntilNextConversion = block.timestamp + 4 weeks;             // adds 1 month until user's next redemption activation
      return userItoInfo(msg.sender)._pendingCreditBalance.div(4);                                      // i.e. balance = 1000, calculates 250
    } 
      else if (userItoInfo(msg.sender).redemptionCounter == 1) {
        userItoInfo(msg.sender).redemptionCounter = userItoInfo(msg.sender).redemptionCounter.add(1);   // adds 1 onto the user's current redemption counter
        userItoInfo(msg.sender).remainingTimeUntilNextConversion = block.timestamp + 4 weeks;           // adds 1 month until user's next redemption activation
        return userItoInfo(msg.sender)._pendingCreditBalance.div(3);                                    // i.e. balance = 750, calculates 250 
    } 
      else if (userItoInfo(msg.sender).redemptionCounter == 2) {
        userItoInfo(msg.sender).redemptionCounter = userItoInfo(msg.sender).redemptionCounter.add(1);   // adds 1 onto the user's current redemption counter
        userItoInfo(msg.sender).remainingTimeUntilNextConversion = block.timestamp + 4 weeks;           // adds 1 month until user's next redemption activation
        return userItoInfo(msg.sender)._pendingCreditBalance.div(2);                                    // i.e. balance = 500, calculates 250  
    } 
      else if (userItoInfo(msg.sender).redemptionCounter == 3) {
        userItoInfo(msg.sender).redemptionCounter = userItoInfo(msg.sender).redemptionCounter.add(1);   // adds 1 onto the user's current redemption counter
        userItoInfo(msg.sender).remainingTimeUntilNextConversion = 0;     
        userItoInfo(msg.sender).fullyConverted = true;
        return userItoInfo(msg.sender)._pendingCreditBalance;                                           // i.e. balance = 250, calculates remaining       
    }
    }

  function commenceConversion(uint256 _conversionAmount) internal {
    // sets user's pending credit balance to 0
    userItoInfo(msg.sender)._pendingCreditBalance = 0;

    // approves _conversionAmount to be sent from credit contract to msg.sender
    credits.contractApprove(address(credits), msg.sender, _conversionAmount);

    // transfers credits from credits contract to caller
    credits.transferFrom(address(credits), msg.sender, _conversionAmount);
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
    users[_beneficiary]._pendingCreditBalance = users[_beneficiary]._pendingCreditBalance.add(_bondAmount);
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
