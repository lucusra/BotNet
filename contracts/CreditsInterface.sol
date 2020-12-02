pragma solidity 0.6.6;

import "./ERC20.sol";

/// @notice CreditsInterface = ERC20 + mint + burn. (c) The BotNet Project 2020

interface CreditsInterface is ERC20 {
	function generateCredits(address tokenOwner, uint tokens) external returns (bool success);
	function deleteCredits(uint tokens) external returns (bool success);
}
