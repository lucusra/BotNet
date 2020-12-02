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

	string name = "Credits";
    string symbol = "CRDT";
    uint8 decimals = 18;
    uint256 initalCreditsSupply = 250000000000000000000000000;   // supply upon deployment
    uint256 totalCreditsSupply;
    uint256 totalCreditsHeld;	 

    constructor() public{
    	totalCreditsSupply = initalCreditsSupply;
        totalCreditsHeld = 0;
    	isPaused = true;

    }
    function totalSupply() override external view returns (uint) {
    	return totalCreditsSupply;	
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
    function generateCredits(address tokenOwner, uint tokens) override external onlyOwner returns (bool success) {
        users[tokenOwner].creditBalance = users[tokenOwner].creditBalance.add(tokens);
        totalCreditsSupply = totalCreditsSupply.add(tokens);
        totalCreditsHeld = totalCreditsHeld.add(tokens);
        emit Transfer(address(0), tokenOwner, tokens);
        return true;
    }
    function deleteCredits(uint tokens) override external onlyOwner returns (bool success) {
        require(totalCreditsSupply >= tokens && totalCreditsHeld > tokens, "unable to burn held tokens");
        require(totalCreditsSupply >= totalCreditsHeld, "unable to burn held tokens");
        users[msg.sender].creditBalance = users[msg.sender].creditBalance.sub(tokens);
        totalCreditsSupply = totalCreditsSupply.sub(tokens);
        emit Transfer(msg.sender, address(0), tokens);
        return true;
    }
}
