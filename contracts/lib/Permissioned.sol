//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./DataBot.sol";

contract Permissioned is DataBot {
    
    constructor() {
        users[msg.sender].isOwner = true;
        users[msg.sender].hasContractAccess = true;
        owner = msg.sender;
        isPaused = false;
    }

//  ----------------------------------------------------
//                      Ownership 
//  ----------------------------------------------------

    address public owner;

    event OwnershipTransferred(
        address indexed from, 
        address indexed to
    );
    event NewCoOwner(
        address indexed promoter, 
        address indexed newCoOwner
    );
    event RevokedCoOwner(
        address indexed revoker, 
        address indexed revokedCoOwner
    );

    modifier onlyOwner() {
        require(
            users[msg.sender].isOwner == true, 
            "ERROR: This function is restricted to the contract's owner"
        );
        _;
    }

    modifier permissionRequired() {
        require(
            users[msg.sender].isOwner == true || users[msg.sender].isCoOwner == true, 
            "ERROR: This function is restricted to the contract's owner & co-owner(s)"
        );
        _;
    }
    
    function addCoOwner(address _user) public onlyOwner {
        require(users[_user].isCoOwner != true && users[_user].isOwner != true, "ERROR: Already Owner or CoOwner");
        users[_user].isCoOwner = true;
        emit NewCoOwner(msg.sender, _user);
    }

    function revokeCoOwner(address _user) public onlyOwner {
        require(users[_user].isCoOwner == true, "ERROR: User currently not a CoOwner");
        users[_user].isCoOwner = false;
        emit RevokedCoOwner(msg.sender, _user);
    }

    // Owner transfers ownership to new address
    function transferOwnership(address _newOwner) public onlyOwner {
        require(users[_newOwner].isOwner != true, "ERROR: Already owner");
        users[msg.sender].isOwner = false;
        users[_newOwner].isOwner = true;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }


//  ----------------------------------------------------
//                   Contract Access
//  ----------------------------------------------------

    modifier contractAccess() {
        require(
            users[msg.sender].hasContractAccess == true,
            "ERROR: No access"
        );
        _;
    }

    function giveContractAccess(address _address) external onlyOwner returns (bool success, bool updatedStatus) {
        require(_address != owner, "ERROR: Unable to give yourself contract access");
        users[_address].hasContractAccess = true;
        return(true, users[_address].hasContractAccess);
    }

//  ----------------------------------------------------
//                    Pause Functions 
//  ----------------------------------------------------

    // When true, function(s) are paused
    bool public isPaused;

    // On - Off feature to resume functionality
    modifier pauseFunction {
        require(isPaused != true, "ERROR: Function is paused by the owner");
        _;
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
