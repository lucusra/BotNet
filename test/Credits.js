const { expect } = require("chai");

describe("Credits.sol: Uint Tests", () => {
    let Credits, credits, creditContract, addr1, addr2;

    beforeEach(async () => {
        Credits = await ethers.getContractFactory("Credits");
        credits = await Credits.deploy();
        [creditsOwner, addr1, addr2, _] = await ethers.getSigners();
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
        it("Should transfer tokens between accounts", async () => {
            // Transfer from send to recipient
            console.log("Sender creditBalance is %s credits", users[_to].creditBalance);
            await token.transfer(addr1.address, 50);
            console.log("Sent %s credits to %s", _amount, _to);
            let addr1Balance = await token.balanceOf(addr1.address);
            expect(addr1Balance).to.equal(50);
        });

        // it("Should transfer tokens from addr1 to addr2", async () => {
        //     // Transfer from addr1 to addr2
        //     await token.connect(addr1).transfer(addr2.address, 50);
        //     let addr2Balance = await token.balanceOf(addr2.address);
        //     expect(addr2Balance).to.equal(50);
        //     addr1Balance = await token.balanceOf(addr1.address);
        //     expect(addr1Balance).to.equal(0);
        // });

        // it("Should fail if sender doesn't have enough tokens", async () => {
        //     const initialOwnerBalance = await token.balanceOf(owner.address);

        //     await expect(token.connect(addr1).transfer(owner.address, 1)).to.be.revertedWith("Not enough tokens");
        //     expect(await token.balanceOf(owner.address)).to.equal(initialOwnerBalance);
        // });

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
});