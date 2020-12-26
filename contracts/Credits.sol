//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Permissioned.sol";
import "./ICredits.sol";

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
    uint256 public initialCreditsSupply;        // supply upon deployment
    uint256 private totalCreditsSupply;         // Credits' total supply (can be adjusted)
    uint256 public totalCreditsHeld;	        // how many Credits are in custody of users
    uint256 public remainingUnheldCredits;      // amount of credits that aren't owned
    address payable creditsContract;            // the address that holds the total supply

    constructor() {    
        creditsContract = address(this);                                   // creditsContract = this contract address (Credits.sol)     
        initialCreditsSupply = 1500000 * 10**uint(_decimals);              // 1,500,000 inital credits supply
    	totalCreditsSupply = initialCreditsSupply;                         // total credits supply = total inital credits supply
        totalCreditsHeld = 0;                                              // credits held by users = 0
    	isPaused = false;                                                  // contract is unpaused on deployment
        users[creditsContract].creditBalance = totalCreditsSupply;         // creditsContract owns total supply
        remainingUnheldCredits = users[creditsContract].creditBalance;     // amount of credits that aren't owned = total supply
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
    function totalSupply() override external view returns (uint) {
    	return totalCreditsSupply;	
    }
    function balanceOf(address tokenOwner) override external view returns (uint creditBalance) {
    	return users[tokenOwner].creditBalance;
    }

//  ----------------------------------------------------
//                 Transfer Functions 
//  ----------------------------------------------------

    function transfer(address _to, uint _value) override external pauseFunction returns (bool success) {
        require(users[msg.sender].creditBalance >= _value, "insufficient funds, revert");
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) override external pauseFunction returns (bool success) {
        require(users[_from].creditBalance >= _value, "from address has insufficient funds, revert");
        require(users[msg.sender].allowance[_from] >= _value, "insufficient allowance, revert");
        require(users[msg.sender].allowance[_from] <= users[_from].creditBalance);
        users[msg.sender].allowance[_from] = users[msg.sender].allowance[_from].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) private pauseFunction {
        if(_from == creditsContract) {
            users[_from].creditBalance = users[_from].creditBalance.sub(_value);
            users[_to].creditBalance = users[_to].creditBalance.add(_value);
            remainingUnheldCredits = users[owner].creditBalance;
            totalCreditsHeld = totalCreditsSupply.add(remainingUnheldCredits);
        } else if (_to == creditsContract){
            users[_from].creditBalance = users[_from].creditBalance.sub(_value);
            users[_to].creditBalance = users[_to].creditBalance.add(_value);
            remainingUnheldCredits = users[owner].creditBalance;
            totalCreditsHeld = totalCreditsSupply.sub(remainingUnheldCredits);
        } else {
            users[_from].creditBalance = users[_from].creditBalance.sub(_value);
            users[_to].creditBalance = users[_to].creditBalance.add(_value);
        }
        emit Transfer(msg.sender, _to, _value);
    }

//  ----------------------------------------------------
//                 Approve + Allowance 
//  ----------------------------------------------------

    function approve(address _spender, uint _value) override external pauseFunction returns (bool success) {
    	_approve(msg.sender, _spender, _value);
    	return true;
    }

    function _approve(address _owner, address _spender, uint _value) private {
        users[_owner].allowance[_spender] = _value;
        emit Approval(_owner, _spender, _value);
    }

    function viewAllowance(address tokenOwner, address spender) override external pauseFunction view returns (uint remaining) {
        return users[tokenOwner].allowance[spender];
    }

//  ----------------------------------------------------
//                 Mint + Burn Credits 
//  ----------------------------------------------------

    function generateCredits(address _to, uint _amount) override external onlyOwner returns (bool success) {
        users[_to].creditBalance = users[_to].creditBalance.add(_amount);
        totalCreditsSupply = totalCreditsSupply.add(_amount);
        totalCreditsHeld = totalCreditsHeld.add(_amount);
        remainingUnheldCredits = users[owner].creditBalance;              
        emit generatedCredits(totalCreditsSupply, _to, _amount);
        return true;
    }
    function deleteCredits(uint _amount) override external onlyOwner returns (bool success) {
        require(users[creditsContract].creditBalance >= _amount);
        users[creditsContract].creditBalance = users[creditsContract].creditBalance.sub(_amount);
        totalCreditsSupply = totalCreditsSupply.sub(_amount);
        remainingUnheldCredits = users[creditsContract].creditBalance;    
        emit deletedCredits(totalCreditsSupply, _amount);
        return true;
    }

    // ------------------------------------------------------------------------
    //                          Don't accept ETH
    // ------------------------------------------------------------------------
    receive () virtual external payable {
        revert();
    }
}