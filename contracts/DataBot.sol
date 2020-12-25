//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

// ----------------------------------------------------------------------------
//
//                      (c) The BotNet Project 2020
//
// ----------------------------------------------------------------------------

contract DataBot {

    uint256 totalUsersHoldingCredits;               // amount of users holding credits
    mapping(address => userData) users;             // user address assigned to personal info sheet

    // Enigma Data
    uint256 _enigmaFee;                             // Enigma entrance fee
    uint256 _enigmaBalance;                         // total funds in Enigma
    uint256 totalEnigmaParticipants;                // total enigma participants
    address[] enigmaParticipants;                   // addresses participating in Enigma

    struct userData {
        // --------Ownership---------
        bool isOwner;                               // isOwner or not
        bool isCoOwner;                             // isCoOwner or not

        // ---------General----------
        uint256 creditBalance;                      // credit balance
        uint256 toTransfer;                         // amount to transfer
        bool holdsCredits;                          // user is/isn't holding credits
        mapping (address => uint256) allowance;     // credits allowed to transfer

        // ------------ITO------------
        uint256 credibyteBalance;                   // users' amount of credibytes, that can be exchanged for credits 
        uint256 timeUntilNextRedemption;            // user's amount of time until next redemption period after first redemption
        uint256 redemptionCounter;                  // the amount of times the user has redeemed 
        uint256 remainingTimeUntilNextConversion;
        bool fullyConverted;                        // whether the user has converted all
        bool hasParticipatedInITO;

        // ----------Staking----------
        uint256 _initalEncryptedBalance;            // inital encrypted balance deposit for each hack
        uint256 encryptedBalance;                   // encrypted balance
        bool isHacking;                             // hacking status
        uint256 hackCompletionTime;                 // hacking completion time

        // ----------Enigma----------
        bool inEnigma;                              // is in the enigma
        uint256 joinedEnigma;                       // block of joining enigma
        uint256 leftEnigma;                         // block of leaving engima
    }
}
