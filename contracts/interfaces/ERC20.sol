//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

/// @notice ERC20 https://eips.ethereum.org/EIPS/eip-20 with optional symbol, name and decimals
interface ERC20 {
    function totalSupply() external view returns (uint totalSupply_includingDecimals, uint totalSupply_excludingDecimals);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function viewAllowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address _to, uint _amount) external returns (bool success);
    function approve(address _spender, uint _amount) external returns (bool success);
    function transferFrom(address _from, address _to, uint _amount) external returns (bool success);

// Are optional 
     function symbol() external view returns (string memory);
     function name() external view returns (string memory);
     function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
