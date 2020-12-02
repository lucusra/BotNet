const Credits = artifacts.require("Credits");
const CreditsInterface = artifacts.require("CreditsInterface");
const DistributionBot = artifacts.require("DistributionBot");
const ERC20 = artifacts.require("ERC20");
const HackerBot = artifacts.require("HackerBot");
const InfoBot = artifacts.require("InfoBot");
const Permissioned = artifacts.require("Permissioned");
const SafeMath = artifacts.require("SafeMath");
const SwapBot = artifacts.require("SwapBot");

module.exports = function (deployer) {
  deployer.deploy(Credits);
};
module.exports = function (deployer) {
  deployer.deploy(CreditsInterface);
};
module.exports = function (deployer) {
  deployer.deploy(DistributionBot);
};
module.exports = function (deployer) {
  deployer.deploy(ERC20);
};
module.exports = function (deployer) {
  deployer.deploy(HackerBot);
};
module.exports = function (deployer) {
  deployer.deploy(InfoBot);
};
module.exports = function (deployer) {
  deployer.deploy(Permissioned);
};
module.exports = function (deployer) {
  deployer.deploy(SafeMath);
};
module.exports = function (deployer) {
  deployer.deploy(SwapBot);
};
