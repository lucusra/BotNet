# BotNet 🤖

## Vision
Inspired by SushiSwap (https://github.com/sushiswap/sushiswap) & the games "The Division" & "Cyberpunk2077". I wanted to create a real world version of being in a futuristic society where everything is online, holograms are everywhere, and cybernetics are everywhere in the world. I essentially tried to create the currency for one of these worlds, with the ability to encrypt your Credits (the native currency) and transfer them to a HackerBot to begin hacking (the equivalent of staking). The HackerBot infiltrates the overworld government banking systems and disguises itself as a bank account, accurring interest from the bank. However, the HackerBot uses special tech to manipulate and boost the base interest rate for itself, causing an upsurge in credit generation over time.

I'm currently thinking about converting to an ERC1155 standard so that I could impliment NFTs (maybe bounties or special things to hack) which can be exchanged for Credits. Then I could eventaully turn it into a game with Engine or Unity.

This project isn't intended to be the next world currency, but more towards a spin off of SushiSwap, mainly because I liked the art style on the website.

## Contracts & Functionalities
### InfoBot 📋
Acts as a storage, containing all the data of each user.

### HackerBot 👥💬💰
- `encrypt_And_Hack`: You input an `encryptAmount` of Credits into the HackerBot, which then encrypts the funds. After the conversion, the HackerBot starts hacking, and after 30 days, the total amount of funds initally injected into it is increased by 2%. Becareful though, the HackerBot can only commence a single hack at a time. If you wish to retrieve your funds, you must either wait for it to finish hacking or `abortHack`.
- `decryptPortion_And_beginNewHack`: Begins a new hack after allowing users to decrypt more credits and, if they choose to, withdraw a porition of the encrypted HackerBot funds (such as profits from previously completed hack).
- `decrypt_And_Redeem`: When the hacking progress is complete, you are able to decrypt the funds and transfer the inital amount + the profit to your Credits balance.
- `abortHack`: Allows you to cancel the current hack in progress, transfering the funds back into your Credit balance, without any penalty or profit.
- `viewHack`: Displays the inital encrypted balance deposited into the HackerBot, the encrypted balance after the hack, the profit after the hack, and the time remaining until the hack is complete (in seconds, minutes, hours and days).

### SwapBot 🏦
- `exchange_Eth_To_Credits`: Converts ETH to Credits.
- `exchange_Credits_To_Eth`: Converts Credits to ETH.
- `setConversionRate`: Changes the conversion rate of how many Credits is equal to an ETH.
- `conversionRate`: Displays the conversion rate.

### DistributionBot 📠
The DistributionBot receives and distributes Credits, from rogue HackerBots that have accumulated funds from exploiting systems on the Net, to the users that are a part of the _**Enigma**_. You may enter the _Enigma_ by paying the entrance fee required at the time.
- `enterEnigma`: Users pay the fee to enter the _Enigma_. 
- `leaveEnigma`: Users can choose to leave the _Enigma_.
- `updateFee`: Owner updates fee (Maybe in the future: Users input what price the _Enigma_ entrace fee shall be. (Pushes number into array)).
- `viewEnigma`: Allows you to view the current fee to enter the _Enigma_ & the amount of funds in the _Enigma_. 
- `decryptEnigma`: Owner distributes funds accumulated from rogue HackerBots to accounts that have paid to enter the RoguePool. (Maybe in the future: decryptEnigmaPortion: allows users to decrypt/redeem their portion manually)


## Future Implementations 
### BountyBot 💸
The BountyBot has a list of people/organisations to hack, in which upon completition, you will receive ERC-721 NFTs that can be exchanged for Credits.

## License
- https://github.com/lucusra/BotNet/blob/main/LICENSE
- https://github.com/lucusra/BotNet/commit/a685fb56bf87904d37e02ec1ea0473efc479b9a8
