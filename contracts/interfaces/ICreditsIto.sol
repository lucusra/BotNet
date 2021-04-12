//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

interface ICredits {

    // Logs credit bond purchase
    event CreditBondPurchase(address indexed beneficiary, uint256 indexed creditBondAmount, uint256 indexed timeOfPurchase);
    
    // Logs credit bond redemption
    event CreditBondRedemption(address indexed beneficiary, uint256 indexed creditBondAmount, uint256 indexed timeOfRedemption); 
    
    // When developer withdraws eth
    event developerEthWithdrawal(address indexed beneficiary, uint256 indexed amount, uint256 indexed timeOfWithdrawal); 
    
    // When developer withdraws credits (helps users prepare for a dump if need be)
    event developerCreditsWithdrawal(address indexed beneficiary, uint256 indexed amount, uint256 indexed timeOfWithdrawal);  


    // Allows owner to update the eth to credibytes conversion rate
    function setRate_EthToCredits(uint _newRate) external;
    
    // Allows owner to update the minimum amount of eth to partake in the ITO
    function updateMinimumRequirement(uint _newMinimumRequirement) external;
    
    // Allows owner to finish the ITO before the timelock is over
    function finalise() external;
    
    // Allows users to view when the dev. timelock is over
    function viewTimeLockStatus() external view returns (uint256 timelockCommenced, uint256 timelockCompletition, uint256 timeRemaining);
    
    // Allows the developer to withdraw "x" amount of  the remaining, unsold credits, or send them to the credits contract
    function developerCreditsWithdraw(address _to, uint256 _amount) external;
    
    // Allows the developer to withdraw a desired amount of ETH to their desired address
    function developerEthWithdraw(address payable _to, uint256 _amount) external;

    // Allows the user to conver their credits to credits
    function redeemCredits() external returns (uint256 convertedAmount, bool sucess);

    // Transfers eth to designated collector & transfers credits to beneficiary
    function buyCreditBond_withETH(address beneficiary) external payable;
    
    // Views the inputted user's pending credit balance to be redeemed
    function viewCreditBondBalance(address user) external view returns (uint256 _creditBondBalance);
    
    // Views how many remaining credibytes there are for purchase, with the total eth value of the remaining
    function viewRemainingCreditsForPurchase() external view returns (uint256 remainingCredibytesForPurchase, uint256 ethValueOfRemainingCredibytesForPurchase);

    // Fetches amount of eth raised from ito 
    function viewEthRaised() external view returns (uint256 totalEthRaised, uint256 ethCurrentlyLocked);

    // If unlocked, call buyCredits_forEth || If locked, revert tx.
    receive() external payable;

}