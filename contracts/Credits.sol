//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./lib/Permissioned.sol";
import "./interfaces/ICredits.sol";
import "./CreditsIto.sol";

// ----------------------------------------------------------------------------
//
//                      (c) The BotNet Project 2020
//
// ----------------------------------------------------------------------------

contract Credits is ICredits, Permissioned {
	using SafeMath for uint256;

//  ----------------------------------------------------
//               Variables + Constructor
//  ----------------------------------------------------

	string _name = "Credits";
    string _symbol = "CRDTS";
    uint8 _decimals = 18;                       

    // Credits' total supply (can be adjusted)
    uint256 private _currentTotalSupply;

    // the amount of credits that can be generated
    uint256 private _totalSupplyCap;

    // User's Credit balance
    mapping (address => uint256) creditBalance;

    // An amount of Credits the assignee is allowed to use from the assigner 
    mapping(address => mapping(address => uint256)) allowance;

    // If ito is underway, fail redemption attempt
    modifier canRedeem {
        require(
            block.timestamp >= itoInfo.timelockActivationDate || itoInfo.hasFinalised == true, 
            "ERROR: ITO phase is currently underway: can redeem once finalised or timelock has activated."
        );
        _;
    }

    constructor() {
        if(msg.sender == owner) {
            grantContractAccess(address(this));
        } 
        isPaused = false;
    	_currentTotalSupply = 0;
        _totalSupplyCap = 1000000 * (_decimals ** 10); // 1 mil total supply
    }

//  ----------------------------------------------------
//                   View Functions 
//  ----------------------------------------------------

    function symbol() override external view returns (string memory) {
        return _symbol;
    }
    function name() override external view returns (string memory) {
        return _name;
    }
    function decimals() override external view returns (uint8) {
        return _decimals;
    }
    function totalSupply() override external view returns (uint256 tokenTotalSupply) {
    	return _currentTotalSupply;	
    }
    function totalSupplyCap() override external view returns (uint256) {
        return _totalSupplyCap;
    }
    function balanceOf(address tokenOwner) override external view returns (uint256) {
    	return tokenOwner.creditBalance;
    }

//  ----------------------------------------------------
//                User Transfer Functions 
//  ----------------------------------------------------

    function transfer(address to, uint256 amount) override external pauseFunction returns (bool success) {
        require(msg.sender.creditBalance >= amount, "insufficient funds, revert");
        _transfer(msg.sender, to, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) override external pauseFunction returns (bool success) {
        require(
            from.creditBalance >= amount, 
            "from address has insufficient funds, revert"
        );
        require(
            msg.sender.allowance(from) >= amount, 
            "insufficient allowance, revert"
        );
        msg.sender.allowance(from) = msg.sender.allowance(from).sub(amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _amount) private pauseFunction {
        if(_from == address(this)) {
            _from.creditBalance = _from.creditBalance.sub(_amount);
            _to.creditBalance = _to.creditBalance.add(_amount);
        } else if (_to == address(this)){
            _from.creditBalance = _from.creditBalance.sub(_amount);
            _to.creditBalance = _to.creditBalance.add(_amount);
            deleteCredits(address(this), _amount);
        } else {
            _from.creditBalance = _from.creditBalance.sub(_amount);
            _to.creditBalance = _to.creditBalance.add(_amount);
        }
        emit Transfer(msg.sender, _to, _amount);
    }


//  ----------------------------------------------------
//               User Approve + Allowance 
//  ----------------------------------------------------

    function viewAllowance(address tokenOwner, address spender) override external pauseFunction view returns (uint remaining) {
        return (tokenOwner)(spender).allowance;
    }

    // approves 
    function approve(address spender, uint amount) override external pauseFunction returns (bool success) {
    	_approve(msg.sender, spender, amount);
    	return true;
    }

    function _approve(address _owner, address _spender, uint _amount) private {
        (_owner)(_spender).allowance = _amount;
        emit Approval(_owner, _spender, _amount);
    }


//  ----------------------------------------------------
//                  Mint + Melt Credits 
//  ----------------------------------------------------

    ///@dev Generates Credits, if supply cap hasn't been reached.
    function generateCredits(address _address, uint _amount) private returns (uint creditsGenerated) {
        require(_totalSupplyCap >= _currentTotalSupply.add(_amount), "ERROR: Total supply cap reached.");
        _address.creditBalance = _address.creditBalance.add(_amount);
        _currentTotalSupply = _currentTotalSupply.add(_amount);
        emit generatedCredits(_currentTotalSupply, _address, _amount);
        return _amount;
    }

    ///@dev Deletes Credits form caller's account
    // [ ] Need to add voting system for community to burn a user's tokens - if a hack occurred
    function deleteCredits(address _address, uint _amount) private returns (bool success) {
        require(_address.creditBalance >= _amount);
        _address.creditBalance = _address.creditBalance.sub(_amount);
        _currentTotalSupply = _currentTotalSupply.sub(_amount);
        emit deletedCredits(_currentTotalSupply, _amount);
        return true;
    }


//  ----------------------------------------------------
//                    Ito Functions 
//  ----------------------------------------------------
    // Allows the user to conver their credits to credits.
    function redeemCredits() canRedeem public returns (uint256 convertedAmount, bool sucess){
    require(
        userItoInfo(msg.sender)._pendingCreditBalance != 0, 
        "ERROR: No credits remaining."
    );

    // checks how many credits user will receive
    uint256 _conversionAmount = validateConversion();

    // transfers credits to user
    commenceConversion(_conversionAmount);
    
    return (_conversionAmount, true);
    emit CreditBondRedemption(msg.sender, _conversionAmount, block.timestamp);
    }

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
    } else if (userItoInfo(msg.sender).redemptionCounter == 1) {
        userItoInfo(msg.sender).redemptionCounter = userItoInfo(msg.sender).redemptionCounter.add(1);   // adds 1 onto the user's current redemption counter
        userItoInfo(msg.sender).remainingTimeUntilNextConversion = block.timestamp + 4 weeks;           // adds 1 month until user's next redemption activation
        return userItoInfo(msg.sender)._pendingCreditBalance.div(3);                                    // i.e. balance = 750, calculates 250 
    } else if (userItoInfo(msg.sender).redemptionCounter == 2) {
        userItoInfo(msg.sender).redemptionCounter = userItoInfo(msg.sender).redemptionCounter.add(1);   // adds 1 onto the user's current redemption counter
        userItoInfo(msg.sender).remainingTimeUntilNextConversion = block.timestamp + 4 weeks;           // adds 1 month until user's next redemption activation
        return userItoInfo(msg.sender)._pendingCreditBalance.div(2);                                    // i.e. balance = 500, calculates 250  
    } else if (userItoInfo(msg.sender).redemptionCounter == 3) {
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
        contractApprove(address(this), msg.sender, _conversionAmount);

        // transfers credits from credits contract to caller
        transferFrom(address(this), msg.sender, _conversionAmount);
    }
//  ----------------------------------------------------
//                 Doesn't accept eth 
//  ----------------------------------------------------
    
    // revert any eth txs to this contract
    receive() external payable {
        revert();
    }
}