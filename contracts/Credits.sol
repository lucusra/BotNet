pragma solidity 0.6.6;

import "./Permissioned.sol";
import "./CreditsInterface.sol";
import "./InfoBot.sol";

// ----------------------------------------------------------------------------
//
//                      (c) The BotNet Project 2020
//
// ----------------------------------------------------------------------------

// @upgrade - need to make sure that the supply

contract Credits is CreditsInterface, Permissioned, InfoBot {
	using SafeMath for uint;

//  ----------------------------------------------------
//               Variables + Constructor
//  ----------------------------------------------------

	string _name = "Credits";
    string _symbol = "CRDTS";
    uint8 _decimals = 18;                       
    uint256 initalCreditsSupply;                // supply upon deployment
    uint256 totalCreditsSupply;                 // Credits' total supply (can be adjusted)
    uint256 public totalCreditsHeld;	        // how many Credits are in custody of users
    uint256 public remainingUnheldCredits;      // amount of credits that aren't owned

    constructor() public{            
        initalCreditsSupply = 1500000 * 10**uint(_decimals);               // 1,500,000 inital credits supply
    	totalCreditsSupply = initalCreditsSupply;                          // total credits supply = total inital credits supply
        totalCreditsHeld = 0;                                              // credits held by users = 0
    	isPaused = false;                                                  // contract is unpaused on deployment
        users[owner].creditBalance = totalCreditsSupply;                   // owner owns total supply
        remainingUnheldCredits = users[owner].creditBalance;               // amount of credits that aren't owned = total supply
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
    function balanceOf(address tokenOwner) override external view returns (uint balance) {
    	return users[tokenOwner].creditBalance;
    }

//  ----------------------------------------------------
//                 Transfer Functions 
//  ----------------------------------------------------

    function transfer(address _to, uint _value) override external pauseFunction returns (bool success) {
        require(users[msg.sender].creditBalance >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) override external pauseFunction returns (bool success) {
        require(_value <= users[_from].creditBalance);
        require(_value <= users[_from].allowance[msg.sender]);
        users[_from].allowance[msg.sender] = users[_from].allowance[msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal pauseFunction {
        require(_to != address(0));
        if(_from == owner) {
            users[_from].creditBalance = users[_from].creditBalance.sub(_value);
            users[_to].creditBalance = users[_to].creditBalance.add(_value);
            totalCreditsHeld = totalCreditsHeld.add(_value);
            remainingUnheldCredits = users[owner].creditBalance; 
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
        require(_spender != address(0));
    	users[msg.sender].allowance[_spender] = _value;
    	emit Approval(msg.sender, _spender, _value);
    	return true;
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
        require(totalCreditsSupply >= _amount && totalCreditsHeld > _amount, "unable to burn held tokens");
        require(totalCreditsSupply >= totalCreditsHeld, "unable to burn held tokens");
        users[owner].creditBalance = users[owner].creditBalance.sub(_amount);
        totalCreditsSupply = totalCreditsSupply.sub(_amount);
        remainingUnheldCredits = users[owner].creditBalance;              
        emit deletedCredits(totalCreditsSupply, _amount);
        return true;
    }
}
