pragma solidity 0.6.6;

contract InfoBot {

    uint totalUsersHoldingCredits;            // how many users hold credits
    
    mapping(address => userInfo) users;       // user address assigned to personal info sheet

    struct userInfo {
        uint creditBalance;                   // credit balance
        uint encryptedBalance;                // encrypted balance
        uint _initalEncryptedBalance;         // inital encrypted balance deposit for each hack
        uint toTransfer;                      // amount to transfer
        bool holdsCredits;                    // user is/isn't holding credits
        bool isHacking;                       // hacking status
        uint currentHackTime;                 // current hacking time progress
        uint hackCompletionTime;              // hacking completion time
        mapping (address => uint256) allowed; // credits allowed to transfer  // 
    }
}