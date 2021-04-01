//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Credits.sol";

// ----------------------------------------------------------------------------
//
//                      (c) The BotNet Project 2020
//
// ----------------------------------------------------------------------------

// TO DO...
// [ ] Add liquidty pools from uniswap & integrate uniswap

contract HackerBot is Credits {
    using SafeMath for uint256;

    // Inital encrypted balance deposit for each hack
    mapping(address => uint256) _initalEncryptedBalance;

    // User's encrypted balance
    mapping(address => uint256) encryptedBalance;

    // Whether user is Hacking (Staking) or not
    mapping(address => bool) isHacking;

    // When the Hack is complete
    mapping(address => uint256) hackCompletionTime;

    event hackCommencement (address indexed user, uint indexed encryptedAmount, uint indexed hackCompletitionTime);
    event hackRedeption (address indexed user, bool indexed hackCompletion, uint indexed timeOfRedeption);
    event hackCancelation (address indexed user, bool indexed isHacking, uint indexed timeOfCancelation);

    /// @dev HackInProgress is used instead of typing the same code over again.
    modifier HackInProgress() {
        require(msg.sender.isHacking == false, "Hack already in progress! : unable to alter hack once commenced - must cancel to change");
        _;
    }

    /// @notice Encrypt credits & transfer to HackerBot to hack & gain interest (Staking).
    function encrypt_And_Hack(uint encryptAmount) external HackInProgress pauseFunction returns (bool success) {
        require(encryptAmount != 0, "cannot encrypt 0");
        require(msg.sender.creditBalance >= encryptAmount, "insufficient credits to encrypt");
        require(block.timestamp >= msg.sender.hackCompletionTime, "HackerBot progress incomplete, wait for completition or abort current hack if you wish to begin a new hack");
        
        msg.sender.isHacking = true;
        msg.sender.creditBalance = msg.sender.creditBalance.sub(encryptAmount);

        msg.sender.hackCompletionTime = block.timestamp.add(30 days);

        msg.sender.encryptedBalance = msg.sender.encryptedBalance.add(encryptAmount);
        msg.sender._initalEncryptedBalance = msg.sender._initalEncryptedBalance.add(encryptAmount);

        emit hackCommencement(msg.sender, encryptAmount, msg.sender.hackCompletionTime);
        return true;
    }
    /// @notice User can encrypt new credits to add onto remaining balance and/or decrypt and redeem "x" amount and start a new hack with remaining balance.
    function decryptPortion_And_beginNewHack(uint decryptAmount, uint encryptAmount) external pauseFunction returns (uint decryptedAmount, uint encryptedAmount, bool hasDecryptedCredits, bool hasEncryptedCredits, bool success) {
        require(msg.sender.isHacking == true, "unable to alter hack once commenced - seek to cancel current hack");
        require(block.timestamp >= msg.sender.hackCompletionTime, "HackerBot progress incomplete, wait for completition or abort current hack if you wish to withdraw");
        require(msg.sender.encryptedBalance > decryptAmount, "cannot decrypt all funds, must have funds to begin new hack");
        require(msg.sender.creditBalance >= encryptAmount, "insufficient credits to encrypt");

        bool _hasEncryptedCredits = false;
        bool _hasDecryptedCredits = false;

        // resets hacking progress.
        msg.sender.hackCompletionTime = block.timestamp.add(30 days);

        // checks if decryptAmount != 0, if not it redeems "x" encrypted credits.
        if (decryptAmount > 0) {
            msg.sender.encryptedBalance = msg.sender.encryptedBalance.sub(decryptAmount);
            msg.sender._initalEncryptedBalance = msg.sender._initalEncryptedBalance.sub(decryptAmount);
            msg.sender.creditBalance = msg.sender.creditBalance.add(decryptAmount);
            _hasDecryptedCredits = true;
        } else { _hasDecryptedCredits = false; }

        // checks if encryptAmount !=, if not it encrypts "x" credits.
        if(encryptAmount > 0) {
            msg.sender.isHacking = true;
            msg.sender.creditBalance = msg.sender.creditBalance.sub(encryptAmount);
            msg.sender.encryptedBalance = msg.sender.encryptedBalance.add(encryptAmount);
            msg.sender._initalEncryptedBalance = msg.sender._initalEncryptedBalance.add(encryptAmount);
            _hasEncryptedCredits = true;
            emit hackCommencement(msg.sender, msg.sender.encryptedBalance, msg.sender.hackCompletionTime);
        } else { 
            msg.sender.isHacking = false;
            _hasEncryptedCredits = false;  
               }

        return (decryptAmount, encryptAmount, hasDecryptedCredits, hasEncryptedCredits, true);
    }

    /// @notice Withdraw inital encrypted balance & HackerBot hacked funds (Unstake & Withdraw).
    function decryptAll_And_Redeem() external pauseFunction returns (bool success) {
        require(msg.sender.isHacking == true, "not hacking");
        require(msg.sender.encryptedBalance > 0, "insufficient HackerBot funds available to withdraw");
        require(block.timestamp >= msg.sender.hackCompletionTime, "HackerBot progress incomplete, wait for completition or abort current hack if you wish to withdraw");
        
        msg.sender.isHacking = false;
        msg.sender.toTransfer = ((msg.sender.encryptedBalance).add((((msg.sender.encryptedBalance).mul(2)).div(100))));
        msg.sender.encryptedBalance = msg.sender.encryptedBalance = 0;
        msg.sender._initalEncryptedBalance = msg.sender._initalEncryptedBalance = 0;

        msg.sender.creditBalance = msg.sender.creditBalance.add(msg.sender.toTransfer);
        msg.sender.toTransfer = 0;

        emit hackRedeption(msg.sender, true, block.timestamp);
        return true;
    }
    /// @notice Allows user to restart or cancel current hack.
    function cancelHack() external pauseFunction returns (bool success) {
        require(msg.sender.isHacking == true, "HackerBot currently is not hacking");
        require(msg.sender.encryptedBalance > 0, "no funds available in HackerBot");

        msg.sender.isHacking = false;
        msg.sender.toTransfer = msg.sender.encryptedBalance;
        msg.sender.encryptedBalance = 0;
        msg.sender._initalEncryptedBalance = 0;
        msg.sender.hackCompletionTime = 0;
        msg.sender.creditBalance = msg.sender.creditBalance.add(msg.sender.toTransfer);
        msg.sender.toTransfer = 0;

        emit hackCancelation(msg.sender, msg.sender.isHacking, block.timestamp);
        return true;
    }
    /// @notice Allows the user to view their current hack.
    function viewHack() external view returns (
        bool currentlyHacking,
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
                msg.sender.isHacking,
                msg.sender._initalEncryptedBalance,
                ((msg.sender._initalEncryptedBalance).add((((msg.sender._initalEncryptedBalance).mul(2)).div(100)))),
                (((msg.sender._initalEncryptedBalance).mul(2)).div(100)),
                ((msg.sender.hackCompletionTime).sub(block.timestamp)), 
                (((msg.sender.hackCompletionTime).sub(block.timestamp)).div(60)), 
                ((((msg.sender.hackCompletionTime).sub(block.timestamp)).div(60)).div(60)), 
                (((((msg.sender.hackCompletionTime).sub(block.timestamp)).div(60)).div(60)).div(24))
            );
    }
}
