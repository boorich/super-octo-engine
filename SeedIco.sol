pragma solidity ^0.4.18;

/**
TODO:
- Investors can invest in project by sending ETHER
- Investors can never invest more then 25% of the total deposited ETHER
- Investors recieve 1 DEVCOIN per 1 ETHER
- In case that we need to increase the overall deposit because an investor wants to send more then waht would be 25%
  we need to lock the suprplus and allow all other investors to top up their deposits so
- DEVCOINs grant their owners the right to vote on upcoming development tasks (yes/no and amount of funding)
- DEVCOINS can be sold anytime, ubder the 25% rule, but they will only yield 1 ETH back during development
- After the solution is live, DEVCOINS are "delegated" to the main Smart Contract that controls all payment of the solution and
  this is when DEVCOINS rise or decrease in value according to success of sultion
 */

// Safe Math library that automatically checks for overflows and underflows
library SafeMath {
    // Safe multiplication
    function mul(uint256 a, uint256 b) internal pure returns (uint) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    // Safe subtraction
    function sub(uint256 a, uint256 b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }
    // Safe addition
    function add(uint256 a, uint256 b) internal pure returns (uint) {
        uint256 c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}

contract ERC20 {

    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This creates a mapping with all balances
    mapping (address => uint256) public balanceOf;
    // Another mapping with spending allowances
    mapping (address => mapping (address => uint256)) public allowance;
    // The total supply of the token
    uint256 public totalSupply;

    // Some variables for nice wallet integration
    string public name = "DevToken";          // Set the name for display purposes
    string public symbol = "DT" ;             // Set the symbol for display purposes
    uint8 public decimals = 18;                // Amount of decimals for display purposes

    function ERC20() {
        totalSupply = 0;
    }
    // Send coins
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != 0x0);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != 0x0);
        balanceOf[_to] = balanceOf[_to].add(_value);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

        // Approve that others can transfer _value tokens for the msg.sender
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require((_value == 0) || (allowance[msg.sender][_spender] == 0));
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowance[msg.sender][_spender] = allowance[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }
    
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowance[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowance[msg.sender][_spender] = 0;
        } else {
            allowance[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }
}
contract SeedIco is ERC20 {

    // Address of owner
    address public owner;
    
    // Constructor


    // Modifiers: only allows Owner/Pool/Contract to call certain functions

    // Deposit
    function () public payable {
        // drop your Ether here this is the Token-Sale
    }

    // create Devcoin
    function createDevcoin() {
        // convert 1 Eth to 1 DC
    }

    // raise total Deposit
    function raiseDeposit() {
        // lock funds that violate 25% rule and allow other Devcoin-Qwners to jointly increase deposit
    }

    // allow Vote
    function allowVote() {
        // grant the right to and execute voting on upcoming development tasks
    }    

    // delegate Devcoin
    function delegateDevcoin() {
        // delegate Devcoin to successor contract (solution main contract) to use as stake in calculating the owner's access to profits of the solution
    }

    // delegate Devcoin
    function delegateDevcoin() {
        // delegate Devcoin to successor contract to use as stake in calculating the access to profits of the solution
    }    
}