pragma solidity 0.6.6;

// ----------------------------------------------------------------------------
//
//                      (c) The BotNet Project 2020
//
// ----------------------------------------------------------------------------

contract DataBot {
    
    uint256 totalUsersHoldingCredits;               // amount of users holding credits
    mapping(address => userData) users;             // user address assigned to personal info sheet

    // Enigma Data
    uint256 _enigmaFee;                         // Enigma entrance fee
    uint256 _enigmaBalance;                     // total funds in Enigma
    uint256 totalEnigmaParticipants;            // total enigma participants
    address[] enigmaParticipants;               // addresses participating in Enigma

    struct userData {
        // ---------General----------
        uint256 creditBalance;                      // credit balance
        uint256 toTransfer;                         // amount to transfer
        bool holdsCredits;                          // user is/isn't holding credits
        mapping (address => uint256) allowance;     // credits allowed to transfer
        // ------------ITO------------
        uint256 credibyteBalance;                   // users' amount of credibytes, that can be exchanged for credits 
        // ----------Staking----------
        uint256 _initalEncryptedBalance;            // inital encrypted balance deposit for each hack
        uint256 encryptedBalance;                   // encrypted balance
        bool isHacking;                             // hacking status
        uint256 hackCompletionTime;                 // hacking completion time
        // ----------Enigma----------
        bool inEnigma;
        uint256 joinedEnigma;
        uint256 leftEnigma;
    }
}