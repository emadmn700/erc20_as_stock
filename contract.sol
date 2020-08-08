pragma solidity ^0.5.16;

contract ERC20_AS_STOCK {

    // the array of balances, matches each address to a number
    mapping (address => uint256) public balances;                   
    
    // a 2D array which in every profit distribution time matches addresses to their state of withdrawal
    mapping (uint64 =>  mapping (address => bool) ) withdrawn;      
    
    // contract events (i wonder if anyone listens to them...)
    event ProfitReceived(address indexed receiver,uint amount);
    event WithdrawalAllowed(uint profit_amount);
    event WithdrawalDisallowed(uint remaining_amount);
    
    bool public withdrawal_allowed;
    address public owner;
    uint128 public profit;
    // the below one is because resetting the withdrawn-refrence is not possible and you have to reset one-by-one
    // so it would be better to put a count or nonce so the previous data would be abandoned
    // also the owner can access previous data
    uint64 public distribution_count = 0;


    string public name = "MyCompany";       // token name
    uint8 public decimals = 0;              // maximum decimals it accepts
    string public symbol = "SCS";           // sample company stock
    uint public totalSupply = 10**9;     // One billion stock papers 

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
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function () payable external {
        require( msg.sender != owner , "what the hell are you doing manager?");
        // stock owners have to send a transaction to the contract ( 0 ETH value ofcourse , just the fee will apply for them ) to withdraw their profit
        // note that it's diffrent from token transferring and they have to send (0 ofcourse) ETH to the contract address
        // the point is that the stock owners who's gonna withdraw their profit have to change the gas limit ( 80,000 is enough )
        // the gas limit for ETH transaction is default set to 21000 but it's not enough as some proccess is happening here
        // Sorry for this structure but i think it was best...
        // changing gas limit and sending an amount is much easier for usual people rather than calling a function of the contract 
        
        require( !withdrawn[distribution_count][msg.sender] , "You've already withdrawn your profit" );
        require( withdrawal_allowed , "withdrawal time has been finished" );
        withdrawn[distribution_count][msg.sender] = true;

        uint128 amount = balances[msg.sender]*profit / ( totalSupply - balances[owner] );
        // address-balance devided by stock-owners-supply is the fraction of every one in the company so they will receive that fraction of profit
        // solidity is not a friend of decimal nums so i've got first write balance*profit then deviding it by stock-owners-supply
        // note that the profit value is in wei ( 1e-18 ETH )
        msg.sender.transfer( amount );
        emit ProfitReceived(msg.sender , amount);
    }
    
    // the owner has to send the profit in ETH to this function(note that he's not gonna send his own fraction or part)
    function AllowWithdrawal() payable external{
        require( msg.sender == owner , "so what do you think you're doing?");
        require( !withdrawal_allowed , "You first have to end the corrent profit distribution proccess then you can start a new one" );
        withdrawal_allowed = true;
        // the profit whih is gonna be distributed is the whole contract ETH balance
        profit = address(this).balance;
        emit WithdrawalAllowed(profit);
    }
    
    // calling this function will end withdrawal time and send back the remaining value to the owner
    function DisallowWithdrawal() external{
        require( msg.sender == owner , "so what do you think you're doing?");
        require( withdrawal_allowed , "You first have to start the proccess of distributing profit then you may end it" );
        withdrawal_allowed = false;
        distribution_count++;
        uint128 remaining = address(this).balance;
        msg.sender.transfer( remaining );                // the profit of those who didn't withdraw will sent back to the owner :)
        emit WithdrawalDisallowed(remaining);
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
