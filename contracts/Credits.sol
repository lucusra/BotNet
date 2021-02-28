//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "hardhat/console.sol"; // used for debugging smart contracts
import "./lib/Permissioned.sol";
import "./interfaces/ICredits.sol";

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
    uint256 private currentTotalSupply;                                          // Credits' total supply (can be adjusted)
    uint256 private totalSupplyCap;                                              // the amount of credits that can be generated
    address public creditsContract;                                              // the address that holds the total supply

    constructor() {    
        isPaused = false;                                                  // contract is unpaused on deployment
        creditsContract = address(this);                                   // creditsContract = this contract address (Credits.sol)    
    	currentTotalSupply = 0;                                            // total credits supply = total inital credits supply
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
    function totalSupply() override external view returns (uint totalSupply_includingDecimals, uint totalSupply_excludingDecimals) {
    	return (currentTotalSupply, (currentTotalSupply.div(10**_decimals)));	
    }
    function balanceOf(address _tokenOwner) override external view returns (uint creditBalance) {
    	return users[tokenOwner].creditBalance;
    }

//  ----------------------------------------------------
//                User Transfer Functions 
//  ----------------------------------------------------

    function transfer(address _to, uint _amount) override external pauseFunction returns (bool success) {
        // hardhat debugging 
        // console.log("Sender creditBalance is %s credits", users[_to].creditBalance);
        // console.log("Trying to send %s credits to %s", _amount, _to);
        // functionality
        require(users[msg.sender].creditBalance >= _amount, "insufficient funds, revert");
        _transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _amount) override external pauseFunction returns (bool success) {
        require(
            users[_from].creditBalance >= _amount, 
            "from address has insufficient funds, revert"
        );
        require(
            users[msg.sender].allowance[_from] >= _amount, 
            "insufficient allowance, revert"
        );
        users[msg.sender].allowance[_from] = users[msg.sender].allowance[_from].sub(_amount);
        _transfer(_from, _to, _amount);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _amount) private pauseFunction {
        if(_from == creditsContract) {
            users[_from].creditBalance = users[_from].creditBalance.sub(_amount);
            users[_to].creditBalance = users[_to].creditBalance.add(_amount);
        } else if (_to == creditsContract){
            users[_from].creditBalance = users[_from].creditBalance.sub(_amount);
            users[_to].creditBalance = users[_to].creditBalance.add(_amount);
        } else {
            users[_from].creditBalance = users[_from].creditBalance.sub(_amount);
            users[_to].creditBalance = users[_to].creditBalance.add(_amount);
        }
        emit Transfer(msg.sender, _to, _amount);
    }

//  ----------------------------------------------------
//               User Approve + Allowance 
//  ----------------------------------------------------


    function approve(address _spender, uint _amount) override external pauseFunction returns (bool success) {
    	_approve(msg.sender, _spender, _amount);
    	return true;
    }

    function _approve(address _owner, address _spender, uint _amount) private {
        users[_owner].allowance[_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function viewAllowance(address _tokenOwner, address _spender) override external pauseFunction view returns (uint remaining) {
        return users[tokenOwner].allowance[spender];
    }

//  ----------------------------------------------------
//                 Mint + Melt Credits 
//  ----------------------------------------------------

    // Temporarily placed here until the DEX is done.
    function purchaseCreditsForEth() external payable returns (uint creditsPurchased, uint etherAmount) {
        uint rate = 1000;
        uint creditsBeingPurchased = msg.value.div(rate);
        require(totalSupplyCap >= currentTotalSupply + creditsBeingPurchased, "ERROR: Total supply cap reached.");
        generateCredits(creditsBeingPurchased);
        return (creditsBeingPurchased, msg.value.div(18**10));
    }

    function generateCredits(uint _amount) private returns (uint creditsGenerated) {
        require(totalSupplyCap >= currentTotalSupply + _amount, "ERROR: Total supply cap reached.");
        users[msg.sender].creditBalance = users[msg.sender].creditBalance.add(_amount);
        currentTotalSupply = currentTotalSupply.add(_amount);
        emit generatedCredits(currentTotalSupply, msg.sender, _amount);
        return _amount;
    }

    function deleteCredits(uint _amount) override external returns (bool success) {
        require(users[msg.sender].creditBalance >= _amount);
        users[msg.sender].creditBalance = users[msg.sender].creditBalance.sub(_amount);
        currentTotalSupply = currentTotalSupply.sub(_amount);
        totalSupplyCap = totalSupplyCap.sub(_amount);
        emit deletedCredits(currentTotalSupply, _amount);
        return true;
    }

//  ----------------------------------------------------
//                 Doesn't accept eth 
//  ----------------------------------------------------
    receive() external payable {
        revert();
    }
}
