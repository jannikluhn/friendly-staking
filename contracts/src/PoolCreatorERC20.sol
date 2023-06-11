// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "../lib/deposit_contract_erc20.sol";
import "../lib/IERC677Receiver.sol";


struct Pool {
    address[] friends;
    uint256[] shares;
    bool[] deposited;
    uint256 numDeposited;
    bool isFinalized;
    address rewardSplitter;
}

contract PoolCreatorERC20 is IERC677Receiver {

    uint256 public numPools;
    mapping(uint256 => Pool) private pools;

    IDepositContract depositContract;

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
    error InvalidTokenTransferCall();

    event PoolCreated(uint256 index, address rewardSplitter);
    event Deposited(uint256 index, uint256 friend);
    event PoolFinalized(uint256 index);

    constructor(IDepositContract depositContract_) {
        depositContract = depositContract_;
        depositContract.stake_token().approve(address(depositContract), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    }

    function getPool(uint256 poolIndex) public view returns (Pool memory) {
        return pools[poolIndex];
    }

    function onTokenTransfer(address from, uint256 value, bytes calldata data) external returns (bool) {
        if (data.length == 0) {
            revert InvalidTokenTransferCall();
        }
        if (data[0] == 0x00) {
            (address[] memory friends, uint256[] memory shares) = abi.decode(data[1:], (address[], uint256[]));
            _setupPool(friends, shares, from, value);
        } else if (data[0] == 0x01) {
            (uint256 poolIndex, uint256 friend) = abi.decode(data[1:], (uint256, uint256));
            _deposit(poolIndex, friend, from, value);
        } else {
            revert InvalidTokenTransferCall();
        }
        return true;
    }

    function _setupPool(address[] memory friends, uint256[] memory shares, address from, uint256 value) internal {
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
        if (totalShares != 1 ether) {
            revert InvalidShares();
        }

        if (from != friends[0]) {
            revert CallerNotFirstFriend();
        }
        if (value != shares[0]) {
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

    function _deposit(uint256 poolIndex, uint256 friend, address from, uint256 value) internal {
        if (poolIndex >= numPools) {
            revert InvalidPoolIndex();
        }
        Pool storage pool = pools[poolIndex];
        if (friend >= pool.friends.length) {
            revert InvalidFriend();
        }
        if (from != pool.friends[friend]) {
            revert DepositorNotFriend();
        }
        if (value != pool.shares[friend]) {
            revert InvalidDepositAmount();
        }
        if (pool.deposited[friend]) {
            revert AlreadyDeposited();
        }

        pools[poolIndex].deposited[friend] = true;
        pools[poolIndex].numDeposited += 1;
        emit Deposited(poolIndex, friend);
    }

    function finalizePool(uint256 poolIndex, bytes calldata pubkey, bytes calldata signature, bytes32 depositDataRoot) external {
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
        depositContract.deposit(
            pubkey,
            withdrawalCredentials,
            signature,
            depositDataRoot,
            1 ether
        );
        emit PoolFinalized(poolIndex);
    }
}
