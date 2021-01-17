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

// TO DO...
// [ ] ADD PERMISSION MODIFIER W/ "hasAccess" bool variable -> ONLY OBTAINABLE VIA DEPLOYER CONFIRMATION 
// [ ] MAKE APPROVE FUNCTION THAT CONTRACTS WITH PERMISSION CAN ACCESS 

contract Credits is ICredits, Permissioned {
	using SafeMath for uint256;

//  ----------------------------------------------------
//               Variables + Constructor
//  ----------------------------------------------------

	string _name = "Credits";
    string _symbol = "CRDTS";
    uint8 _decimals = 18;                       
    uint256 public initialCreditsSupply = 20000000 * 10**uint(_decimals);         // 20,000,000 credits supply upon deployment
    uint256 private totalCreditsSupply;                                           // Credits' total supply (can be adjusted)
    uint256 public totalCreditsHeld;	                                          // how many Credits are in custody of users
    uint256 public remainingUnheldCredits;                                        // amount of credits that aren't owned
    address public creditsContract;                                              // the address that holds the total supply

    constructor() {    
        isPaused = false;                                                  // contract is unpaused on deployment
        creditsContract = address(this);                                   // creditsContract = this contract address (Credits.sol)    
        users[creditsContract].hasContractAccess = true;                   // is given contract access for contractApprove()
    	totalCreditsSupply = initialCreditsSupply;                         // total credits supply = total inital credits supply
        totalCreditsHeld = 0;                                              // credits held by users = 0
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
    function totalSupply() override external view returns (uint totalSupply_includingDecimals, uint totalSupply_excludingDecimals) {
    	return (totalCreditsSupply, (totalCreditsSupply.div(10**_decimals)));	
    }
    function balanceOf(address tokenOwner) override external view returns (uint creditBalance) {
    	return users[tokenOwner].creditBalance;
    }

//  ----------------------------------------------------
//                User Transfer Functions 
//  ----------------------------------------------------

    function transfer(address _to, uint _amount) override external pauseFunction returns (bool success) {
        // debugging 
        // console.log("Sender creditBalance is %s credits", users[_to].creditBalance);
        // console.log("Trying to send %s credits to %s", _amount, _to);
        // functionality
        require(users[msg.sender].creditBalance >= _amount, "insufficient funds, revert");
        _transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _amount) override external pauseFunction returns (bool success) {
        require(users[_from].creditBalance >= _amount, "from address has insufficient funds, revert");
        require(users[msg.sender].allowance[_from] >= _amount, "insufficient allowance, revert");
        require(users[msg.sender].allowance[_from] <= users[_from].creditBalance);
        users[msg.sender].allowance[_from] = users[msg.sender].allowance[_from].sub(_amount);
        _transfer(_from, _to, _amount);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _amount) private pauseFunction {
        if(_from == creditsContract) {
            users[_from].creditBalance = users[_from].creditBalance.sub(_amount);
            users[_to].creditBalance = users[_to].creditBalance.add(_amount);
            remainingUnheldCredits = users[owner].creditBalance;
            totalCreditsHeld = totalCreditsSupply.add(remainingUnheldCredits);
        } else if (_to == creditsContract){
            users[_from].creditBalance = users[_from].creditBalance.sub(_amount);
            users[_to].creditBalance = users[_to].creditBalance.add(_amount);
            remainingUnheldCredits = users[owner].creditBalance;
            totalCreditsHeld = totalCreditsSupply.sub(remainingUnheldCredits);
        } else {
            users[_from].creditBalance = users[_from].creditBalance.sub(_amount);
            users[_to].creditBalance = users[_to].creditBalance.add(_amount);
        }
        emit Transfer(msg.sender, _to, _amount);
    }

//  ----------------------------------------------------
//               User Approve + Allowance 
//  ----------------------------------------------------

    function contractApprove(address _approver, address _approvee, uint256 _amount) contractAccess external returns (bool success) {
        _approve(_approver, _approvee, _amount);
        return true;
    }

    function approve(address _spender, uint _amount) override external pauseFunction returns (bool success) {
        // require(msg.sender != creditsContract, "ERROR: Unable to set ");
    	_approve(msg.sender, _spender, _amount);
    	return true;
    }

    function _approve(address _owner, address _spender, uint _amount) private {
        users[_owner].allowance[_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function viewAllowance(address tokenOwner, address spender) override external pauseFunction view returns (uint remaining) {
        return users[tokenOwner].allowance[spender];
    }

//  ----------------------------------------------------
//                 Mint + Burn Credits 
//  ----------------------------------------------------

    function generateCredits(uint _amount) override external onlyOwner returns (bool success) {
        users[creditsContract].creditBalance = users[creditsContract].creditBalance.add(_amount);
        totalCreditsSupply = totalCreditsSupply.add(_amount);
        remainingUnheldCredits = users[owner].creditBalance;              
        emit generatedCredits(totalCreditsSupply, creditsContract, _amount);
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
    receive() external payable {
        revert();
    }
}