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

    event hackCommencement (address indexed user, uint indexed encryptedAmount, uint indexed hackCompletitionTime);
    event hackRedeption (address indexed user, bool indexed hackCompletion, uint indexed timeOfRedeption);
    event hackCancelation (address indexed user, bool indexed isHacking, uint indexed timeOfCancelation);

    /// @dev HackInProgress is used instead of typing the same code over again.
    modifier HackInProgress() {
        require(users[msg.sender].isHacking == false, "Hack already in progress! : unable to alter hack once commenced - must cancel to change");
        _;
    }

    /// @notice Encrypt credits & transfer to HackerBot to hack & gain interest (Staking).
    /// @param encryptAmount          : is the amount of Credits to commence hacking with.
    function encrypt_And_Hack(uint encryptAmount) external HackInProgress pauseFunction returns (bool success) {
        require(encryptAmount != 0, "cannot encrypt 0");
        require(users[msg.sender].creditBalance >= encryptAmount, "insufficient credits to encrypt");
        require(block.timestamp >= users[msg.sender].hackCompletionTime, "HackerBot progress incomplete, wait for completition or abort current hack if you wish to begin a new hack");
        
        users[msg.sender].isHacking = true;
        users[msg.sender].creditBalance = users[msg.sender].creditBalance.sub(encryptAmount);

        users[msg.sender].hackCompletionTime = block.timestamp.add(30 days);

        users[msg.sender].encryptedBalance = users[msg.sender].encryptedBalance.add(encryptAmount);
        users[msg.sender]._initalEncryptedBalance = users[msg.sender]._initalEncryptedBalance.add(encryptAmount);

        emit hackCommencement(msg.sender, encryptAmount, users[msg.sender].hackCompletionTime);
        return true;
    }
    /// @notice User can encrypt new credits to add onto remaining balance and/or decrypt and redeem "x" amount and start a new hack with remaining balance.
    /// @param decryptAmount         : is the amount to withdraw/redeem.
    /// @param encryptAmount         : is the amount to deposit/hack with.
    /// @return decryptedAmount      : returns how many Credits were redeemed.
    /// @return encryptedAmount      : returns how many Credits were deposited.
    /// @return hasDecryptedCredits  : returns whether the user has redeemed any Credits.
    /// @return hasEncryptedCredits  : returns whether the user has deposited any Credits.
    /// @return success              : returns whether the transaction was a success or not.
    function decryptPortion_And_beginNewHack(uint decryptAmount, uint encryptAmount) external pauseFunction returns (uint decryptedAmount, uint encryptedAmount, bool hasDecryptedCredits, bool hasEncryptedCredits, bool success) {
        require(users[msg.sender].isHacking == true, "unable to alter hack once commenced - seek to cancel current hack");
        require(block.timestamp >= users[msg.sender].hackCompletionTime, "HackerBot progress incomplete, wait for completition or abort current hack if you wish to withdraw");
        require(users[msg.sender].encryptedBalance > decryptAmount, "cannot decrypt all funds, must have funds to begin new hack");
        require(users[msg.sender].creditBalance >= encryptAmount, "insufficient credits to encrypt");

        bool _hasEncryptedCredits = false;
        bool _hasDecryptedCredits = false;

        // resets hacking progress.
        users[msg.sender].hackCompletionTime = block.timestamp.add(30 days);

        // checks if decryptAmount != 0, if not it redeems "x" encrypted credits.
        if (decryptAmount > 0) {
            users[msg.sender].encryptedBalance = users[msg.sender].encryptedBalance.sub(decryptAmount);
            users[msg.sender]._initalEncryptedBalance = users[msg.sender]._initalEncryptedBalance.sub(decryptAmount);
            users[msg.sender].creditBalance = users[msg.sender].creditBalance.add(decryptAmount);
            _hasDecryptedCredits = true;
        } else { _hasDecryptedCredits = false; }

        // checks if encryptAmount !=, if not it encrypts "x" credits.
        if(encryptAmount > 0) {
            users[msg.sender].isHacking = true;
            users[msg.sender].creditBalance = users[msg.sender].creditBalance.sub(encryptAmount);
            users[msg.sender].encryptedBalance = users[msg.sender].encryptedBalance.add(encryptAmount);
            users[msg.sender]._initalEncryptedBalance = users[msg.sender]._initalEncryptedBalance.add(encryptAmount);
            _hasEncryptedCredits = true;
            emit hackCommencement(msg.sender, users[msg.sender].encryptedBalance, users[msg.sender].hackCompletionTime);
        } else { 
            users[msg.sender].isHacking = false;
            _hasEncryptedCredits = false;  
               }

        return (decryptAmount, encryptAmount, hasDecryptedCredits, hasEncryptedCredits, true);
    }

    /// @notice Withdraw inital encrypted balance & HackerBot hacked funds (Unstake & Withdraw).
    /// @return success              : returns whether the transaction was a success or not.
    function decryptAll_And_Redeem() external pauseFunction returns (bool success) {
        require(users[msg.sender].isHacking == true, "not hacking");
        require(users[msg.sender].encryptedBalance > 0, "insufficient HackerBot funds available to withdraw");
        require(block.timestamp >= users[msg.sender].hackCompletionTime, "HackerBot progress incomplete, wait for completition or abort current hack if you wish to withdraw");
        
        users[msg.sender].isHacking = false;
        users[msg.sender].toTransfer = ((users[msg.sender].encryptedBalance).add((((users[msg.sender].encryptedBalance).mul(2)).div(100))));
        users[msg.sender].encryptedBalance = users[msg.sender].encryptedBalance = 0;
        users[msg.sender]._initalEncryptedBalance = users[msg.sender]._initalEncryptedBalance = 0;

        users[msg.sender].creditBalance = users[msg.sender].creditBalance.add(users[msg.sender].toTransfer);
        users[msg.sender].toTransfer = 0;

        emit hackRedeption(msg.sender, true, block.timestamp);
        return true;
    }
    /// @notice Allows user to restart or cancel current hack.
    /// @return success              : returns whether the transaction was a success or not.
    function cancelHack() external pauseFunction returns (bool success) {
        require(users[msg.sender].isHacking == true, "HackerBot currently is not hacking");
        require(users[msg.sender].encryptedBalance > 0, "no funds available in HackerBot");

        users[msg.sender].isHacking = false;
        users[msg.sender].toTransfer = users[msg.sender].encryptedBalance;
        users[msg.sender].encryptedBalance = 0;
        users[msg.sender]._initalEncryptedBalance = 0;
        users[msg.sender].hackCompletionTime = 0;
        users[msg.sender].creditBalance = users[msg.sender].creditBalance.add(users[msg.sender].toTransfer);
        users[msg.sender].toTransfer = 0;

        emit hackCancelation(msg.sender, users[msg.sender].isHacking, block.timestamp);
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
                users[msg.sender].isHacking,
                users[msg.sender]._initalEncryptedBalance,
                ((users[msg.sender]._initalEncryptedBalance).add((((users[msg.sender]._initalEncryptedBalance).mul(2)).div(100)))),
                (((users[msg.sender]._initalEncryptedBalance).mul(2)).div(100)),
                ((users[msg.sender].hackCompletionTime).sub(block.timestamp)), 
                (((users[msg.sender].hackCompletionTime).sub(block.timestamp)).div(60)), 
                ((((users[msg.sender].hackCompletionTime).sub(block.timestamp)).div(60)).div(60)), 
                (((((users[msg.sender].hackCompletionTime).sub(block.timestamp)).div(60)).div(60)).div(24))
            );
    }
}
