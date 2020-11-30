pragma solidity 0.6.6;

import "./Credits.sol";

contract HackerBot is Credits {

    mapping(address => uint) timeOfHack;
    mapping(address => uint) timeToFinishHack;
    mapping(address => bool) isHacking;
    mapping(address => uint) toTransfer;
    mapping(address => uint) encryptedBalance;
    mapping(address => uint) _initalEncryptedBalance;

    modifier HackInProgress() {
        require(isHacking[msg.sender] != true, "HackerBot already hacking, wait for completition or abort current hack");
        _;
    }

    // Encrypted credits & transfer to HackerBot to hack & gain interest (Staking)
    function encrypt_And_Hack(uint encryptAmount) external HackInProgress pauseFunction returns (bool success) {
        require(isHacking[msg.sender] == false, "HackerBot can only hack one account at a time, wait for completition or abort current hack if you wish to restart");
        require(creditBalances[msg.sender] != 0, "no credits to encrypt");
        
        isHacking[msg.sender] = true;
        creditBalances[msg.sender] = creditBalances[msg.sender].sub(encryptAmount);
        timeOfHack[msg.sender] == block.timestamp;
        timeToFinishHack[msg.sender] = timeOfHack[msg.sender].add(30 days);

        encryptedBalance[msg.sender] = encryptedBalance[msg.sender].add(encryptAmount);
        _initalEncryptedBalance[msg.sender] = _initalEncryptedBalance[msg.sender].add(encryptAmount);
        return true;
    }
    // Withdraw inital encrypted balance & HackerBot hacked funds (Unstake & Withdraw)
    function decrypt_And_Redeem() external pauseFunction returns (bool success) {
        require(isHacking[msg.sender] == false, "HackerBot progress incomplete, wait for completition or abort current hack if you wish to withdraw");
        require(encryptedBalance[msg.sender] > 0, "insufficient HackerBot funds available to withdraw");
        require(timeOfHack[msg.sender] >= timeToFinishHack[msg.sender], "HackerBot progress incomplete, wait for completition or abort current hack if you wish to withdraw");
        
        toTransfer[msg.sender] = ((encryptedBalance[msg.sender]).add((((encryptedBalance[msg.sender]).mul(2)).div(100))));
        encryptedBalance[msg.sender] = 0;
        isHacking[msg.sender] == false;

        creditBalances[msg.sender] = creditBalances[msg.sender].add(toTransfer[msg.sender]);
        toTransfer[msg.sender] = 0;
        return true;
    }
    // Allows user to restart or cancel current hack
    function abortHack() external pauseFunction returns (bool success) {
        require(isHacking[msg.sender] == true, "HackerBot currently is not hacking");
        require(encryptedBalance[msg.sender] > 0, "no funds available in HackerBot");
        isHacking[msg.sender] == false;
        timeOfHack[msg.sender] == 0;
        timeToFinishHack[msg.sender] == 0;
        toTransfer[msg.sender] = encryptedBalance[msg.sender];
        encryptedBalance[msg.sender] = 0;
        _initalEncryptedBalance[msg.sender] = 0;
        creditBalances[msg.sender].add(toTransfer[msg.sender]);
        toTransfer[msg.sender] = 0;
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
        uint daysRemaining) 
            {
                return ( 
                    _initalEncryptedBalance[msg.sender],
                    ((_initalEncryptedBalance[msg.sender]).add((((_initalEncryptedBalance[msg.sender]).mul(2)).div(100)))),
                    (((_initalEncryptedBalance[msg.sender]).mul(2)).div(100)),
                    ((timeToFinishHack[msg.sender]).sub(now)), 
                    (((timeToFinishHack[msg.sender]).sub(now)).div(60)), 
                    ((((timeToFinishHack[msg.sender]).sub(now)).div(60)).div(60)), 
                    (((((timeToFinishHack[msg.sender]).sub(now)).div(60)).div(60)).div(24))
                );
    }
}