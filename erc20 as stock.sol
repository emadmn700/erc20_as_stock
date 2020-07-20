pragma solidity ^0.5.16;

contract ERC20_AS_STOCK {

    // the array of balances, matches each address to a number
    mapping (address => uint256) public balances;                   
    
    // a 2D array which in every profit distribution time matches addresses to their state of withdrawal
    mapping (uint64 =>  mapping (address => bool) ) withdrawn;      
    
    // i don't think anyone would listen to this event but it would be more 'standard' so i put it
    event ProfitReceived(address indexed receiver,uint amount);
    
    bool withdrawal_allowed;
    address owner;
    uint256 profit;
    // the below one is because resetting the withdrawn-refrence is not possible and you have to reset one-by-one
    // so it would be better to put a count or nonce so the previous data would be abandoned
    uint64 distribution_count = 0;


    string public name = "MyCompany";       // token name
    uint8 public decimals = 0;              // maximum decimals it accepts
    string public symbol = "SCS";           // sample company stock
    uint256 public totalSupply = 10**9;     // One billion stock papers 

    // the constructor function will run only when the contract is deployed, obviously it's deployed by its creator (company manager)
    constructor() public {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;                  // gives the creator all initial tokens
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        // it would be a great bug if any transfer happens during withdrawal time
        require( !withdrawal_allowed , "Sorry but you can't transfer during profit distribution time");
        //the sender(spender) is the message sender (contract caller)
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);         // raising the transfer event (doesn't matter for us)
        return true;
    }

    function () payable external {
        // if the sender is the owner it means he/she is gonna either distribute the profit (note that the profit is in ETH) or finish the withdrawal time
        // I know it might seem stupid but as i decided if the owner sends 0 ETH it means he/she is gonna end the profit withdrawal time
        // And if some amount of ETH is sent by the owner it's the profit which is gonna be distributed
        // the owner has to change the gas limit to at least 60,000 else will face error
        if(msg.sender == owner && msg.value == 0){
            require( withdrawal_allowed , "You first have to start the proccess of distributing profit then you may end it" );
            withdrawal_allowed = false;
            distribution_count++;
        }
        if(msg.sender == owner && msg.value != 0){
            require( !withdrawal_allowed , "You first have to end the corrent profit distribution proccess then you can start a new one" );
            withdrawal_allowed = true;
            // in my idea the profit whih is gonna be distributed is not only the value sent by the owner but the whole contract ETH balance
            profit = address(this).balance;  
        }
        // stock owners have to send a transaction to the contract ( 0 ETH value ofcourse , just the fee will apply for them ) to withdraw their profit
        // note that it's diffrent from token transferring and they have to send (0 ofcourse) ETH to the contract address
        // the point is that the stock owners who's gonna withdraw their profit have to change the gas limit ( 70,000 is enough )
        // the gas limit for ETH transaction is default set to 21000 but it's not enough as some proccess is happening here
        // Sorry for this structure but i think it was best...
        // changing gas limit and sending an amount is much easier for usual people rather than calling a function of the contract 
        if(msg.sender != owner){
            require( !withdrawn[distribution_count][msg.sender] , "You've already withdrawn your profit" );
            require( withdrawal_allowed , "withdrawal time has been finished" );
            withdrawn[distribution_count][msg.sender] = true;
            
            uint256 profit_amount = balances[msg.sender]*profit / ( totalSupply - balances[owner] );
            // address-balance devided by stock-owners-supply is the fraction of every one in the company so they will receive that fraction of profit
            // solidity is not a friend of decimal nums so i've got first write balance*profit then deviding it by stock-owners-supply
            // note that the profit value is in wei ( 1e-18 ETH )
            msg.sender.transfer( profit_amount );
            emit ProfitReceived(msg.sender , profit_amount);
        }
        // didn't use 'else' so it would be easier to understand, if your'e gonna use this code, do it!
    }
    
    
    
    // The below functions are no matter for us, just for respecting the ERC20 standard

    mapping (address => mapping (address => uint256)) public allowed;

    event Approval(address indexed tokenOwner, address indexed spender,uint tokens);
    event Transfer(address indexed from, address indexed to,uint tokens);
     
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        // it would be a great bug if any transfer happens during withdrawal time
        require( !withdrawal_allowed , "Sorry but you can't transfer during profit distribution time");
        
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) external view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}