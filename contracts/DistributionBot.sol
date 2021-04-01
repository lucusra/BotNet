//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Credits.sol";
import "./lib/Permissioned.sol";

// ----------------------------------------------------------------------------
//
//                      (c) The BotNet Project 2020
//
// ----------------------------------------------------------------------------

///@dev add decryptEnigmaPortion()

contract DistributionBot is Permissioned {
    using SafeMath for uint256;

    Credits credits;

    /// @dev Enigma entrance fee
    private uint256 _enigmaFee;

    /// @dev Total funds in Enigma
    private uint256 _enigmaBalance;

    /// @dev Total enigma participants
    uint256 totalEnigmaParticipants;

    /// @dev Addresses participating in Enigma
    address[] enigmaParticipants;

    /// @dev Is user in enigma
    bool inEnigma;

    /// @dev Block that user joined Enigma
    mapping(address => uint256[]) joinedEnigma;

    /// @dev Block that user left engima
    mapping(address => uint256[]) leftEnigma;

    event userJoiningEngima(
        address indexed userJoining, 
        uint256 indexed enteranceFee, 
        uint256 indexed joiningTime
    );
    event userLeavingEngima(
        address indexed userLeaving, 
        uint256 indexed leavingTime
    );
    event newEntranceFee(
        uint256 indexed newFee, 
        uint256 indexed timeUpdated
    );
    event enigmaDecryption(
        uint256 indexed totalRecipients, 
        uint256 indexed decryptedCreditsPerPerson
    );

    constructor() {
        if(msg.sender == owner) {
            grantContractAccess(address(this));
        } 
        uint enigmaFee = 1000;
        _enigmaFee = enigmaFee;
    }

    /// @notice allows the caller to enter the Enigma for a fee.
    function enterEnigma() external pauseFunction returns (uint entranceFee, bool success) {
        require(users[msg.sender].creditBalance >= _enigmaFee, "insufficient funds to enter Enigma");
        require(users[msg.sender].inEnigma == false, "already in Enigma");

        credits.transfer(address(credits), _enigmaFee);
        msg.sender.joinedEnigma = block.timestamp;
        msg.sender.leftEnigma = 0;
        msg.sender.inEnigma = true;
        enigmaParticipants.push(msg.sender);
        totalEnigmaParticipants = totalEnigmaParticipants.add(1);

        emit userJoiningEngima(msg.sender, _enigmaFee, block.timestamp);
        return (_enigmaFee, true);
    }

    /// @notice allows the user to leave the Enigma pool.
    function leaveEnigma() external pauseFunction returns (bool success) {
        require(msg.sender.inEnigma == true, "unable to leave when you have not joined the Enigma");

        users[msg.sender].inEnigma = false;
        enigmaParticipants.pop();
        totalEnigmaParticipants = totalEnigmaParticipants.add(1);
        users[msg.sender].leftEnigma = block.timestamp;

        return true;
    }

    /// @notice Allows the owner to update the Enigma enterance fee.
    function updateFee(uint _newFee) external onlyOwner returns (uint updatedFee, bool success) {
        _enigmaFee = _newFee;
        emit newEntranceFee(_newFee, block.timestamp);
        return (_enigmaFee, true);
    }

    /// @notice Allows the user to view the entranaceFee & Enigma's balance.
    function getEntranceFee() external view returns (uint256) {
        return (_enigmaFee);
    }

    function getEnigmaBalance() external view returns (uint256) {
        return (_enigmaBalance);
    }

    function getParticipants() external view returns (uint256, address[]) {
        return (totalEnigmaParticipants, enigmaParticipants[]);
    }

    /// @notice allows owner to decrypt funds within Enigma which then distributes to members of the Enigma equally. 
    function decryptEnigma() external pauseFunction returns (uint256 totalRecipients, uint256 decryptedCreditsPerPerson) {
        require(totalEnigmaParticipants != 0, "no participants in Enigma for distribution");

        uint _creditsPerPerson = (_enigmaBalance.div(enigmaParticipants.length));
            for(uint i = 0; enigmaParticipants.length > i;) {
                address n = enigmaParticipants[i];
                credits.approve(address(this), _creditsPerPerson);
                credits.transferFrom(address(credits), n, _creditsPerPerson);
                i++
            }
            
        emit enigmaDecryption(totalEnigmaParticipants, _creditsPerPerson);
        return (totalEnigmaParticipants, _creditsPerPerson);
    }
}
