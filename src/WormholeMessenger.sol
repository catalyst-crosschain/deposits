// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces/IWormhole.sol";
import "./Libraries/HashUtils.sol";

/**
 * @title WormholeMessenger
 * @dev Contract to facilitate messaging across blockchains using the Wormhole protocol.
 */

 interface IMessenger {
    function sentMessagesBlock(bytes32 message) external view returns (uint);

    function receivedMessages(bytes32 message) external view returns (uint);

    function sendMessage(bytes32 message) external payable;

    function receiveMessage(bytes32 message, uint v1v2, bytes32 r1, bytes32 s1, bytes32 r2, bytes32 s2) external;
}

contract WormholeMessenger is Ownable {
    using HashUtils for bytes32;

    IWormhole public immutable wormhole;
    uint32 public nonce;
    uint8 public commitmentLevel;

    mapping(uint16 => bytes32) public otherWormholeMessengers;
    mapping(bytes32 => uint) public receivedMessages;
    mapping(bytes32 => uint) public sentMessages;

    event MessageSent(bytes32 indexed message, uint64 sequence);
    event MessageReceived(bytes32 indexed message, uint64 sequence);

    constructor(IWormhole _wormhole, uint8 _commitmentLevel) {
        wormhole = _wormhole;
        commitmentLevel = _commitmentLevel;
    }

    function sendMessage(bytes32 message, uint16 targetChainId) external {
        bytes32 messageWithSender = message.hashWithSenderAddress(msg.sender);
        require(sentMessages[messageWithSender] == 0, "WormholeMessenger: Message already sent");

        uint64 sequence = wormhole.publishMessage(nonce++, abi.encodePacked(messageWithSender), commitmentLevel, targetChainId);
        sentMessages[messageWithSender] = 1;

        emit MessageSent(messageWithSender, sequence);
    }

    function receiveMessage(bytes memory encodedMessage) external {
        (IWormhole.VM memory vm, bool valid, string memory reason) = wormhole.parseAndVerifyVM(encodedMessage);
        require(valid, reason);
        require(vm.payload.length == 32, "WormholeMessenger: Invalid payload length");

        bytes32 messageWithSender = bytes32(vm.payload);
        require(receivedMessages[messageWithSender] == 0, "WormholeMessenger: Message already received");
        require(otherWormholeMessengers[vm.emitterChainId] == vm.emitterAddress, "WormholeMessenger: Invalid emitter");

        receivedMessages[messageWithSender] = 1;
        emit MessageReceived(messageWithSender, vm.sequence);
    }

    function registerOtherWormholeMessenger(uint16 chainId, bytes32 messengerAddress) external onlyOwner {
        otherWormholeMessengers[chainId] = messengerAddress;
    }

    function updateCommitmentLevel(uint8 newCommitmentLevel) external onlyOwner {
        commitmentLevel = newCommitmentLevel;
    }
}
