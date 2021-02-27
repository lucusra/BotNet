//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "./ERC20.sol";

/// @notice CreditsInterface = ERC20 + mint + burn. (c) The BotNet Project 2020

interface ICredits is ERC20 {
	function deleteCredits(uint _amount) external returns (bool success);

	event generatedCredits(uint indexed currentTotalSupply, address indexed generatedTo, uint indexed amountGenerated);
	event deletedCredits(uint totalSupply, uint amountDeleted);
}
