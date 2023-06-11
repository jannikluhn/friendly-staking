// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./interfaces/IDepositContract.sol";
import "./interfaces/IERC677Receiver.sol";
import "./interfaces/IUnwrapper.sol";
import "./interfaces/IWithdrawalContract.sol";
import "./utils/PausableEIP1967Admin.sol";
import "./utils/Claimable.sol";

/**
 * @title SBCDepositContract
 * @dev Implementation of the ERC20 ETH2.0 deposit contract.
 * For the original implementation, see the Phase 0 specification under https://github.com/ethereum/eth2.0-specs
 */
contract SBCDepositContract is
    IDepositContract,
    IERC165,
    IERC677Receiver,
    PausableEIP1967Admin,
    Claimable,
    IWithdrawalContract
{
    using SafeERC20 for IERC20;

    uint256 private constant DEPOSIT_CONTRACT_TREE_DEPTH = 32;
    // NOTE: this also ensures `deposit_count` will fit into 64-bits
    uint256 private constant MAX_DEPOSIT_COUNT = 2 ** DEPOSIT_CONTRACT_TREE_DEPTH - 1;

    bytes32[DEPOSIT_CONTRACT_TREE_DEPTH] private zero_hashes;

    bytes32[DEPOSIT_CONTRACT_TREE_DEPTH] private branch;
    uint256 private deposit_count;

    mapping(bytes => bytes32) public validator_withdrawal_credentials;

    IERC20 public immutable stake_token;

    constructor(address _token) {
        stake_token = IERC20(_token);
    }

    function get_deposit_root() external view override returns (bytes32) {
    }

    function get_deposit_count() external view override returns (bytes memory) {
    }

    function deposit(
        bytes memory pubkey,
        bytes memory withdrawal_credentials,
        bytes memory signature,
        bytes32 deposit_data_root,
        uint256 stake_amount
    ) external override whenNotPaused {
        stake_token.transferFrom(msg.sender, address(this), stake_amount);
        _deposit(pubkey, withdrawal_credentials, signature, deposit_data_root, stake_amount);
    }

    function batchDeposit(
        bytes calldata pubkeys,
        bytes calldata withdrawal_credentials,
        bytes calldata signatures,
        bytes32[] calldata deposit_data_roots
    ) external whenNotPaused {
    }

    function onTokenTransfer(
        address,
        uint256 stake_amount,
        bytes calldata data
    ) external override whenNotPaused returns (bool) {
        require(msg.sender == address(stake_token), "DepositContract: not a deposit token");
        require(data.length % 176 == 32, "DepositContract: incorrect deposit data length");
        uint256 count = data.length / 176;
        require(count > 0, "BatchDeposit: You should deposit at least one validator");
        uint256 stake_amount_per_deposit = stake_amount;
        if (count > 1) {
            require(count <= 128, "BatchDeposit: You can deposit max 128 validators at a time");
            require(stake_amount == 1 ether * count, "BatchDeposit: batch deposits require 1 GNO deposit amount");
            stake_amount_per_deposit = 1 ether;
        }

        bytes memory withdrawal_credentials = data[0:32];
        for (uint256 p = 32; p < data.length; p += 176) {
            bytes memory pubkey = data[p:p + 48];
            bytes memory signature = data[p + 48:p + 144];
            bytes32 deposit_data_root = bytes32(data[p + 144:p + 176]);
            _deposit(pubkey, withdrawal_credentials, signature, deposit_data_root, stake_amount_per_deposit);
        }
        return true;
    }

    function _deposit(
        bytes memory pubkey,
        bytes memory withdrawal_credentials,
        bytes memory signature,
        bytes32 deposit_data_root,
        uint256 stake_amount
    ) internal {
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IDepositContract).interfaceId ||
            interfaceId == type(IERC677Receiver).interfaceId;
    }

    /**
     * @dev Allows to transfer any locked token from this contract.
     * Only admin can call this method.
     * Deposit-related tokens cannot be claimed.
     * @param _token address of the token, if it is not provided (0x00..00), native coins will be transferred.
     * @param _to address that will receive the locked tokens from this contract.
     */
    function claimTokens(address _token, address _to) external onlyAdmin {
    }

    function to_little_endian_64(uint64 value) internal pure returns (bytes memory ret) {
        ret = new bytes(8);
        bytes8 bytesValue = bytes8(value);
        // Byteswapping during copying to bytes.
        ret[0] = bytesValue[7];
        ret[1] = bytesValue[6];
        ret[2] = bytesValue[5];
        ret[3] = bytesValue[4];
        ret[4] = bytesValue[3];
        ret[5] = bytesValue[2];
        ret[6] = bytesValue[1];
        ret[7] = bytesValue[0];
    }

    /*** Withdrawal part ***/

    address private constant SYSTEM_WITHDRAWAL_EXECUTOR = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;

    uint256 private constant DEFAULT_GAS_PER_WITHDRAWAL = 300000;

    /**
     * @dev Function to be used to process a withdrawal.
     * Actually it is an internal function, only this contract can call it.
     * This is done in order to roll back all changes in case of revert.
     * @param _amount Amount to be withdrawn.
     * @param _receiver Receiver of the withdrawal.
     */
    function processWithdrawalInternal(uint256 _amount, address _receiver) external {
    }

    /**
     * @dev Internal function to be used to process a withdrawal.
     * Uses processWithdrawalInternal under the hood.
     * Call to this function will revert only if it ran out of gas.
     * @param _amount Amount to be withdrawn.
     * @param _receiver Receiver of the withdrawal.
     * @return success An indicator of whether the withdrawal was successful or not.
     */
    function _processWithdrawal(uint256 _amount, address _receiver, uint256 gasLimit) internal returns (bool success) {
    }

    struct FailedWithdrawalRecord {
        uint256 amount;
        address receiver;
        uint64 withdrawalIndex;
    }
    mapping(uint256 => FailedWithdrawalRecord) public failedWithdrawals;
    mapping(uint64 => uint256) public failedWithdrawalIndexByWithdrawalIndex;
    uint256 public numberOfFailedWithdrawals;
    uint64 public nextWithdrawalIndex;

    /**
     * @dev Function to be used to process a failed withdrawal (possibly partially).
     * @param _failedWithdrawalId Id of a failed withdrawal.
     * @param _amountToProceed Amount of token to withdraw (for the case it is impossible to withdraw the full amount)
     * (available only for the receiver, will be ignored if other account tries to process the withdrawal).
     */
    function processFailedWithdrawal(uint256 _failedWithdrawalId, uint256 _amountToProceed) external whenNotPaused {
    }

    uint256 public failedWithdrawalsPointer;

    /**
     * @dev Function to be used to process failed withdrawals.
     * Call to this function will revert only if it ran out of gas or it is a reentrant access to failed withdrawals processing.
     * Call to this function doesn't transmit flow control to any untrusted contract and uses a constant gas limit for each withdrawal,
     * so using constant gas limit and constant max number of withdrawals for calls of this function is ok.
     * @param _maxNumberOfFailedWithdrawalsToProcess Maximum number of failed withdrawals to be processed.
     */
    function processFailedWithdrawalsFromPointer(uint256 _maxNumberOfFailedWithdrawalsToProcess) public {
    }

    /**
     * @dev Function to be used only in the system transaction.
     * Call to this function will revert only in three cases:
     *     - the caller is not `SYSTEM_WITHDRAWAL_EXECUTOR` or `_admin()`;
     *     - the length of `_amounts` array is not equal to the length of `_addresses` array;
     *     - it is a reentrant access to failed withdrawals processing;
     *     - the call ran out of gas.
     * Call to this function doesn't transmit flow control to any untrusted contract and uses a constant gas limit for each withdrawal,
     * so using constant gas limit and constant number of withdrawals (including failed withdrawals) for calls of this function is ok.
     * @param _maxNumberOfFailedWithdrawalsToProcess Maximum number of failed withdrawals to be processed.
     * @param _amounts Array of amounts to be withdrawn.
     * @param _addresses Array of addresses that should receive the corresponding amount of tokens.
     */
    function executeSystemWithdrawals(
        uint256 _maxNumberOfFailedWithdrawalsToProcess,
        uint64[] calldata _amounts,
        address[] calldata _addresses
    ) external {
    }

    /**
     * @dev Check if a block's withdrawal has been fully processed or not
     * @param _withdrawalIndex EIP-4895 withdrawal.index property
     */
    function isWithdrawalProcessed(uint64 _withdrawalIndex) external view returns (bool) {
    }

    /**
     * @dev Allows to unwrap the mGNO in this contract to GNO
     * Only admin can call this method.
     * @param _unwrapper address of the mGNO token unwrapper
     */
    function unwrapTokens(IUnwrapper _unwrapper, IERC20 _token) external onlyAdmin {
    }
}
