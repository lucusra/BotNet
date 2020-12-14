pragma solidity 0.6.6;

import "./Credits.sol";

// ----------------------------------------------------------------------------
//
//                      (c) The BotNet Project 2020
//
// ----------------------------------------------------------------------------

///@dev add decryptEnigmaPortion()

contract DistributionBot is Credits {
    Credits public credits;

    constructor() public  {
        uint enigmaFee = 1000;
        _enigmaFee = enigmaFee;
    }

    /// @notice allows the caller to enter the Enigma for a fee.
    /// @return entranceFee                 : the fee price required to enter the Enigma pool.
    /// @return success                      : whether or not the transaction to leave was a success
    function enterEnigma() external pauseFunction returns (uint entranceFee, bool success) {
        require(users[msg.sender].creditBalance >= _enigmaFee, "insufficient funds to enter Enigma");
        require(users[msg.sender].inEnigma == false, "already in Enigma");
        credits.transfer(owner, _enigmaFee);
        users[msg.sender].joinedEnigma = block.timestamp;
        users[msg.sender].leftEnigma = 0;
        users[msg.sender].inEnigma = true;
        enigmaParticipants.push(msg.sender);
        totalEnigmaParticipants = totalEnigmaParticipants.add(1);
        return (_enigmaFee, true);
    }

    /// @notice allows the user to leave the Enigma pool.
    /// @return success                      : whether or not the transaction to leave was a success
    function leaveEnigma() external pauseFunction returns (bool success) {
        require(users[msg.sender].inEnigma == true, "unable to leave when you have not joined the Enigma");
        users[msg.sender].inEnigma = false;
        enigmaParticipants.pop();
        totalEnigmaParticipants = totalEnigmaParticipants.add(1);
        users[msg.sender].leftEnigma = now;
        return true;
    }

    /// @notice allows the owner to update the Enigma enterance fee.
    /// @param newFee                        : the updated fee for entering the Enigma.
    /// @return updatedFee                   : returns the new fee, set by the owner.
    /// @return success                      : whether or not the transaction to leave was a success
    function updateFee(uint newFee) external onlyOwner returns (uint updatedFee, bool success) {
        _enigmaFee = newFee;
        return (_enigmaFee, true);
    }

    /// @notice allows the user to view the entranaceFee & Enigma's balance.
    /// @return entranceFee                 : the fee price required to enter the Enigma pool.
    /// @return enigmaBalance               : the total amount of Credits stored in the Enigma.
    function viewEnigma() external view returns (uint entranceFee, uint enigmaBalance) {
        return (_enigmaFee, _enigmaBalance);
    }

    /// @notice allows owner to decrypt funds within Enigma which then distributes to members of the Enigma equally. 
    /// @dev potentially making the users able to call this function.
    /// @return decryptedCreditsPerPerson   : the share each member gets (calculated via: total amount of Credits divided by the amount of Engima members). 
    /// @return totalRecipients             : the total amount of Engima share recipients.
    function decryptEnigma() external pauseFunction onlyOwner returns (uint decryptedCreditsPerPerson, uint totalRecipients) {
        require(totalEnigmaParticipants != 0, "no participants in Enigma for distribution");
        uint _creditsPerPerson = (_enigmaBalance.div(enigmaParticipants.length));
            for(uint i = 0; enigmaParticipants.length > i; i++) {
                address n = enigmaParticipants[i];
                credits.transferFrom(owner, n, _creditsPerPerson);
            }
        return ( _creditsPerPerson, totalEnigmaParticipants);
    }
}
