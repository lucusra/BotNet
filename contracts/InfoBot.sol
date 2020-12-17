pragma solidity 0.6.6;

// ----------------------------------------------------------------------------
//
//                      (c) The BotNet Project 2020
//
// ----------------------------------------------------------------------------

contract InfoBot {
    
    uint256 _enigmaFee;                             // Enigma entrance fee
    uint256 _enigmaBalance;                         // total funds in Enigma
    uint256 totalEnigmaParticipants;                // total enigma participants
    address[] enigmaParticipants;                   // addresses participating in Enigma

    uint256 totalUsersHoldingCredits;               // amount of users holding credits

    mapping(address => userInfo) users;             // user address assigned to personal info sheet

    struct userInfo {
        uint256 creditBalance;                      // credit balance
        uint256 credibyteBalance;                   // users' amount of credibytes, that can be exchanged for credits 
        uint256 encryptedBalance;                   // encrypted balance
        uint256 _initalEncryptedBalance;            // inital encrypted balance deposit for each hack
        uint256 toTransfer;                         // amount to transfer
        bool holdsCredits;                          // user is/isn't holding credits
        bool isHacking;                             // hacking status
        uint256 hackCompletionTime;                 // hacking completion time
        mapping (address => uint256) allowance;     // credits allowed to transfer
        
        
        bool inEnigma;
        uint256 joinedEnigma;
        uint256 leftEnigma;
        // uint timeUntilEnigmaRecipient;           // future implimentation, maybe
        // bool enigmaRecipient;                    // future implimentation, maybe
    }
}
