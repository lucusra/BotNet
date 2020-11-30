const Credits = artifacts.require("Credits");
const CreditsInterface = artifacts.require("CreditsInterface");
const ERC20 = artifacts.require("ERC20");
const HackerBot = artifacts.require("HackerBot");
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
  deployer.deploy(ERC20);
};
module.exports = function (deployer) {
  deployer.deploy(HackerBot);
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