// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./Credits.sol";

import "./interfaces/uniswapv2.sol";

// Contract for implementing UniSwap
contract UniBot {
    using SafeMath for uint256;

    UniswapRouterV2 router = UniswapRouterV2(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );

    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant creditsAddress = "CREDITS CONTRACT ADDRESS"; 


//  ----------------------------------------------------
//                      Functions 
//  ----------------------------------------------------

   function convertEthToCredits(uint daiAmount, uint deadline) public payable {   // For mainnet pass deadline from frontend!
    router.swapETHForExactTokens{ value: msg.value }(daiAmount, getPathForETHtoCREDITS(), address(this), deadline);
    
    // refund leftover ETH to user
    (bool success,) = msg.sender.call{ value: address(this).balance }("");
    require(success, "refund failed");
  }
  
  function getEstimatedETHforCREDITS(uint daiAmount) public view returns (uint[] memory) {
    return router.getAmountsIn(daiAmount, getPathForETHtoCREDITS());
  }

  function getPathForETHtoCREDITS() private pure returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = weth;
    path[1] = creditsAddress;
    
    return path;
  }
  
  // important to receive ETH
  receive() payable external {}
}