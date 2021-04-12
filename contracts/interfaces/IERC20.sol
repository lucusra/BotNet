//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

/// @notice ERC20 https://eips.ethereum.org/EIPS/eip-20 with optional symbol, name and decimals
interface IERC20 {
    function totalSupply() external view returns (uint256 tokenTotalSupply);
    function balanceOf(address tokenOwner) external view returns (uint256);
    function viewAllowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function transfer(address to, uint256 amount) external returns (bool success);
    function approve(address spender, uint256 amount) external returns (bool success);
    function transferFrom(address from, address to, uint256 amount) external returns (bool success);

// Are optional 
     function symbol() external view returns (string memory);
     function name() external view returns (string memory);
     function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}
