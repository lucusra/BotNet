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
        users[msg.sender].creditBalance = users[msg.sender].creditBalance.add((msg.value.mul(_conversionRate)).div(1000000000000000000));
        if (users[msg.sender].creditBalance != 0 && users[msg.sender].holdsCredits == false) {
            users[msg.sender].holdsCredits = true;
            totalUsersHoldingCredits = totalUsersHoldingCredits.add(1);
        }
        return true;
    }
    function exchange_Credits_To_Eth(uint creditsAmount) public pauseFunction returns(bool success) {
        require(users[msg.sender].creditBalance != 0, "balance is empty, unable to withdraw");
        require(users[msg.sender].creditBalance >= creditsAmount, "insufficient funds to withdraw");
        require(creditsAmount != 0, "unable to withdraw 0");
        _totalSupply = _totalSupply.sub(creditsAmount);
        _totalSupplyHeld = _totalSupplyHeld.sub(creditsAmount);
        users[msg.sender].creditBalance = users[msg.sender].creditBalance.sub(creditsAmount);
        creditsAmount = creditsAmount.mul(1000000000000000000);
        msg.sender.transfer(creditsAmount.div(_conversionRate));
        if (users[msg.sender].creditBalance == 0 && users[msg.sender].holdsCredits == true) {
            users[msg.sender].holdsCredits = false;
            totalUsersHoldingCredits = totalUsersHoldingCredits.sub(1);
        }
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
