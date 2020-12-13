const { Contract } = require("ethers");

const Credits = artifacts.require('./Credits');

require("chai")
    .use(require("chai-as-promised"))
    .should()

const credit = (n) => {
    return new web3.utils.BN(
        web3.utils.toWei(n.toString(), "ether")
    )
}

contract("Credits", ([alice, bob]) => {
    const name = "Credits"
    const symbol = "CRDTS"
    const decimals = "18"
    const totalSupply = credit(1500000).toString()
    let credits

    beforeEach(async () => {
        credits = await Credits.new()
    })

    describe("deployment", () => {
        it("tracks the name", async () => {
            const result = await credits.name()
            result.should.equal(name)
            console.log(name)
        })

        it("tracks the symbol", async () => {
            const result = await credits.symbol()
            result.should.equal(symbol)
            console.log(symbol)
        })

        it("tracks the decimals", async () => {
            const result = await credits.decimals()
            result.toString().should.equal(decimals)
            console.log(decimals)
        })

        it("tracks the supply", async () => {
            const result = await credits.totalSupply()
            result.toString().should.equal(totalSupply.toString())
            console.log(totalSupply)
        })
    })

    describe("successful transfer", () => {
        it("transfers credits from alice to bob", async () => {
            let balanceOf

            // resumes the Credits.sol contract (begins paused)
            await credits.resumeContract()

            // before minting of tokens to alice
            balanceOf = await credits.balanceOf(alice)
            console.log("Alice | balance before minting:", balanceOf.toString())

            // mint the deployer tokens because all of the tokens are held by the contract
            await credits.generateCredits(alice, credit(100), { from: alice })

            // after minting of tokens to alice + before transfer to bob
            balanceOf = await credits.balanceOf(alice)
            console.log("Alice | balance after minting + before transfer:", balanceOf.toString())

            // bob's balance before the transfer
            balanceOf = await credits.balanceOf(bob)
            console.log("Bob | balance before transfer:", balanceOf.toString())

            // Transfer 100 credits to bob from alice (msg.sender)
            await credits.transfer(bob, credit(100), { from: alice })

            // Balances after transfer
            balanceOf = await credits.balanceOf(alice)
            balanceOf.toString().should.equal(credit(0).toString())
            console.log("Alice | balance after transfer:", balanceOf.toString())

            balanceOf = await credits.balanceOf(bob)
            balanceOf.toString().should.equal(credit(100).toString())
            console.log("Bob | balance after transfer:", balanceOf.toString())
        })
    
    // describe("unsuccessful transfer")
    //     it("rejects insufficient balances", async () => {
    //         let invalidAmount
    //         invalidAmount = credit(1000) // alice doesn't have 1000 tokens
    //         await token.transfer(alice, invalidAmount, { from: alice }).should.be.rejectedWith("VM Exception while processing transaction: revert");
    //     })

    })
})
