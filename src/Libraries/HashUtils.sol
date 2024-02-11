// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library HashUtils {
    /**
     * @dev Replace the first two bytes of data with the source and destination chain IDs.
     * @param data The original bytes32 data.
     * @param sourceChainId The source chain ID to insert.
     * @param destinationChainId The destination chain ID to insert.
     * @return result The modified bytes32 data.
     */
    function replaceChainBytes(
        bytes32 data,
        uint8 sourceChainId,
        uint8 destinationChainId
    ) internal pure returns (bytes32 result) {
        assembly {
            mstore(0x00, data)
            mstore8(0x00, sourceChainId)
            mstore8(0x01, destinationChainId)
            result := mload(0x0)
        }
    }

    /**
     * @dev Hashes a message with a sender.
     * @param message The message to hash.
     * @param sender The sender's address.
     * @return result The hashed value.
     */
    function hashWithSender(bytes32 message, bytes32 sender) internal pure returns (bytes32 result) {
        assembly {
            mstore(0x00, message)
            mstore(0x20, sender)
            result := or(
                and(
                    message,
                    0xffff000000000000000000000000000000000000000000000000000000000000 // First 2 bytes
                ),
                and(
                    keccak256(0x00, 0x40),
                    0x0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff // Last 30 bytes
                )
            )
        }
    }

    /**
     * @dev Hashes a message with a sender address.
     * @param message The message to hash.
     * @param sender The sender's address.
     * @return result The hashed value.
     */
    function hashWithSenderAddress(bytes32 message, address sender) internal pure returns (bytes32 result) {
        assembly {
            mstore(0x00, message)
            mstore(0x20, sender)
            result := or(
                and(
                    message,
                    0xffff000000000000000000000000000000000000000000000000000000000000 // First 2 bytes
                ),
                and(
                    keccak256(0x00, 0x40),
                    0x0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff // Last 30 bytes
                )
            )
        }
    }

    /**
     * @dev Hashes a bytes32 message.
     * @param message The message to hash.
     * @return result The hashed value.
     */
    function hashed(bytes32 message) internal pure returns (bytes32 result) {
        assembly {
            mstore(0x00, message)
            result := keccak256(0x00, 0x20)
        }
    }
}
