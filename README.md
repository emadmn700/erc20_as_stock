# using ERC20 token as company stock 

Hi, I'm an ethereum lover and i'm not so glad that there are lots of of shit-tokens on ethereum network instead of company stocks existing as ERC20 tokens.
so i've changed an ERC20 contract token so it can be used as a company stock...

you may ask what's the diffrence either ?

a token (even a very useful one like chainlink or stable-coins or DeFi ones) doesn't produce value (not talking about DeFi staking or the ones which issue new tokens) but a company stock does...

By owning a stock paper(token) , you have certain rights including receiving a fraction of the company profit

## I had to set some rules

usual people are gonna use this so forget any contract-function-call except for the owner...


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

FOR STOCK OWNERS : the proccess is done by sending an ETH transaction to the contract address (will have 0 ETH value but the fee will apply, have to change gas limit)

FOR CONTRACT OWNER : there are two function to start and end the profit distribution period

possiblity : we might change the rule that stock owners have to send 0 amount of token to for exmple their own address so there MIGHT be no gas limit change

my opinion : stock owners and normal people won't approve contract function call, either of the two ways mentioned should be used

### starting profit distribution

for this job the owner has to call the contract

```
function AllowWithdrawal() payable external{
    require( msg.sender == owner );
    require( !withdrawal_allowed , "You first have to end the corrent profit distribution proccess then you can start a new one" );
    withdrawal_allowed = true;
    // the profit whih is gonna be distributed is the whole contract ETH balance
    profit = address(this).balance;
    emit WithdrawalAllowed(profit);
}
```

### ending profit distribution

for this job the owner has to call the contract, the remainig balance is the profit of those who didn't withdraw

in my case it's sent backed to the owner, you can write other scenarios

```
function DisallowWithdrawal() payable external{
    require( msg.sender == owner , "so what do you think you're doing?");
    require( withdrawal_allowed , "You first have to start the proccess of distributing profit then you may end it" );
    withdrawal_allowed = false;
    distribution_count++;
    uint256 remaining = address(this).balance;
    msg.sender.transfer( remaining );                // the profit of those who didn't withdraw will sent back to the owner :)
    emit WithdrawalDisallowed(remaining);
}
```

### receiving the profit

obviously every address is gonna receive a fraction : ( address-balance / stock-owners-supply ) of the profit

they (stock owners) have to send a transaction (ofcourse 0 value of ETH) to the contract address

the point is that they have to change the gas limit (and ofcourse they must have some ETH in their address to pay the fee)

i'll soon update how much gas is required

```
function () payable external {
    require( msg.sender != owner);
    require( !withdrawn[distribution_count][msg.sender] , "You've already withdrawn your profit" );
    require( withdrawal_allowed , "withdrawal time has been finished" );
    withdrawn[distribution_count][msg.sender] = true;

    uint256 amount = balances[msg.sender]*profit / ( totalSupply - balances[owner] );
    msg.sender.transfer( amount );
    emit ProfitReceived(msg.sender , amount);
}
```

## Improvements

this structure causes price pump during profit distribution period and also exchanges are able to receive considerable amount of the profit

i'm waiting for you to improve the code in which stock owners have to stake their tokens for a while

### more details in the code comments
