// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IBridge {
    /**
     * @dev Encodes asset and transaction information into a format compatible with the Wormhole protocol.
     * @param asset The asset to be transferred.
     * @param amount The amount of the asset to be transferred.
     * @param to The destination address on the target chain.
     * @return encodedData The encoded data ready to be sent to the Wormhole bridge.
     */
    function encodeAssetInformation(address asset, uint256 amount, address to) external view returns (bytes memory encodedData);

    /**
     * @dev Handles the submission of cross-chain transfer requests to the Wormhole bridge.
     * @param encodedData The encoded asset and transaction information.
     * @return success Indicates whether the submission was successful.
     */
    function submitCrossChainTransfer(bytes memory encodedData) external returns (bool success);

    /**
     * @dev Verifies and processes incoming messages or transactions from the Solana network via the Wormhole bridge.
     * @param incomingData The incoming data from Solana to be processed.
     * @return processed Indicates whether the incoming data was successfully processed.
     */
    function processIncomingData(bytes memory incomingData) external returns (bool processed);
}
