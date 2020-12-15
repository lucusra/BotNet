const SafeMath = artifacts.require("SafeMath");
const Permissioned = artifacts.require("Permissioned");
const InfoBot = artifacts.require("InfoBot");
const ERC20 = artifacts.require("ERC20");
const CreditsInterface = artifacts.require("CreditsInterface");
const Credits = artifacts.require("Credits");
const CreditsITO = artifacts.require("CreditsITO");
const DistributionBot = artifacts.require("DistributionBot");
const HackerBot = artifacts.require("HackerBot");
const SwapBot = artifacts.require("SwapBot");

module.exports = function (deployer) {
  deployer.deploy(SafeMath);
  deployer.deploy(Permissioned);
  deployer.deploy(InfoBot);
  deployer.deploy(ERC20);
  deployer.deploy(CreditsInterface);
  deployer.deploy(Credits);
  deployer.deploy(CreditsITO);
  deployer.deploy(DistributionBot);
  deployer.deploy(HackerBot);
};

module.exports = async function (deployer) {
  const accounts = await web3.eth.getAccounts()

  const feeAccount = accounts[0]
  const feePercent = 10

  await deployer.deploy(SwapBot, feeAccount, feePercent);
};
