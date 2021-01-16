const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("Credits.sol: Uint Tests", () => {
    let Credits, credits, addr1, addr2, addr3, addr4;

    beforeEach(async () => {
        Credits = await ethers.getContractFactory("Credits");
        credits = await Credits.deploy();
        [addr1, addr2, addr3, addr4, _] = await ethers.getSigners();
    });

    describe("Deployment", () => {
        it("Should set the contract's address as owner", async () => {
            expect(await credits.creditsContract()).to.equal(credits.address);
        });

        it("Should assign the totalSupply of credits to the creditsContract", async () => {
            let creditsContractBal = await credits.balanceOf(credits.address);
            expect(await credits.remainingUnheldCredits()).to.equal(creditsContractBal);
        });
    });

    describe("Transactions", () => {
        // it("Should use transfer() to send tokens from addr1 to addr2", async () => {
        //     credits.contractApprove(credits.address, addr1, 100);
        //     await credits.connect(addr1).transfer(addr2.address, 50);
        //     let addr2Balance = await credits.balanceOf(addr2.address);
        //     expect(addr2Balance).to.equal(50);
        //     expect(credits.balanceOf(addr1.address)).to.equal(0);
        // });

        // it("Should transfer tokens from addr1 to addr2", async () => {
        //     // Transfer from addr1 to addr2
        //     await token.connect(addr1).transfer(addr2.address, 50);
        //     let addr2Balance = await token.balanceOf(addr2.address);
        //     expect(addr2Balance).to.equal(50);
        //     addr1Balance = await token.balanceOf(addr1.address);
        //     expect(addr1Balance).to.equal(0);
        // });

        it("Should fail if sender doesn't have enough tokens", async () => {
            const initalCreditsSupply = await credits.balanceOf(credits.address);

            await expect(credits.connect(addr1).transfer(credits.address, 1)).to.be.revertedWith("Not enough tokens");
            expect(await credits.balanceOf(credits.address)).to.equal(initalCreditsSupply);
        });


        it("Should fail when user tries to access contract approve without access", async () => {
            await expect(credits.connect(addr1).contractApprove(credits.address, addr1, 100)).to.be.revertedWith("No access");
            expect(await credits.users[credits.address].allowance[addr1]).to.equal(0);
        });
        // it("Should update balances after transfers", async () => {
        //     const initialOwnerBalance = await token.balanceOf(owner.address);

        //     await token.transfer(addr1.address, 100);
        //     await token.transfer(addr2.address, 50);

        //     const finalOwnerBalance = await token.balanceOf(owner.address);
        //     expect(finalOwnerBalance).to.equal(initialOwnerBalance - 150);

        //     const addr1Balance = await token.balanceOf(addr1.address);
        //     expect(addr1Balance).to.equal(100);

        //     const addr2Balance = await token.balanceOf(addr2.address);
        //     expect(addr2Balance).to.equal(50);
        // });
    });

    // describe("", () => {
    //     it("Should fail if sender doesn't have enough tokens", async () => {
    //         const initialOwnerBalance = await token.balanceOf(owner.address);

    //         await expect(token.connect(addr1).transfer(owner.address, 1)).to.be.revertedWith("Not enough tokens");
    //         expect(await token.balanceOf(owner.address)).to.equal(initialOwnerBalance);
    //     });
    // });
});
