//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

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

    // Credits' total supply (can be adjusted)
    uint256 private _currentTotalSupply;

    // the amount of credits that can be generated
    uint256 private _totalSupplyCap;

    // User's Credit balance
    mapping (address => uint256) creditBalance;

    // An amount of Credits the assignee is allowed to use from the assigner 
    mapping(address => mapping(address => uint256)) allowance;

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
    function balanceOf(address tokenOwner) override external view returns (uint256 creditBalance) {
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
            msg.sender.allowance[from] >= _amount, 
            "insufficient allowance, revert"
        );
        msg.sender.allowance[_from] = msg.sender.allowance[from].sub(amount);
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
//                 Mint + Melt Credits 
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
//                 Doesn't accept eth 
//  ----------------------------------------------------
    
    // revert any eth txs to this contract
    receive() external payable {
        revert();
    }
}
