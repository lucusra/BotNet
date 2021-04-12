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
  struct _itoInfo {
    uint256 conversionRate_EthToCredits;               // How many credibytes a buyer gets per eth.
    uint256 _totalEthRaised;                           // Amount of eth raised
    uint256 minEthRequirement;                         // minimum amount of eth required to buy credibytes
    uint256 remaining_itoCreditsSupply;                // the remaining credibytes that are available for purchase
    uint256 itoTotalParticipants;                      // the amount of ito user participants 
    uint256 deploymentDate;                            // The block when the timer begins counting from.
    uint256 timelockActivationDate;                    // The block when the contract locks/stops functioning.
    bool hasFinalised;
  }   

  _itoInfo itoInfo;
    
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
    
    itoInfo.deploymentDate = block.timestamp;
    itoInfo.timelockActivationDate = itoInfo.deploymentDate + 4 weeks;
    itoInfo.hasFinalised = false;
    itoInfo.conversionRate_EthToCredits = 10000;                 // 10,000 credits per eth
    itoInfo.minEthRequirement = 1 ether;                         // the minimum amount required to purchase credit bonds
    itoInfo.remaining_itoCreditsSupply = 3000000;                // 300,000 credits available in ito
  }


//  ----------------------------------------------------
//                      Dashboard 
//  ----------------------------------------------------

  /// @notice Allows owner to update the eth to credits conversion rate.
  function setRate_EthToCredits(uint _newRate) public onlyOwner {
    itoInfo.conversionRate_EthToCredits = _newRate;
  }

  /// @notice Allows owner to update the minimum amount of eth to partake in the ITO.
  function updateMinimumRequirement(uint _newMinimumRequirement) public onlyOwner {
      itoInfo.minEthRequirement = _newMinimumRequirement;
  }

  // Allows owner to finish the Ito before the timelock is over
  function finalise() public onlyOwner { 
    itoInfo.hasFinalised = true;
  }



//  ----------------------------------------------------
//        ITO Timelock, Dev Functions, Modifiers
//  ----------------------------------------------------

  // If: now <= timelockActivationDate, continue functionality of ITO.
  modifier ito_Timelock {
    require(
        block.timestamp <= itoInfo.timelockActivationDate || itoInfo.hasFinalised != true, 
        "ERROR: ITO phase is over: contract locked & no longer functional."
      );
    _;
  }
  
  // If ito is underway, fail redemption attempt
  modifier canRedeem {
    require(
        block.timestamp >= itoInfo.timelockActivationDate || itoInfo.hasFinalised == true, 
        "ERROR: ITO phase is currently underway: can redeem once finalised or timelock has activated."
      );
    _;
  }

  // Prevents developer(s) from withdrawing credits instantly after the ito has finished
  modifier creditsTimeLock {
    require(
      itoInfo.timelockActivationDate >= itoInfo.timelockActivationDate + 26 weeks, 
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
      itoInfo.timelockActivationDate,
      itoInfo.timelockActivationDate + 26 weeks,
      (itoInfo.timelockActivationDate + 26 weeks).sub(block.timestamp)
    );
  }

  // Allows the developer to withdraw "x" amount of  the remaining, unsold credits, or send them to the credits contract
  // function developerCreditsWithdraw(address to, uint256 amount) permissionRequired creditsTimeLock external {
  //     userItoInfo(address(this)).creditBalance = users[address(this)].creditBalance.sub(amount);
  //     users[_to].creditBalance = users[_to].creditBalance.add(amount);
  //     emit developerEthWithdrawal(to, amount, block.timestamp);
  // } 

  // Allows the developer to withdraw a desired amount of ETH to their desired address
  function developerEthWithdraw(address payable to, uint256 amount) onlyOwner external {
      to.transfer(amount);
      emit developerEthWithdrawal(to, amount, block.timestamp);
  } 


