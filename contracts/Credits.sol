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

	string _name = "Credits";
    string _symbol = "CRDTS";
    uint8 _decimals = 18;
    uint256 initalCreditsSupply;   // supply upon deployment
    uint256 totalCreditsSupply;    // Credits' total supply (can be adjusted)
    uint256 totalCreditsHeld;	   // how many Credits are in custody of users

    constructor() public{            
        initalCreditsSupply = 1500000000000000000000000;    // 1,500,000 inital
    	totalCreditsSupply = initalCreditsSupply;
        totalCreditsHeld = 0;
    	isPaused = true;

    }
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
    function transfer(address _to, uint _value) override external pauseFunction returns (bool success) {
        require(users[msg.sender].creditBalance >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal pauseFunction {
        require(_to != address(0));
        users[_from].creditBalance = users[_from].creditBalance.sub(_value);
        users[_to].creditBalance = users[_to].creditBalance.add(_value);
        emit Transfer(msg.sender, _to, _value);
    }
    
    function approve(address _spender, uint _value) override external pauseFunction returns (bool success) {
        require(_spender != address(0));
    	users[msg.sender].allowance[_spender] = _value;
    	emit Approval(msg.sender, _spender, _value);
    	return true;
    }
    function transferFrom(address _from, address _to, uint _value) override external pauseFunction returns (bool success) {
        require(_value <= users[_from].creditBalance);
        require(_value <= users[_from].allowance[msg.sender]);
        users[_from].allowance[msg.sender] = users[_from].allowance[msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }
    function allowance(address tokenOwner, address spender) override external pauseFunction view returns (uint remaining) {
        return users[tokenOwner].allowance[spender];
    }
    function generateCredits(address tokenOwner, uint _amount) override external onlyOwner returns (bool success) {
        users[tokenOwner].creditBalance = users[tokenOwner].creditBalance.add(_amount);
        totalCreditsSupply = totalCreditsSupply.add(_amount);
        totalCreditsHeld = totalCreditsHeld.add(_amount);
        emit Transfer(address(0), tokenOwner, _amount);
        return true;
    }
    function deleteCredits(uint _amount) override external onlyOwner returns (bool success) {
        require(totalCreditsSupply >= _amount && totalCreditsHeld > _amount, "unable to burn held tokens");
        require(totalCreditsSupply >= totalCreditsHeld, "unable to burn held tokens");
        users[msg.sender].creditBalance = users[msg.sender].creditBalance.sub(_amount);
        totalCreditsSupply = totalCreditsSupply.sub(_amount);
        emit Transfer(msg.sender, address(0), _amount);
        return true;
    }
}
