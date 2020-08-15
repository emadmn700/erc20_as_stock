pragma solidity ^0.5.16;

contract ERC20_AS_STOCK {

    mapping (address => uint256) public balances;
    mapping (uint32 =>  mapping (address => bool) ) public withdrawn;       // uint32 : distribution_count , bool : profit received or not
    mapping (uint32 =>  mapping (address => bool) ) public voted;           // uint32 : election_count , bool : voted or not
    mapping (uint32 =>  mapping (uint8 => uint256) ) public proposals;      // uint32 : election_count , uint8 : proposal_id , uint256 : proposal_vote_count
    
    event WithdrawalAllowed(uint256 profit_amount);
    event WithdrawalEnded(uint256 remaining_amount);
    event ElectionStarted();
    event ElectionEnded();
    
    address public chairperson;
    uint256 public profit;
    bool public withdrawal_allowed;
    bool public voting_allowed;
    uint32 public distribution_count = 0;           // every time the company distributes its profit
    uint32 public election_count = 0;               // every time the company runs an election proccess

    string public name = "MyCompany";       // token name
    uint8 public decimals = 0;              // maximum decimals it accepts
    string public symbol = "SCS";           // sample company stock
    uint public totalSupply = 10**9;        // One billion stock papers 

    modifier onlyOwner {
        require( msg.sender == chairperson, "Only owner can call this function." );
        _;
    }

    constructor() public {
        chairperson = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        
        require( !(withdrawal_allowed && msg.sender == chairperson) , "You just can't transfer during withdrawal time");
        require( !withdrawn[distribution_count][msg.sender] , "As you've received the company stock profit, you can't transfer untill withdrawal time is ended");
        require( !voted[election_count][msg.sender] , "As you have voted, you can't transfer untill voting time is ended");
        
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    // FIRST WAY : stock owners can use this function to withdraw their fraction of the company profit
    function ReceiveYourProfit() public{
        require( msg.sender != chairperson );
        require( !withdrawn[distribution_count][msg.sender] , "You've already withdrawn your profit" );
        require( withdrawal_allowed , "Withdrawal time has been finished" );
        withdrawn[distribution_count][msg.sender] = true;

        msg.sender.transfer( balances[msg.sender]*profit / ( totalSupply - balances[chairperson] ) );
        // address-balance ÷ stock-owners-supply is the fraction of everyone in the company so they will receive that fraction of profit
    }
    
    // SECOND WAY : stock owners can send a transaction (with 0 amount of ETH ofcourse) to the contract address for withdrawal, just the fee will apply
    // note that they have to change the gas limit (70K is enough)
    function () payable external {
        ReceiveYourProfit();
    }
    
    // The chairperson has to send the profit in ETH to this function
    // IMPORTANT : the ETH sent by the chairperson to this function is the value which is gonna be received by the stock owners and not him.
    function AllowWithdrawal() payable external onlyOwner{
        require( !withdrawal_allowed , "You first have to end the current profit distribution proccess then you can start a new one" );
        withdrawal_allowed = true;
        // the profit whih is gonna be distributed is the whole contract ETH balance
        profit = address(this).balance;
        emit WithdrawalAllowed(profit);
    }
    
    function EndWithdrawal() external onlyOwner{
        require( withdrawal_allowed , "You first have to start the proccess of distributing profit then you may end it" );
        withdrawal_allowed = false;
        distribution_count++;
        uint256 remaining = address(this).balance;
        msg.sender.transfer( remaining );                // the value belonging to those who didn't withdraw will be sent back to the chairperson :)
        emit WithdrawalEnded(remaining);
    }
    
    // No need to input the proposal or candidate names, the chairperson will announce instructions separately
    function StartElection() external onlyOwner{
        require( !voting_allowed , "You first have to end the current election then you can start a new one" );
        voting_allowed = true;
        
        emit ElectionStarted();
    }
    
    // No need to return the winner_id , everyone's vote count is seen
    function EndElection() external onlyOwner{
        require( voting_allowed , "You first have to start an election then you may end it" );
        voting_allowed = false;
        
        election_count++;
        emit ElectionEnded();
    }
    
    // The chairperson will announce which id belongs to which proposal or candidate
    function Vote(uint8 _id) external{
        require( !voted[election_count][msg.sender] , "Changing vote is not possible" );
        require( voting_allowed , "The voting period has been finished" );
        voted[election_count][msg.sender] = true;
        
        // The weight of everyone in voting is their balance
        proposals[election_count][_id] += balances[msg.sender];
    }
    
    // The below functions are no matter for us, just for respecting the ERC20 standard

    mapping (address => mapping (address => uint256)) allowed;

    event Approval(address indexed tokenOwner, address indexed spender,uint tokens);
    event Transfer(address indexed from, address indexed to,uint tokens);
     
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        
        require( !withdrawn[distribution_count][_from] ,
        "You can't transfer from an address which has received the company stock profit untill withdrawal time is ended");
        require( !voted[election_count][_from] , "You can't transfer from an address which has voted untill the voting time is ended");
        
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
        require( msg.sender != chairperson , "This option is not available for you");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}
