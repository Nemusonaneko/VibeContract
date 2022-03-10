// contracts/VibeDeposit.sol
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TransferHelper.sol";

error NotAReceiver();
error AmountWithdrawnHigherThanExistingBalance();
error AlreadyAReceiver();
error ReceiverDoesNotExist();
error TransferAmountHigherThanBalance();
error DepositsDisabled();

/// @author nemusona
/// @title Vibe contract
/// Are my ancestors proud of me?
contract VibeDeposit {
    /// @notice using TransferHelper for safe transfers
    using TransferHelper for address;

    /// @notice Deposit token
    IERC20 public token;

    /// @notice Array for receivers
    address[] public receiverArray;

    /// @notice events
    event Deposit(address indexed _from, uint256 _amount);
    event Withdraw(address indexed _from, uint256 _amount);
    event ToggleDeposits(address indexed _from, bool _acceptDeposits);
    event BecomeReceiver(address indexed _from);
    event TransferToReceiver(
        address indexed _from,
        address indexed _to,
        uint256 _amount
    );

    /// @notice Struct for receiver of tokens which stores balance, seconds per token and checks if they exist
    struct Receiver {
        /// @notice Balance to be withdrawn
        uint256 balance;
        /// @notice receiver is valid
        bool valid;
        /// @notice receiver accepting deposits
        bool acceptDeposits;
    }

    /// @notice maps Receiver Struct for receiver of token to withdraw
    mapping(address => Receiver) public receivers;
    /// @notice maps balance for depositor to use on the receiver
    mapping(address => uint256) public depositors;

    constructor(IERC20 _token) {
        token = _token;
    }

    /// @notice returns an array of Receivers
    function getAllReceivers() external view returns (Receiver[] memory) {
        uint256 len = receiverArray.length;
        Receiver[] memory r = new Receiver[](len);
        for (uint256 i; i < len; i++) {
            r[i] = receivers[receiverArray[i]];
        }
        return r;
    }

    /// @notice returns all receiver addresses
    function receiverAddresses() external view returns (address[] memory) {
        return receiverArray;
    }

    /// @notice deposit function
    function deposit(uint256 _amount) external {
        address(token).safeTransferFrom(msg.sender, address(this), _amount);
        depositors[msg.sender] += _amount;
        emit Deposit(msg.sender, _amount);
    }

    /// @notice withdraw function
    function withdraw(uint256 _amount) external {
        if (!receivers[msg.sender].valid) revert NotAReceiver();
        if (receivers[msg.sender].balance < _amount)
            revert AmountWithdrawnHigherThanExistingBalance();
        receivers[msg.sender].balance -= _amount;
        address(token).safeTransferFrom(address(this), msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    /// @notice can become a receiver with a default secondsPertoken at 10 seconds
    function becomeReceiver() external {
        if (receivers[msg.sender].valid) revert AlreadyAReceiver();
        receivers[msg.sender].balance;
        receivers[msg.sender].valid = true;
        receiverArray.push(msg.sender);
        emit BecomeReceiver(msg.sender);
    }

    /// @notice accept deposits toggle
    function toggleAcceptDeposits() external {
        if (!receivers[msg.sender].valid) revert NotAReceiver();
        receivers[msg.sender].acceptDeposits = !receivers[msg.sender]
            .acceptDeposits;
        emit ToggleDeposits(msg.sender, receivers[msg.sender].acceptDeposits);
    }

    /// @notice depositor transfers token to receiver
    function transferToReceiver(address _receiver, uint256 _amount) external {
        if (!receivers[_receiver].valid) revert ReceiverDoesNotExist();
        if (!receivers[_receiver].acceptDeposits) revert DepositsDisabled();
        if (depositors[msg.sender] < _amount)
            revert TransferAmountHigherThanBalance();
        depositors[msg.sender] -= _amount;
        receivers[_receiver].balance += _amount;
        emit TransferToReceiver(msg.sender, _receiver, _amount);
    }
}
