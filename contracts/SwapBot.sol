pragma solidity 0.6.6;

import "./Credits.sol";

// ----------------------------------------------------------------------------
//
//                      (c) The BotNet Project 2020
//
// ----------------------------------------------------------------------------

contract SwapBot is Credits {
    uint _conversionRate;

    function exchange_Eth_To_Credits() public payable pauseFunction returns(bool success) {
        require(msg.value > 0 wei, "balance is empty, unable to deposit");
        require(msg.sender.balance > 0 wei, "insufficient enough funds");
        _totalSupplyHeld = _totalSupplyHeld.add((msg.value.mul(_conversionRate)).div(1000000000000000000));
        _totalSupply = _totalSupply.add((msg.value.mul(_conversionRate)).div(1000000000000000000));
        creditBalances[msg.sender] = creditBalances[msg.sender].add((msg.value.mul(_conversionRate)).div(1000000000000000000));
        return true;
    }
    function exchange_Credits_To_Eth(uint creditsAmount) public pauseFunction returns(bool success) {
        require(creditBalances[msg.sender] != 0, "balance is empty, unable to withdraw");
        require(creditBalances[msg.sender] >= creditsAmount, "insufficient funds to withdraw");
        require(creditsAmount != 0, "unable to withdraw 0");
        _totalSupply = _totalSupply.sub(creditsAmount);
        _totalSupplyHeld = _totalSupplyHeld.sub(creditsAmount);
        creditBalances[msg.sender] = creditBalances[msg.sender].sub(creditsAmount);
        creditsAmount = creditsAmount.mul(1000000000000000000);
        msg.sender.transfer(creditsAmount.div(_conversionRate));
        return true;
    }
    function setConversionRate(uint newRate) public onlyOwner returns(uint rate) {
        require(_conversionRate != newRate, "unable to change to the same rate");
        _conversionRate = newRate;
        return _conversionRate;
    } 
    function conversionRate() public view returns(uint rate) {
        return _conversionRate;
    }
}
