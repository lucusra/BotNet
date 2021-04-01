//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "./SafeMath.sol";

contract Permissioned  {
    using SafeMath for uint256;

    // The address that can manipulate the contracts' states
    address public owner;

    // Whether or not the address has access to call the `contractAccess` modified functions
    mapping(address => bool) hasContractAccess;

    // When true, function(s) are paused
    bool public isPaused;

    event OwnershipTransferred(
        address indexed from, 
        address indexed to
    );

    modifier onlyOwner() {
        require(
            msg.sender == owner, 
            "ERROR: This function is restricted to the contract's owner"
        );
        _;
    }

    modifier requireContractAccess() {
        require(
            msg.sender.hasContractAccess == true,
            "ERROR: No access"
        );
        _;
    }


    constructor() {
        owner = msg.sender;
        msg.sender.hasContractAccess = true;
        isPaused = false;
    }

    // On - Off feature to resume functionality
    modifier pauseFunction {
        require(isPaused != true, "ERROR: Function is paused by the owner");
        _;
    }

    // Owner transfers ownership to new address
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner.isOwner != true, "ERROR: Already owner");
        msg.sender.isOwner = false;
        _newOwner.isOwner = true;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }

    function grantContractAccess(address _address) public onlyOwner returns (bool success, bool updatedStatus) {
        require(_address != owner && _address.CoOwner != true, "ERROR: Unable to give yourself contract access");
        _address.hasContractAccess = true;
        return(true, _address.hasContractAccess);
    }

    // Owner pauses the contract - DISABLING functionality
    function pauseContract() public onlyOwner {
        require(isPaused != true, "ERROR: Already paused functionality");
        isPaused = true;
    }

    // Owner resumes the contract - ENABLING functionality
    function resumeContract() public onlyOwner {
        require(isPaused != false, "ERROR: Already resumed functionality");
        isPaused = false;
    }
}
