require("@nomiclabs/hardhat-ethers");
require('@nomiclabs/hardhat-waffle')

module.exports = {
  solidity: {
    compilers: [
      {
        version: '0.7.0',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
};