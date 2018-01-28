pragma solidity ^0.4.18;

/**
TODO:
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


// Basic ERC20 functions
contract ERC20 {

    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // mapping of all balances
    mapping (address => uint256) public balanceOf;
    // mapping of spending allowances
    mapping (address => mapping (address => uint256)) public allowance;
    // The total supply of the token
    uint256 public totalSupply;

    // Some variables for nice wallet integration
    string public name;          // name of token
    string public symbol;        // symbol of token
    uint8 public decimals;       // decimals of token

    // constructor setting token variables
    function ERC20() {
        name = "DevToken";
        symbol = "DT";
        decimals = 18;
        totalSupply = 0;
    }

    // send tokens
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != 0x0);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    // transfer tokens with allowances
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != 0x0);
        balanceOf[_to] = balanceOf[_to].add(_value);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    // approve that others can transfer _value tokens for the msg.sender
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

// DevToken functions which are active during development phase
contract DevToken is ERC20 {

    // TODO: implement exchange rate, shouldn't be changable via voting function

    // maximum supply of the token
    uint256 public maxSupply;
    // time since the last emergency withdrawal
    uint256 public emergencyWithdrawal;
    // maximum stake someone can have of all tokens (in percent)
    uint256 public maxStake;
    // the maximum amount someone can deposit before the stake percentage starts to count
    // TODO: possible security risk? If someone in the beginning gets to more than 50% he can manipulate all variables during voting
    uint256 public maxSimpleInvestment;
    // address of the developers
    address public devs;

    // constructor setting contract variables
    function SeedICO(uint256 _maxSupply, uint256 _maxStake, uint256 _maxSimpleInvestment, address _devs) {
        emergencyWithdrawal = now;
        maxSupply = _maxSupply;
        maxStake = _maxStake;
        maxSimpleInvestment = _maxSimpleInvestment;
        devs = _devs;
    }

    // modifiers: only allows Owner/Pool/Contract to call certain functions
    modifier onlyDev {
        require(msg.sender == devs);
        _;
    }

    // lock ETH in contract and return DevTokens
    function () public payable {
        // adds the amount of ETH sent as DevToken value and increases total supply
        balanceOf[msg.sender].add(msg.value);
        totalSupply = totalSupply.add(msg.value);

        // fails if total supply surpasses maximum supply
        require(totalSupply < maxSupply);
        // up to 5 Ethers can be deposited
        if (balanceOf[msg.sender] > maxSimpleInvestment) {
            // If user wants to deposit more than 5 Ether, he cannot deposit more than X% of the total supply
            require(balanceOf[msg.sender] < totalSupply.mul(maxStake)/100);
        }
        // transfer event
        Transfer(address(this), msg.sender, msg.value);
    }

    // allows devs to withdraw 1 ether per week in case of an emergency or a malicous attack that prevents developers to access ETH in the contract at all
    function emergencyWithdraw() public onlyDev {
        if (now.sub(emergencyWithdrawal) > 7 days) {
            emergencyWithdrawal = now;
            devs.transfer(1 ether);
        }
    }
}

// voting implementation of DevToken contract
contract VotingContract is DevToken {
    // TODO: commenting
    struct Voting {
        string name;
        bool running;
        uint256 parameter;
        mapping(address => uint256) voted;
    }

    Voting maxSupplyVoting;
    Voting maxStakeVoting;
    Voting maxSimpleInvestmentVoting;

    function VotingContract() {
        maxSupplyVoting = Voting({name: "maxSupply", running: false, parameter: 0});
        maxStakeVoting = Voting({name: "maxStake", running: false, parameter: 0});
        maxSimpleInvestmentVoting = Voting({name: "maxSimpleInvestment", running: false, parameter: 0});
    }

    function startVoting() {}
    function Vote() {}
    function endVote() {}

}

// RevToken functions which are active after development phase
contract RevToken is ERC20 {
    // TODO
}

// DevRevToken combines DevToken and RevToken into one token
contract DevRevToken is VotingContract, RevToken {

}