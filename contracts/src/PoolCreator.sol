// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "../lib/deposit_contract.sol";


struct Pool {
    address[] friends;
    uint256[] shares;
    bool[] deposited;
    uint256 numDeposited;
    bool isFinalized;
    address rewardSplitter;
}

contract PoolCreator {

    uint256 public numPools;
    mapping(uint256 => Pool) private pools;

    IDepositContract depositContract;
    address rugpuller;

    error InvalidFriends();
    error InvalidShares();
    error CallerNotFirstFriend();
    error WrongDepositAmount();
    error InvalidPoolIndex();
    error InvalidFriend();
    error DepositorNotFriend();
    error InvalidDepositAmount();
    error MissingDeposits();
    error AlreadyDeposited();
    error AlreadyFinalized();

    event PoolCreated(uint256 index, address rewardSplitter);
    event Deposited(uint256 index, uint256 friend);
    event PoolFinalized(uint256 index);

    constructor(IDepositContract depositContract_) {
        depositContract = depositContract_;
        rugpuller = msg.sender;
    }

    function getPool(uint256 poolIndex) public view returns (Pool memory) {
        return pools[poolIndex];
    }

    function setupPool(address[] calldata friends, uint256[] calldata shares) external payable {
        if (friends.length < 2) {
            revert InvalidFriends();
        }

        if (shares.length != friends.length) {
            revert InvalidShares();
        }
        uint256 totalShares = 0;
        for (uint256 i = 0; i < shares.length; i++) {
            if (shares[i] == 0) {
                revert InvalidShares();
            }
            totalShares += shares[i];
        }
        if (totalShares != 32 ether) {
            revert InvalidShares();
        }

        if (msg.sender != friends[0]) {
            revert CallerNotFirstFriend();
        }
        if (msg.value != shares[0]) {
            revert WrongDepositAmount();
        }

        bool[] memory deposited = new bool[](friends.length);
        deposited[0] = true;

        PaymentSplitter rewardSplitter = new PaymentSplitter(friends, shares);

        Pool memory pool = Pool({
            friends: friends,
            shares: shares,
            deposited: deposited,
            numDeposited: 1,
            isFinalized: false,
            rewardSplitter: address(rewardSplitter)
        });
        pools[numPools] = pool;
        numPools += 1;

        emit PoolCreated(numPools - 1, address(rewardSplitter));
    }

    function deposit(uint256 poolIndex, uint256 friend) external payable {
        if (poolIndex >= numPools) {
            revert InvalidPoolIndex();
        }
        Pool storage pool = pools[poolIndex];
        if (friend >= pool.friends.length) {
            revert InvalidFriend();
        }
        if (msg.sender != pool.friends[friend]) {
            revert DepositorNotFriend();
        }
        if (msg.value != pool.shares[friend]) {
            revert InvalidDepositAmount();
        }
        if (pool.deposited[friend]) {
            revert AlreadyDeposited();
        }

        pools[poolIndex].deposited[friend] = true;
        pools[poolIndex].numDeposited += 1;
        emit Deposited(poolIndex, friend);
    }

    function finalizePool(uint256 poolIndex, bytes calldata pubkey, bytes calldata signature, bytes32 depositDataRoot) external payable {
        if (poolIndex >= numPools) {
            revert InvalidPoolIndex();
        }
        Pool memory pool = pools[poolIndex];
        if (msg.sender != pool.friends[0]) {
            revert CallerNotFirstFriend();
        }
        if (pool.numDeposited < pool.friends.length) {
            revert MissingDeposits();
        }
        if (pool.isFinalized) {
            revert AlreadyFinalized();
        }
        pools[poolIndex].isFinalized = true;
        bytes memory withdrawalCredentials = bytes.concat(
            bytes1(0x01),
            bytes11(0),
            bytes20(address(pool.rewardSplitter))
        );
        depositContract.deposit{value: 32 ether}(
            pubkey,
            withdrawalCredentials,
            signature,
            depositDataRoot
        );
        emit PoolFinalized(poolIndex);
    }

    function rugpull() external {
        // for debugging, in case we get precious goerli ETH stuck here
        require(msg.sender == rugpuller);
        msg.sender.call{value: address(this).balance}("");
    }
}

contract FakeDepositContract {

    address rugpuller;

    constructor() {
        rugpuller = msg.sender;
    }

    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable {

    }

    function rugpull() external {
        // for debugging, in case we get previous goerli ETH stuck here
        require(msg.sender == rugpuller);
        msg.sender.call{value: address(this).balance}("");
    }
}
