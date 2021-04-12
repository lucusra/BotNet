const { ethers } = require('hardhat');
const { expect } = require("chai");
const { BigNumber } = require("ethers");

let owner, user1, user2
let creditsIto, CreditsIto

describe("Credits Unit Tests", function() {
  beforeEach("Set testing environment", async () => {
    [owner, user1, user2] = await ethers.getSigners();

    CreditsIto = await ethers.getContractFactory("Credits");
    creditsIto = await CreditsIto.deploy();
    await creditsIto.deployed();


  })

  it("Deployment was successful", async () => {
    expect(await credits.symbol()).to.equal("CRDTS");
  });

  it("User1 purchases tokens", async () => {
    purchaseCreditsForEth()
  })
});
