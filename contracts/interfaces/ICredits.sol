//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "./interfaces/ERC20.sol";

/// @notice CreditsInterface = ERC20 + mint + burn. (c) The BotNet Project 2020

interface ICredits is ERC20 {
	function generateCredits(address _to, uint _amount) external returns (bool success);
	function deleteCredits(uint _amount) external returns (bool success);

	event generatedCredits(uint totalSupply, address generatedTo, uint amountGenerated);
	event deletedCredits(uint totalSupply, uint amountDeleted);
}
