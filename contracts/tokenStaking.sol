// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/IERC20.sol";


contract stakeEther {
    address owner;
    address tokenAddress;
    uint public contractBalance = address(this).balance;

    struct User {
        uint256 userReward;
        uint256 stakeTime;
        uint256 unlockTime;
    }

    mapping(address => User) stake;
    mapping(address => uint) public stakeAmount;

    error unlockTimeNotReached();
    error insufficientFunds();

    // Events
    event DepositSuccessful(address, uint);
    event WithdrawSuccessfull(address, uint);




    constructor(address _tokenAddress) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
    }

    function calculateReward(uint _days) internal view  returns(uint256) {
        uint256 userStake = stakeAmount[msg.sender];
        uint256 dailyPercentage = (userStake * 10) / 100;   // 10 percent daily on staked amount
        uint256 userReward = dailyPercentage * _days;
        return userReward;
    }

    function depositStake(uint _days, uint _amount) external payable {
        require(msg.value > 0, "Cannot send zero ETH");

        uint userBalance = IERC20(tokenAddress).balanceOf(msg.sender);

        if(userBalance < _amount) {
            revert insufficientFunds();
        }

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount);

        contractBalance += _amount;

        stakeAmount[msg.sender] += _amount;
        uint _unlockTime = block.timestamp + (_days * 24 * 60 * 60);

        uint reward = calculateReward(_days);
        stake[msg.sender] = User({ userReward: reward, stakeTime: block.timestamp, unlockTime: _unlockTime  });
        emit DepositSuccessful(msg.sender, _amount);
    }

    function withdrawStakeReward() external payable {
        if(stake[msg.sender].unlockTime < block.timestamp) {
            revert unlockTimeNotReached();
        }
        uint withdrawReward = stake[msg.sender].userReward;
        stake[msg.sender].userReward = 0;

        IERC20(tokenAddress).transfer(msg.sender, withdrawReward);

    }

    function withdrawStakeAndReward() external payable {
        if(stake[msg.sender].unlockTime < block.timestamp) {
            revert unlockTimeNotReached();
        }

        uint withdrawAmount = stakeAmount[msg.sender] + stake[msg.sender].userReward;
        stakeAmount[msg.sender] = 0;

        stake[msg.sender].userReward = 0;
        contractBalance -= withdrawAmount;

        IERC20(tokenAddress).transfer(msg.sender, withdrawAmount);
        emit WithdrawSuccessfull(msg.sender, withdrawAmount);
 
    }

    // Emergency withdrawal of funds before unlocktime attract 20 percent reduction in stake and no reward
    function withdrawEmergency() external  {
         if(stake[msg.sender].unlockTime < block.timestamp) {
            uint stakeValue =  stakeAmount[msg.sender];
            uint reduction = (stakeValue * 20) * 100;

            // 20 percent reduction from user stake amount
            stakeAmount[msg.sender] -= reduction;
            uint amountToSend = stakeValue - reduction;

            IERC20(tokenAddress).transfer(msg.sender, amountToSend);
        }

    }

} 