//  ----------------------------------------------------
//                 External Functions 
//  ----------------------------------------------------

  // Transfers eth to designated collector & transfers credits to beneficiary. 
  function buyCreditBond_withETH(address beneficiary) ito_Timelock public payable {
    uint256 ethAmount = msg.value;
    
    // validates tx isn't sending 0 wei
    _preValidatePurchase(beneficiary, ethAmount);

    // calculates the amount of credits to be created
    uint256 creditBondAmount = _getCreditsAmount(ethAmount);
    
    // updates state: totalEthRaised
    itoInfo._totalEthRaised = itoInfo._totalEthRaised.add(ethAmount);

    // transfers credits to beneficiary
    _processPurchase(beneficiary, creditBondAmount); 

    // emit CreditBondPurchase(msg.sender, creditBondAmount, block.timestamp); 
  }

  // Views the inputted user's credibyte balance
  function viewCreditBondBalance(address user) external view returns (uint256 _creditBondBalance) {
    return userItoInfo[user]._pendingCreditBalance;
  }

  // Views how many remaining credibytes there are for purchase, with the total eth value of the remaining
  function viewRemainingCreditsForPurchase() external view returns (
      uint256 remainingCredibytesForPurchase, 
      uint256 ethValueOfRemainingCredibytesForPurchase
    ) {
    return(
      itoInfo.remaining_itoCreditsSupply,
      itoInfo.remaining_itoCreditsSupply.div(10000)
    );
  }
  
  function viewEthRaised() external view returns (uint256 totalEthRaised, uint256 ethCurrentlyLocked){
      return (itoInfo._totalEthRaised, address(this).balance);
  }

  // If unlocked, call buyCredits_forEth || If locked, revert tx.
  receive() external payable {
    if(block.timestamp <= itoInfo.timelockActivationDate) {
      buyCreditBond_withETH(msg.sender); 
    } else { revert(); }
  }


//  ----------------------------------------------------
//         buyCredits_forETH Internal Functions 
//  ----------------------------------------------------



  function _preValidatePurchase(address _beneficiary, uint256 _ethAmount) ito_Timelock view internal {
    require(
        itoInfo.remaining_itoCreditsSupply >= (_ethAmount.mul(itoInfo.conversionRate_EthToCredits)).div(10**18), // (1 eth * 10,000)/ 1 eth = 10,000 crediBonds
        "ERROR: Insufficent remaining credibyte supply to purchase, check remaining supply and adjust purchase amount."
      );
    require(
        _beneficiary != address(this),
        "ERROR: Unable to purchase credibytes for this contract."
      );
    require(
        _ethAmount >= itoInfo.minEthRequirement, 
        "ERROR: Does not meet the minimum purchasing requirement: refer to minEthRequirement."
      );
  }

  function _getCreditsAmount(uint256 _ethAmount) ito_Timelock internal view returns (uint256) {
    return (_ethAmount.mul(itoInfo.conversionRate_EthToCredits)).div(18**10);   // (1 eth * 10,000)/ 1 eth = 10,000 creditBonds
  }


  // Calls _deliverTokens.
  function _processPurchase(address _beneficiary, uint256 _bondAmount) ito_Timelock internal {
    _deliverCreditBond(_beneficiary, _bondAmount);
  }
  
  // Updates crediBond balance
  function _deliverCreditBond(address _beneficiary, uint256 _bondAmount) ito_Timelock internal {
    itoInfo.remaining_itoCreditsSupply = itoInfo.remaining_itoCreditsSupply.sub(_bondAmount);
    userItoInfo[_beneficiary]._pendingCreditBalance = userItoInfo[_beneficiary]._pendingCreditBalance.add(_bondAmount);

    // If redemption counter is not 0, or is not fully converted, set counter to 0 & fullyConverted to 0
    if(userItoInfo[_beneficiary].redemptionCounter != 0 || userItoInfo[_beneficiary].fullyConverted != false) {
      userItoInfo[_beneficiary].redemptionCounter = 0;
      userItoInfo[_beneficiary].fullyConverted = false;
    }
    // adds users to hasParticipated if they haven't been added
    if(userItoInfo[_beneficiary].hasParticipatedInITO != true) {
      userItoInfo[_beneficiary].hasParticipatedInITO = true;
      itoInfo.itoTotalParticipants = itoInfo.itoTotalParticipants.add(1);
    }
  }
}