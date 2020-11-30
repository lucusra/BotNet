pragma solidity 0.6.6;

import "./ERC20.sol";

/// @notice CreditsInterface = ERC20 + mint + burn

interface CreditsInterface is ERC20 {
	function mint(address tokenOwner, uint tokens) external returns (bool success);
	function burn(uint tokens) external returns (bool success);
}