pragma solidity 0.6.6;

import "./Permissioned.sol";
import "./CreditsInterface.sol";

contract Credits is CreditsInterface, Permissioned {
	using SafeMath for uint;

	string name = "Credits";
    string symbol = "CRDT";
    uint8 decimals = 18;
    uint256 _initialSupply = 250000000000000000000000000;   // supply upon deployment
    uint256 _totalSupply; 	 
    uint256 _totalSupplyHeld; // users holding supply

    mapping(address => uint256) creditBalances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => mapping (address => bool)) hasAccess;

    constructor() public{
    	_totalSupply = _initialSupply;
        _totalSupplyHeld = _totalSupply;
    	isPaused = true;

    }
    function totalSupply() override external view returns (uint) {
    	return _totalSupply;	
    }
    function balanceOf(address tokenOwner) override external view returns (uint balance) {
    	return creditBalances[tokenOwner];
    }
    function transfer(address to, uint tokens) override external pauseFunction returns (bool success) {
        require(to != msg.sender, "unable to transfer credits to yourself");
    	creditBalances[msg.sender] = creditBalances[msg.sender].sub(tokens);
    	creditBalances[to] = creditBalances[to].add(tokens);
    	emit Transfer(msg.sender, to, tokens);
    	return true;
    }
    function approve(address spender, uint tokens) override external pauseFunction returns (bool success) {
    	allowed[msg.sender][spender] = tokens;
    	emit Approval(msg.sender, spender, tokens);
    	return true;
    }
    function transferFrom(address from, address to, uint tokens) override external pauseFunction returns (bool success) {
        require(from != msg.sender && to != msg.sender, "unable to transfer to yourself");
        creditBalances[from] = creditBalances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        creditBalances[to] = creditBalances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) override external pauseFunction view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    function mint(address tokenOwner, uint tokens) override external onlyOwner returns (bool success) {
        creditBalances[tokenOwner] = creditBalances[tokenOwner].add(tokens);
        _totalSupply = _totalSupply.add(tokens);
        emit Transfer(address(0), tokenOwner, tokens);
        return true;
    }
    function burn(uint tokens) override external onlyOwner returns (bool success) {
        creditBalances[msg.sender] = creditBalances[msg.sender].sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
        emit Transfer(msg.sender, address(0), tokens);
        return true;
    }
}
