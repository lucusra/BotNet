//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "./SafeMath.sol";

contract Permissioned  {
    using SafeMath for uint256;

    // Whether or not the address has access to call the `contractAccess` modified functions
    mapping(address => bool) _hasContractAccess;

    // The address that can manipulate the contracts' states
    address owner;

    // When true, function(s) are paused
    bool public isPaused;

    // Emits previous owner to new owner
    event OwnershipTransferred(
        address indexed from, 
        address indexed to
    );

    // Caller must be owner, otherwise fail
    modifier onlyOwner() {
        require(msg.sender == owner, "ERROR: This function is restricted to the contract's owner");
        _;
    }

    // Caller must have contract access, otherwise fail
    modifier requireContractAccess() {
        require(_hasContractAccess[msg.sender] == true, "ERROR: No contract access");
        _;
    }

    constructor() {
        owner = msg.sender;
        _hasContractAccess[msg.sender] = true;
        isPaused = false;
    }

    // On - Off feature to resume functionality
    modifier pauseFunction {
        require(isPaused != true, "ERROR: Function is paused by the owner");
        _;
    }

    // Owner transfers ownership to new address
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != owner, "ERROR: Already owner");
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }

    // Fetches the inputted address to see if they have contract access
    function hasContractAccess(address fetchAddress) public view returns (bool) {
        return(_hasContractAccess[fetchAddress]);
    }

    // Gives the inputted address contract access 
    function grantContractAccess(address grantedAddress) public onlyOwner returns (bool success, bool updatedStatus) {
        require(grantedAddress != owner, "ERROR: Unable to give yourself contract access");
        _hasContractAccess[grantedAddress] = true;
        return(true, _hasContractAccess[grantedAddress]);
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
