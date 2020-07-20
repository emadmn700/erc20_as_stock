# using ERC20 token as company stock 

Hi, I'm an ethereum lover and i'm not so glad that there are lots of of shit-tokens on ethereum network instead of company stocks existing as ERC20 tokens.
so i've changed an ERC20 contract token so it can be used as a company stock...

you may ask what's the diffrence either ?

a token (even a very useful one like chainlink or stable-coins or DeFi ones) doesn't produce value (not talking about DeFi staking or the ones which issue new tokens) but a company stock does...

By owning a stock paper(token) , you have certain rights including receiving a fraction of the company profit

## I had to set some rules

usual people are gonna use this so forget any contract-function-call... so i did put a set or rules which i'm gonna explain


FIRST i have to tell you the profit is in ETH and i'll be so glad if you write your own version which works with a stablecoin as the profit
SECOND as ethereum is not still scalable, there is HUGE COSTS distributing the profit which the company owner can not afford so the stock owners have to call the contract manually (an also change the gas limit as you'll see, it might even cost them up to 1$)

### withdrawal time

there's a boolean which the owner can only change its value, all transfers during withdrawl time will face error

```
require( !withdrawal_allowed , "Sorry but you can't transfer during profit distribution time");
```

### withdrawn refrence

there's a mapping object which is used to ensure an address requesting profit double will face error

i've explained more in the code comments  

### how the contract is being interacted

there's no function to interact but the proccess is done by sending an ETH transaction to the contract address (can have 0 ETH value but the fee will apply)


I've set three possiblities which i'll be happy if you'd improve it (they're in the no-name payable function)

### starting profit distribution

for this job the owner has to send the amount of profit in ETH to the contract (also has to change the gas limit of the transaction to at least 60K)

```
if(msg.sender == owner && msg.value != 0){
    require( !withdrawal_allowed , "You first have to end the corrent profit distribution proccess then you can start a new one" );
    withdrawal_allowed = true;
    profit = address(this).balance;  
}
```

### ending profit distribution

for this job the owner has to send zero amount of ETH to the contract (also has to change the gas limit)

```
if(msg.sender == owner && msg.value == 0){
    require( withdrawal_allowed , "You first have to start the proccess of distributing profit then you may end it" );
    withdrawal_allowed = false;
    distribution_count++;
}
```

### receiving the profit

obviously every address is gonna receive a fraction : ( address-balance / stock-owners-supply ) of the profit

they (stock owners) have to send a transaction (ofcourse 0 value of ETH) to the contract address

the point is that they have to change the gas limit to at least 70K (and ofcourse they must have some ETH in their address to pay the fee) 

```
if(msg.sender != owner){
    require( !withdrawn[distribution_count][msg.sender] , "You've already withdrawn your profit" );
    require( withdrawal_allowed , "withdrawal time has been finished" );
    withdrawn[distribution_count][msg.sender] = true;
    
    uint256 profit_amount = balances[msg.sender]*profit / ( totalSupply - balances[owner] );
    // address-balance devided by stock-owners-supply is the fraction of every one in the company so they will receive that fraction of profit
    msg.sender.transfer( profit_amount );
    emit ProfitReceived(msg.sender , profit_amount);
}
```

## Improvements

this structure causes price pump during profit distribution period and also exchanges are able to receive considerable amount of the profit

i'm waiting for you to improve the code in which stock owners have to stake their tokens for a while

## more details in the code comments
