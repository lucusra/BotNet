const { ethers } = require('hardhat');
const { expect } = require("chai");
const { BigNumber } = require("ethers");

let owner, user1, user2
let credits, Credits

describe("Credits Unit Tests", function() {
  beforeEach("Set testing environment", async () => {
    [owner, user1, user2] = await ethers.getSigners();

    Credits = await ethers.getContractFactory("Credits");
    credits = await Credits.deploy();
    await credits.deployed();
  })

  it("Deployment was successful", async () => {
    expect(await credits.symbol()).to.equal("CRDTS");
    expect(await credits.name()).to.equal("Credits");
    expect(await credits.decimals()).to.equal(18);
    expect(await credits.totalSupply()).to.equal(0);
    expect(await credits.totalSupplyCap()).to.equal(BigNumber.from(1000000*(18**10)));
  });

  it("User1 purchases tokens", async () => {
    purchaseCreditsForEth()
  })
});
