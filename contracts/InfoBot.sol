pragma solidity 0.6.6;

// ----------------------------------------------------------------------------
//
//                      (c) The BotNet Project 2020
//
// ----------------------------------------------------------------------------

contract InfoBot {
    
    uint _enigmaFee;                             // Enigma entrance fee
    uint _enigmaBalance;                         // total funds in Enigma
    uint totalEnigmaParticipants;                // total enigma participants
    address[] enigmaParticipants;                // addresses participating in Enigma

    uint totalUsersHoldingCredits;               // amount of users holding credits

    mapping(address => userInfo) users;          // user address assigned to personal info sheet

    struct userInfo {
        uint creditBalance;                      // credit balance
        uint encryptedBalance;                   // encrypted balance
        uint _initalEncryptedBalance;            // inital encrypted balance deposit for each hack
        uint toTransfer;                         // amount to transfer
        bool holdsCredits;                       // user is/isn't holding credits
        bool isHacking;                          // hacking status
        uint hackCompletionTime;                 // hacking completion time
        mapping (address => uint256) allowed;    // credits allowed to transfer
        
        bool inEnigma;
        uint joinedEnigma;
        uint leftEnigma;
        // uint timeUntilEnigmaRecipient;        // future implimentation, maybe
        // bool enigmaRecipient;                 // future implimentation, maybe
    }
}
