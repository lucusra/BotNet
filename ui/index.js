// Connect to the selected network (i.e. kovan, mainnet, etc)
var web3 = new Web3(Web3.givenProvider);
// Use this instead of ^ when using infura
// var web3 = new Web3(new Web3.providers.WebsocketProvider("wss://mainnet.infura.io/ws"));

// Our contract instance
var instance;
var user;

// Deploy contract, then set this to that address
var contractAddress = "";

$(document).ready(function(){
    // Prompts metamask window
    window.ethereum.enable().then(function(accounts){
        // Sets the contract we're using
        instance = new web3.eth.Contract(abi, contractAddress, { from: accounts[0] })
        user = accounts[0];

        console.log(instance);


        // Events (https://web3js.readthedocs.io/en/v1.2.9/web3-eth-contract.html#contract-events)
        instance.events.Birth().on("data", function(event){
            console.log(event);
            // Returns values from smart contract event
            let owner = event.returnValues.owner;
            let kittyId = event.returnValues.kittyId;
            $("#kittyCreation").css("display", "block");
            $("#kittyCreation").text("owner: " + owner
                                    +" kittyId: " + kittenId);
        });
    })
})


function createKitty(){
    var dnaStr = getDna();

    // This calls the solidity function `createKittyGen0`
    // Send is used if its not a view function - i.e. we're manipulating something
    instance.methods.createKittyGen0(dnaStr).send({}, function(error, txHash){
        if(err) {
            console.log(err);
        } else {
            console.log(txHash);
        }
    })
}