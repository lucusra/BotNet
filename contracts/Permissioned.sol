pragma solidity 0.6.6;

import "./SafeMath.sol";

contract Permissioned {
    address public owner = msg.sender;

    event OwnershipTransferred(address indexed from, address indexed to);

// ------------[ ownership functions ]---------------

    modifier onlyOwner() {
        require(msg.sender == owner, "This function is restricted to the contract's owner");
        _;
    }
    
    // Owner transfers ownership to new address
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner, "Already owner");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

// ------------ [ pause functions ] ---------------

    // When true, function(s) are paused
    bool public isPaused;

    // On - Off feature to resume functionality
    modifier pauseFunction {
        require(isPaused != true, "Function is paused by the owner");
        _;
    }

    // Owner pauses the contract - DISABLING functionality
    function pauseContract() public onlyOwner {
        require(isPaused != true, "Already paused functionality");
        isPaused = true;
    }

    // Owner resumes the contract - ENABLING functionality
    function resumeContract() public onlyOwner {
        require(isPaused != false, "Already resumed functionality");
        isPaused = false;
    }
}