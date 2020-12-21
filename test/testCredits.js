const { expect } = require("chai");
const { BigNumber } = require("ethers");

let Credits;
let hardhatCredits;
let creditsContract;
let addr1;
let addr2;

beforeEach(async function () {
    Credits = await ethers.getContractFactory("Credits");
    [creditsContract, addr1, addr2] = await ethers.getSigners();
    hardhatCredits = await Credits.deploy();
    await hardhatCredits.deployed();
});

describe("Credits contract", function() {
    it("Deployment should assign the total supply of credits to the contract", async function() {
        expect(await hardhatCredits.balanceOf(creditsContract.address).toString()).to.equal(hardhatCredits.totalSupply().toString());
    });

    it("Total supply should equal inital supply", async function() {
        expect(await hardhatCredits.totalSupply().toString()).to.equal(initialCreditsSupply.toString());
    });
});

describe("Transactions", function () {
    it("Should transfer tokens between accounts", async function() {
    
      // Transfer 50 tokens from owner to addr1
      await hardhatCredits.transfer(addr1.address, 50);
      expect(await hardhatCredits.balanceOf(addr1.address)).to.equal(50);
      
      // Transfer 50 tokens from addr1 to addr2
      await hardhatCredits.connect(addr1).transfer(addr2.address, 50);
      expect(await hardhatCredits.balanceOf(addr2.address)).to.equal(50);
    });
  });
