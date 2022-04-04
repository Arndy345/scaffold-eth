// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  event Stake(address, uint256);

  ExampleExternalContract public exampleExternalContract;
  mapping (address => uint256) public balances;
  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 72 hours;
  bool public openForWithdraw;

  modifier notCompleted() {
    require(!exampleExternalContract.completed(), "The stake is already completed");
    _;
  }
   modifier deadlinePassed(bool requireDeadlinePassed) {
    uint256 timeRemaining = timeLeft();
    if (requireDeadlinePassed) {
      require(timeRemaining <= 0, "Deadline has not been passed yet");
    } else {
      require(timeRemaining > 0, "Deadline is already passed");
    }
    _;
  }

  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable {
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  function execute() public notCompleted {
    require(block.timestamp >= deadline, "Deadline exceeded");
   
      if (address(this).balance >= threshold) {
        // It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
        exampleExternalContract.complete{value: address(this).balance}();
      } else {
        // if the `threshold` was not met, allow everyone to call a `withdraw()` function
        openForWithdraw = true;
      }
    
  }

  // Add a `withdraw(address payable)` function lets users withdraw their balance
  function withdraw() public payable notCompleted  {
    require(openForWithdraw && balances[msg.sender]>0);
    uint256 userBalance = balances[msg.sender];
      // reset the sender's balance
      balances[msg.sender] = 0;
      (bool sent, ) = payable(msg.sender).call{value: userBalance}("");
        require(sent, "Failed to send Ether");
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    if (block.timestamp >= deadline) {
      return 0;
    }
    return deadline - block.timestamp;
  }


  //Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    stake();
  }
}