//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./lib/Permissioned.sol";
import "./interfaces/ICredits.sol";

// ----------------------------------------------------------------------------
//
//                      (c) The BotNet Project 2020
//
// ----------------------------------------------------------------------------

contract mCredits is ICredits, Permissioned {
	using SafeMath for uint256;

//  ----------------------------------------------------
//               Variables + Constructor
//  ----------------------------------------------------

	string _name = "Credits";
    string _symbol = "CRDTS";
    uint8 _decimals = 18;                       
    uint256 private _currentTotalSupply;                                          // Credits' total supply (can be adjusted)
    uint256 private _totalSupplyCap;                                              // the amount of credits that can be generated

    constructor() {
        if(msg.sender == owner) {
            grantContractAccess(address(this));
        } 
        isPaused = false;                                                  // contract is unpaused on deployment
    	_currentTotalSupply = 0;                                            // total credits supply = total inital credits supply
        _totalSupplyCap = 1000000 * (_decimals ** 10);
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
    function balanceOf(address _tokenOwner) override external view returns (uint256 creditBalance) {
    	return users[_tokenOwner].creditBalance;
    }

//  ----------------------------------------------------
//                User Transfer Functions 
//  ----------------------------------------------------

    function transfer(address _to, uint256 _amount) override external pauseFunction returns (bool success) {
        require(users[msg.sender].creditBalance >= _amount, "insufficient funds, revert");
        _transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) override external pauseFunction returns (bool success) {
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
        if(_from == address(this)) {
            users[_from].creditBalance = users[_from].creditBalance.sub(_amount);
            users[_to].creditBalance = users[_to].creditBalance.add(_amount);
        } else if (_to == address(this)){
            users[_from].creditBalance = users[_from].creditBalance.sub(_amount);
            users[_to].creditBalance = users[_to].creditBalance.add(_amount);
            deleteCredits(address(this), _amount);
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
        return users[_tokenOwner].allowance[_spender];
    }


//  ----------------------------------------------------
//                 Mint + Melt Credits 
//  ----------------------------------------------------

    ///@dev Temporarily placed here until the DEX is done.
    function purchaseCreditsForEth() override external payable returns (uint creditsPurchased, uint etherAmount) {
        uint256 rate = 1000;
        uint256 creditsBeingPurchased = msg.value.div(rate);
        require(_totalSupplyCap >= _currentTotalSupply.add(creditsBeingPurchased), "ERROR: Total supply cap reached.");
        generateCredits(msg.sender, creditsBeingPurchased);
        return (creditsBeingPurchased, msg.value.div(18**10));
    }

    ///@dev Generates Credits, if supply cap hasn't been reached.
    function generateCredits(address _address, uint _amount) private returns (uint creditsGenerated) {
        require(_totalSupplyCap >= _currentTotalSupply.add(_amount), "ERROR: Total supply cap reached.");
        users[_address].creditBalance = users[_address].creditBalance.add(_amount);
        _currentTotalSupply = _currentTotalSupply.add(_amount);
        emit generatedCredits(_currentTotalSupply, _address, _amount);
        return _amount;
    }

    ///@dev Deletes Credits form caller's account
    // [ ] Need to add voting system for community to burn a user's tokens - if a hack occurred
    function deleteCredits(address _address, uint _amount) private returns (bool success) {
        require(users[_address].creditBalance >= _amount);
        users[_address].creditBalance = users[_address].creditBalance.sub(_amount);
        _currentTotalSupply = _currentTotalSupply.sub(_amount);
        emit deletedCredits(_currentTotalSupply, _amount);
        return true;
    }

//  ----------------------------------------------------
//                 Doesn't accept eth 
//  ----------------------------------------------------
    receive() external payable {
        revert();
    }
}