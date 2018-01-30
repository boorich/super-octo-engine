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
    function transfer(address _to, uint256 _value) public {
        // necessary?
        require(_to != 0x0);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(msg.sender, _to, _value);
    }
    // transfer tokens with allowances
    function transferFrom(address _from, address _to, uint256 _value) public {
        require(_to != 0x0);
        balanceOf[_to] = balanceOf[_to].add(_value);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
    }

    // approve that others can transfer _value tokens for the msg.sender
    function approve(address _spender, uint256 _value) public {
        require((_value == 0) || (allowance[msg.sender][_spender] == 0));
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }
    
    function increaseApproval(address _spender, uint _addedValue) public {
        allowance[msg.sender][_spender] = allowance[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
    }
    
    function decreaseApproval(address _spender, uint _subtractedValue) public {
        uint oldValue = allowance[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowance[msg.sender][_spender] = 0;
        } else {
            allowance[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
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
    // TODO: blacklisted accounts
    mapping(address => bool) blacklist;

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
    // constant function: return maximum possible investment per person
    function maxInvestment() public view returns(uint256) {
        if (totalSupply.mul(maxStake)/100 > maxSimpleInvestment) {
            return totalSupply.mul(maxStake)/100;
        } else {
            return maxSimpleInvestment;
        }
    }

}

// voting implementation of DevToken contract
contract Voting is DevToken {
    // TODO: Implement minimum/maximum in voting interface (e.g. so maxSupply cannot be set lower than totalSupply)
    struct Poll {
        // name of poll
        string name;
        // bool if poll is currently running 
        bool running;
        // bool if the poll is a yes/no poll
        bool boolVote;
        // range of values acceptable in poll
        // when there is no need to define a range, then range = []
        // when the poll is a yes/no poll the range is [0,1], 0 is no, 1 is yes
        int256[] range;
        // time since last poll started
        uint256 lastPoll;
        // duration of current poll
        uint256 pollDuration;
        // TODO
        uint256 parameter;
        // mapping that saves timestamp of last user vote
        mapping(address => uint256) lastVote;
    }

    // array of polls
    Poll[] public polls;

    // constructor: saving all possible votes
    function VotingContract() {
        polls.push(Voting({name: "maxSupply", running: false, boolVote: false, range: [], lastPoll: 0, pollDuration: 0, parameter: 0}));
        polls.push(Voting({name: "maxStake", running: false, boolVote: false, range: [10,49], lastPoll: 0, pollDuration: 0, parameter: 0}));
        polls.push(Voting({name: "maxSimpleInvestment", running: false, boolVote: false, range: [1,50], lastPoll: 0, pollDuration: 0, parameter: 0}));
        polls.push(Voting({name: "finishDevelopment", running: false, boolVote: true, range: [0,1], lastPoll: 0, pollDuration: 0, parameter:0}));
    }

    // start of a new poll, takes poll.name as an input argument
    function startVoting(string _name) public {
        // iterates through all polls
        for (uint256 i = 0; i < polls.length; i++) {
            // gets the poll whose name is equal to the input parameter _name
            if (polls[i].name == _name) {
                // requires polls.running to be false
                require(!polls[i].running);
                // allows one poll of a kind in 4 weeks
                require(now.sub(lastPoll) > 4 weeks);
                // resets last poll timestamp
                polls[i].lastPoll = now;
                // resets poll duration timestamp
                polls[i].pollDuration = now;
                polls[i].running = true;
            }
            // breaks loop to save gas
            break;
        }
    }

    // TODO: implement voting count
    function Vote(string _name, uint256 _vote) public {
        for (uint256 i = 0; i < polls.length; i++) {
            if (polls[i].name == _name) {
                require(polls[i].running);
                // if poll is running for longer than 1 week, the poll ends
                if (now.sub(polls[i].pollDuration) > 1 weeks) {
                    endVote(_name);
                } else {
                    // the last vote of msg.sender has to be longer than 8 days (-> msg.sender can only vote once per poll)
                    require(now.sub(polls[i].lastVote[msg.sender]) > 8 days);
                    // checks if vote has range
                    if (polls[i].range.length == 0) {

                    } else {

                    }
                }
            }
            break;
        }
    }

    // TODO; setting variables after votes have finished
    function endVote(string _name) public {
        // iterates through all polls
        for (uint256 i = 0; i < polls.length; i++) {
            // gets the poll whose name is equal to the input parameter _name
            if (polls[i].name == _name) {
                // requires polls.running to be true
                require(polls[i].running);
                // poll ends after 1 week
                require(now.sub(polls[i].pollDuration) > 1 weeks);
                polls[i].running = false;
            }
            // breaks loop to save gas
            break;
        }
    }


    // constant function: returns all current running polls in a string array
    function runningVotes() public view returns(string[]) {
        string[] activePolls;
        for (uint256 i = 0; i < polls.length; i++) {
            if (polls[i].running) {
                if (now.sub(polls[i].pollDuration) < 1 weeks) {
                    activePolls.push(polls[i].name);
                }
            }
        }
        return activePolls;
    }

}

// RevToken functions which are active after development phase
contract RevToken is ERC20 {
    // TODO
}

// DevRevToken combines DevToken and RevToken into one token
contract DevRevToken is Voting, RevToken {

}