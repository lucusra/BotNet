//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "./IERC20.sol";

/// @notice CreditsInterface = ERC20 + mint + burn. (c) The BotNet Project 2020

interface ICredits is IERC20 {
	event generatedCredits(uint indexed currentTotalSupply, address indexed generatedTo, uint indexed amountGenerated);
	event deletedCredits(uint totalSupply, uint amountDeleted);

	function totalSupplyCap() external view returns (uint256);
	function purchaseCreditsForEth() external payable returns (uint creditsPurchased, uint etherAmount);
}
