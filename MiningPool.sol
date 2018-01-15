pragma solidity ^0.4.18;

/**
FEATURES:
- Customers can deposit a sum of ETH which is forwarded to the mining pool automatically
- Interestrate is calculated automatically so customers can keep track of their balance.
- Customers can request withdrawals
- Mining pool can automatically payout the requested withdrawals
- Balances are public for transparency reasons
- Withdrawal Requests and Amounts are public for trust and transparancy reasons

ROPSTEN:
0x28e89Bd7c11Ac7E56d36BFEab46E2d48725B2Fba
ABI:
[{"constant":true,"inputs":[],"name":"pool","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[],"name":"withdraw","outputs":[],"payable":true,"stateMutability":"payable","type":"function"},{"constant":true,"inputs":[{"name":"_address","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"getRequestValue","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"","type":"uint256"}],"name":"withdrawalRequests","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_amountWei","type":"uint256"}],"name":"requestWithdrawal","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"interest","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"withdrawalAmount","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"inputs":[{"name":"_pool","type":"address"},{"name":"_interest","type":"uint256"}],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"payable":true,"stateMutability":"payable","type":"fallback"}]


TODO:
- case when withdrawal pays to a smart contract
- check potential security issues
- check for bugs
- implement onlyContract
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

contract MiningPool {

    // Use SafeMath library for uint256 arithmetics
    using SafeMath for uint256;

    // Address of owner
    address public owner;
    // Address of pool
    address public pool;
    // Keeps track of users balances
    mapping(address => uint256) internal balances;
    // Keeps track of last updated price
    mapping(address => uint256) internal lastTime;
    // Keeps track of last deposit time. You cannot withdraw for 24 hours after a deposit was made.
    mapping(address => uint256) internal lastDeposit;
    // Array of withdrawal requests
    address[] public withdrawalRequests;
    // Keeps track of index of withdrawal
    mapping(address => int256) internal withdrawalIndex;
    // Keeps track of withdrawal amounts
    mapping(address => uint256) public withdrawalAmount;
    // Interest Rate per day /1,000,000
    uint256 public interest = 54;
    
    // Constructor
    function MiningPool(address _pool, uint256 _interest) public {
        owner = msg.sender;
        pool = _pool;
        interest = _interest;
    }

    // Modifier: only allows Owner/Pool/Contract to call certain functions
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier onlyPool {
        require(msg.sender == pool);
        _;
    }
    modifier onlyContract {
        require(msg.sender == address(this));
        _;
    }

    // Deposit
    function () public payable {
        // Updates Balance to latest interest rate
        updateBalance(msg.sender);
        // Adds amount to users balance and sends balance to pool
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        lastDeposit[msg.sender] = now;
        pool.transfer(msg.value);
    }

    function requestWithdrawal(uint256 _amountWei) public {
        // Updates Balance to latest interest rate
        updateBalance(msg.sender);
        // Amount (with previously requested amounts) has to be less than balance and greater than 0
        require((_amountWei.add(withdrawalAmount[msg.sender])) < balances[msg.sender] && _amountWei > 0);
        // Checks if a deposit was made in the last 24 hours
        require((now.sub(lastDeposit[msg.sender]) > (1 days)));

        // Checks if a withdrawal request already has been made
        // If it hasn't been added yet, add it to the array, save its index and increase the amount,
        // If it has been added just increase the amount
        if (withdrawalAmount[msg.sender] > 0) {
            withdrawalAmount[msg.sender] = withdrawalAmount[msg.sender].add(_amountWei);
        } else {
            withdrawalRequests.push(msg.sender);
            withdrawalIndex[msg.sender] = int(withdrawalRequests.length - 1);
            withdrawalAmount[msg.sender] = withdrawalAmount[msg.sender].add(_amountWei);
        }
    }

    // Gets value of all requested withdrawals
    function getRequestValue() public view returns(uint256) {
        uint256 amount = 0;
        for (uint256 i = 0; i < withdrawalRequests.length; i++) {
            amount = amount.add(withdrawalAmount[withdrawalRequests[i]]);
        }
        return amount;
    }

    // Pay out withdrawals, funds need to be included in the function
    function withdraw() public payable onlyPool {
        for (uint256 i = 0; i < withdrawalRequests.length; i++) {
            withdrawalRequests[i].send(withdrawalAmount[withdrawalRequests[i]]);
            withdrawalAmount[withdrawalRequests[i]] = 0;
            withdrawalIndex[withdrawalRequests[i]] = -1;
        }
        // Empty array after payout
        withdrawalRequests.length = 0;
    }

    // Function to update balance with interest
    function updateBalance(address _address) internal {
        if (balances[_address] > 0) {
            // Uhecks if balance has been updated in more than one day
            if ((now.sub(lastTime[_address]) > (1 days))) {
                // Updates balance with calculated interest
                uint256 _days = lastTime[_address] / (1 days);
                lastTime[_address] = now;
                balances[_address] = calcInterest(balances[_address], _days);
            }
        } else {
            lastTime[_address] = now;
        }
    }

    // View: returns the latest balance with interest
    function balanceOf(address _address) view public returns (uint256) {
        // Checks if balance has been updated in more than one day
        if ((now.sub(lastTime[_address]) > (1 days))) {
            // Updates balance with calculated interest
            uint256 _days = lastTime[_address] / (1 days);
            return calcInterest(balances[_address], _days);
        } else {
            return balances[_address];
        }
    }

    // Pure function: calculates interest for n days
    function calcInterest(uint256 _value, uint256 _days) internal view returns (uint256) {
        require(_days > 0);
        uint256 value = _value;
        for (uint256 i = 0; i < _days; i++) {
            value += value * interest/1000000;
        }
        assert(value > _value);
        return value;
    }
}