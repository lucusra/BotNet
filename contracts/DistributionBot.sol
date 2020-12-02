pragma solidity 0.6.6;

import "./Credits.sol";

// ----------------------------------------------------------------------------
//
//                      (c) The BotNet Project 2020
//
// ----------------------------------------------------------------------------

///@dev add decryptEnigmaPortion()

contract DistributionBot is Credits {

    constructor() public  {
        uint enigmaFee = 1000;
        _enigmaFee = enigmaFee;
    }

    function enterEnigma() external pauseFunction returns (uint entranceFee, bool success) {
        require(users[msg.sender].creditBalance >= _enigmaFee, "insufficient funds to enter Enigma");
        require(users[msg.sender].inEnigma == false, "already in Enigma");

        users[msg.sender].creditBalance = users[msg.sender].creditBalance.sub(_enigmaFee);
        users[msg.sender].joinedEnigma = block.timestamp;
        users[msg.sender].leftEnigma = 0;

        users[msg.sender].inEnigma = true;
        enigmaParticipants.push(msg.sender);
        totalEnigmaParticipants = totalEnigmaParticipants.add(1);

        return (_enigmaFee, true);
    }

    function leaveEnigma() external pauseFunction returns (bool success) {
        require(users[msg.sender].inEnigma == true, "unable to leave when you have not joined the Enigma");

        users[msg.sender].inEnigma = false;
        enigmaParticipants.pop();
        totalEnigmaParticipants = totalEnigmaParticipants.add(1);
        users[msg.sender].leftEnigma = now;

        return true;
    }

    function updateFee(uint newFee) external onlyOwner returns (uint updatedFee, bool success) {
        _enigmaFee = newFee;
        return (_enigmaFee, true);
    }

    function viewEnigma() external view returns (uint entranceFee, uint enigmaBalance) {
        return (_enigmaFee, _enigmaBalance);
    }

    function decryptEnigma() external pauseFunction onlyOwner returns (uint totalDecryptedCredits, uint decryptedCreditsPerPerson, uint totalRecipients) {
        require(totalEnigmaParticipants != 0, "no participants in Enigma for distribution");

        uint _creditsPerPerson = (_enigmaBalance.div(enigmaParticipants.length));

            for(uint i = 0; enigmaParticipants.length > i; i++) {
                address n = enigmaParticipants[i];
                users[n].creditBalance = users[n].creditBalance.add(_creditsPerPerson);
            }

        return (_enigmaBalance, _creditsPerPerson, totalEnigmaParticipants);
    }
}