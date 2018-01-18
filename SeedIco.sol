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
- 


Testnet --> ROPSTEN:
- put information here


contract SeedIco {

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