pragma solidity 0.6.6;

import "./Permissioned.sol";
import "./CreditsInterface.sol";
import "./InfoBot.sol";

// ----------------------------------------------------------------------------
//
//                      (c) The BotNet Project 2020
//
// ----------------------------------------------------------------------------

contract Credits is CreditsInterface, Permissioned, InfoBot {
	using SafeMath for uint;

	string name = "Credits";
    string symbol = "CRDT";
    uint8 decimals = 18;
    uint256 _initialSupply = 250000000000000000000000000;   // supply upon deployment
    uint256 _totalSupply; 	 
    uint256 _totalSupplyHeld; // users holding supply

    constructor() public{
    	_totalSupply = _initialSupply;
        _totalSupplyHeld = _totalSupply;
    	isPaused = true;

    }
    function totalSupply() override external view returns (uint) {
    	return _totalSupply;	
    }
    function balanceOf(address tokenOwner) override external view returns (uint balance) {
    	return users[tokenOwner].creditBalance;
    }
    function transfer(address to, uint tokens) override external pauseFunction returns (bool success) {
        require(to != msg.sender, "unable to transfer credits to yourself");
    	users[msg.sender].creditBalance = users[msg.sender].creditBalance.sub(tokens);
    	users[to].creditBalance = users[to].creditBalance.add(tokens);
    	emit Transfer(msg.sender, to, tokens);
    	return true;
    }
    function approve(address spender, uint tokens) override external pauseFunction returns (bool success) {
        require(spender != msg.sender, "unable to approve tokens to yourself");
    	users[msg.sender].allowed[spender] = tokens;
    	emit Approval(msg.sender, spender, tokens);
    	return true;
    }
    function transferFrom(address from, address to, uint tokens) override external pauseFunction returns (bool success) {
        require(from != msg.sender && to != msg.sender, "unable to transfer to yourself");
        users[from].creditBalance = users[from].creditBalance.sub(tokens);
        users[from].allowed[msg.sender] = users[from].allowed[msg.sender].sub(tokens);
        users[to].creditBalance = users[to].creditBalance.add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) override external pauseFunction view returns (uint remaining) {
        return users[tokenOwner].allowed[spender];
    }
    function mint(address tokenOwner, uint tokens) override external onlyOwner returns (bool success) {
        users[tokenOwner].creditBalance = users[tokenOwner].creditBalance.add(tokens);
        _totalSupply = _totalSupply.add(tokens);
        emit Transfer(address(0), tokenOwner, tokens);
        return true;
    }
    function burn(uint tokens) override external onlyOwner returns (bool success) {
        users[msg.sender].creditBalance = users[msg.sender].creditBalance.sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
        emit Transfer(msg.sender, address(0), tokens);
        return true;
    }
}
