// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


contract stakeEther {
    address owner;
    uint public contractBalance = address(this).balance;

    struct User {
        uint256 userReward;
        uint256 stakeTime;
        uint256 unlockTime;
    }

    mapping(address => User) stake;
    mapping(address => uint) public stakeAmount;

    error unlockTimeNotReached();

    // Events
    event DepositSuccessful(address, uint);
    event WithdrawSuccessfull(address, uint);




    constructor() {
        owner = msg.sender;
    }

    function calculateReward(uint _days) internal view  returns(uint256) {
        uint256 userStake = stakeAmount[msg.sender];
        uint256 dailyPercentage = (userStake * 10) / 100;   // 10 percent daily on staked amount
        uint256 userReward = dailyPercentage * _days;
        return userReward;
    }

    function depositStake(uint _days) external payable {
        require(msg.value > 0, "Cannot send zero ETH");
        contractBalance += msg.value;

        stakeAmount[msg.sender] += msg.value;
        uint _unlockTime = block.timestamp + (_days * 24 * 60 * 60);

        uint reward = calculateReward(_days);
        stake[msg.sender] = User({ userReward: reward, stakeTime: block.timestamp, unlockTime: _unlockTime  });
        emit DepositSuccessful(msg.sender, msg.value);
    }

    function withdrawStakeReward() external payable {
        if(stake[msg.sender].unlockTime < block.timestamp) {
            revert unlockTimeNotReached();
        }
        uint withdrawReward = stake[msg.sender].userReward;
        stake[msg.sender].userReward = 0;

        (bool success,) = msg.sender.call{ value: withdrawReward }("");
        require(success);

    }

    function withdrawStakeAndReward() external payable {
        if(stake[msg.sender].unlockTime < block.timestamp) {
            revert unlockTimeNotReached();
        }

        uint withdrawAmount = stakeAmount[msg.sender] + stake[msg.sender].userReward;
        stakeAmount[msg.sender] = 0;

        stake[msg.sender].userReward = 0;
        contractBalance -= withdrawAmount;

        (bool success, ) = msg.sender.call{ value: withdrawAmount }("");
        require(success);

        emit WithdrawSuccessfull(msg.sender, withdrawAmount);
 
    }

    // Emergency withdrawal of funds before unlocktime attract 20 percent reduction in stake and no reward
    function withdrawEmergency() external  {
         if(stake[msg.sender].unlockTime < block.timestamp) {
            uint stakeValue =  stakeAmount[msg.sender];
            uint reduction = (stakeValue * 20) * 100;

            stakeAmount[msg.sender] -= reduction;
            uint amountToSend = stakeValue - reduction;

            (bool success,) = msg.sender.call{ value: amountToSend }("");
            require(success);
        }

    }


} 