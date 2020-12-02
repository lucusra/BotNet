pragma solidity 0.6.6;

import "./Credits.sol";

// ----------------------------------------------------------------------------
//
//                      (c) The BotNet Project 2020
//
// ----------------------------------------------------------------------------

contract HackerBot is Credits {

    modifier HackInProgress() {
        require(users[msg.sender].isHacking != true, "HackerBot already hacking, wait for completition or abort current hack");
        _;
    }

    // Encrypted credits & transfer to HackerBot to hack & gain interest (Staking).
    function encrypt_And_Hack(uint encryptAmount) external HackInProgress pauseFunction returns (bool success) {
        require(users[msg.sender].isHacking == false, "HackerBot can only hack one account at a time, wait for completition or abort current hack if you wish to restart");
        require(encryptAmount > 0, "cannot encrypt 0");
        require(users[msg.sender].creditBalance >= encryptAmount, "insufficient credits to encrypt");
        require(users[msg.sender].currentHackTime >= users[msg.sender].hackCompletionTime, "HackerBot progress incomplete, wait for completition or abort current hack if you wish to begin a new hack");
        
        users[msg.sender].isHacking = true;
        users[msg.sender].creditBalance = users[msg.sender].creditBalance.sub(encryptAmount);
        users[msg.sender].currentHackTime == block.timestamp;
        users[msg.sender].hackCompletionTime = users[msg.sender].currentHackTime.add(30 days);

        users[msg.sender].encryptedBalance = users[msg.sender].encryptedBalance.add(encryptAmount);
        users[msg.sender]._initalEncryptedBalance = users[msg.sender]._initalEncryptedBalance.add(encryptAmount);
        return true;
    }
    // User can encrypt new credits to add onto remaining balance and/or decrypt and redeem "x" amount and start a new hack with remaining balance.
    function decryptPortion_And_beginNewHack(uint decryptAmount, uint encryptAmount) external pauseFunction returns (uint decryptedAmount, uint encryptedAmount, bool hasDecryptedCredits, bool hasEncryptedCredits, bool success) {
        require(users[msg.sender].isHacking == true, "not hacking");
        require(users[msg.sender].currentHackTime >= users[msg.sender].hackCompletionTime, "HackerBot progress incomplete, wait for completition or abort current hack if you wish to withdraw");
        require(users[msg.sender].encryptedBalance > decryptAmount, "cannot decrypt all funds, must have funds to begin new hack");
        require(users[msg.sender].creditBalance >= encryptAmount, "insufficient credits to encrypt");

        bool _hasEncryptedCredits = false;
        bool _hasDecryptedCredits = false;

        // resets hacking progress
        users[msg.sender].currentHackTime == block.timestamp;
        users[msg.sender].hackCompletionTime = users[msg.sender].currentHackTime.add(30 days);

        // checks if decryptAmount != 0, if not it redeems "x" encrypted credits
        if (decryptAmount > 0) {
            users[msg.sender].encryptedBalance = users[msg.sender].encryptedBalance.sub(decryptAmount);
            users[msg.sender]._initalEncryptedBalance = users[msg.sender]._initalEncryptedBalance.sub(decryptAmount);
            users[msg.sender].creditBalance = users[msg.sender].creditBalance.add(decryptAmount);
            _hasDecryptedCredits = true;
        } else { _hasDecryptedCredits = false; }

        // checks if encryptAmount !=, if not it encrypts "x" credits
        if(encryptAmount > 0) {
            users[msg.sender].creditBalance = users[msg.sender].creditBalance.sub(encryptAmount);
            users[msg.sender].encryptedBalance = users[msg.sender].encryptedBalance.add(encryptAmount);
            users[msg.sender]._initalEncryptedBalance = users[msg.sender]._initalEncryptedBalance.add(encryptAmount);
            _hasEncryptedCredits = true;
        } else { _hasEncryptedCredits = false; }

        return (decryptAmount, encryptAmount, hasDecryptedCredits, hasEncryptedCredits, true);
    }

    // Withdraw inital encrypted balance & HackerBot hacked funds (Unstake & Withdraw).
    function decryptAll_And_Redeem() external pauseFunction returns (bool success) {
        require(users[msg.sender].isHacking == true, "not hacking");
        require(users[msg.sender].encryptedBalance > 0, "insufficient HackerBot funds available to withdraw");
        require(users[msg.sender].currentHackTime >= users[msg.sender].hackCompletionTime, "HackerBot progress incomplete, wait for completition or abort current hack if you wish to withdraw");
        
        users[msg.sender].toTransfer = ((users[msg.sender].encryptedBalance).add((((users[msg.sender].encryptedBalance).mul(2)).div(100))));
        users[msg.sender].encryptedBalance = users[msg.sender].encryptedBalance = 0;
        users[msg.sender]._initalEncryptedBalance = users[msg.sender]._initalEncryptedBalance = 0;
        users[msg.sender].isHacking == false;

        users[msg.sender].creditBalance = users[msg.sender].creditBalance.add(users[msg.sender].toTransfer);
        users[msg.sender].toTransfer == 0;
        return true;
    }
    // Allows user to restart or cancel current hack
    function abortHack() external pauseFunction returns (bool success) {
        require(users[msg.sender].isHacking == true, "HackerBot currently is not hacking");
        require(users[msg.sender].encryptedBalance > 0, "no funds available in HackerBot");

        users[msg.sender].isHacking == false;
        users[msg.sender].currentHackTime == 0;
        users[msg.sender].hackCompletionTime == 0;

        users[msg.sender].toTransfer = users[msg.sender].encryptedBalance;
        users[msg.sender].encryptedBalance == 0;
        users[msg.sender]._initalEncryptedBalance == 0;
        users[msg.sender].creditBalance = users[msg.sender].creditBalance.add(users[msg.sender].toTransfer);
        users[msg.sender].toTransfer == 0;
        return true;
    }
    // --------[*Needs to be fixed, use a struct!]---------
    function viewHack() external view returns (
        uint initalEncryptedBalance, 
        uint encryptedBalance_afterHack,
        uint profitAfterHack, 
        uint secondsRemaining, 
        uint minutesRemaining, 
        uint hoursRemaining, 
        uint daysRemaining
    ){
            return 
            ( 
                users[msg.sender]._initalEncryptedBalance,
                ((users[msg.sender]._initalEncryptedBalance).add((((users[msg.sender]._initalEncryptedBalance).mul(2)).div(100)))),
                (((users[msg.sender]._initalEncryptedBalance).mul(2)).div(100)),
                ((users[msg.sender].hackCompletionTime).sub(now)), 
                (((users[msg.sender].hackCompletionTime).sub(now)).div(60)), 
                ((((users[msg.sender].hackCompletionTime).sub(now)).div(60)).div(60)), 
                (((((users[msg.sender].hackCompletionTime).sub(now)).div(60)).div(60)).div(24))
            );
    }
}
