// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Interfaces/IBridge.sol";
import "./Interfaces/IWormhole.sol";
import "./WormholeMessenger.sol";
import "./Libraries/HashUtils.sol";

interface IGasOracle {
    function chainData(uint chainId) external view returns (uint128 price, uint128 gasPrice);

    function chainId() external view returns (uint);

    function crossRate(uint otherChainId) external view returns (uint);

    function getTransactionGasCostInNativeToken(uint otherChainId, uint256 gasAmount) external view returns (uint);

    function getTransactionGasCostInUSD(uint otherChainId, uint256 gasAmount) external view returns (uint);

    function price(uint chainId) external view returns (uint);

    function setChainData(uint chainId, uint128 price, uint128 gasPrice) external;

    function setGasPrice(uint chainId, uint128 gasPrice) external;

    function setPrice(uint chainId, uint128 price) external;
}

contract Bridge is IBridge {
    using SafeERC20 for IERC20;
    using HashUtils for bytes32;

    IWormhole public wormhole;
    WormholeMessenger public messenger;
    IGasOracle public gasOracle;
    address public admin;

    uint public immutable chainId;
    mapping(bytes32 => bool) public processedMessages;
    mapping(bytes32 => bool) public sentMessages;

    event TokensSent(uint amount, address indexed recipient, uint destinationChainId, address indexed receiveToken, uint nonce);
    event TokensReceived(uint amount, address indexed recipient, uint nonce, bytes32 message);

    constructor(uint _chainId, IWormhole _wormhole, WormholeMessenger _messenger, IGasOracle _gasOracle) {
        chainId = _chainId;
        wormhole = _wormhole;
        messenger = _messenger;
        gasOracle = _gasOracle;
        admin = msg.sender;
    }

    function bridgeTokens(IERC20 token, uint amount, uint destinationChainId, address receiveToken, uint nonce) external override {
    require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

    bytes32 message = keccak256(abi.encodePacked(msg.sender, amount, destinationChainId, receiveToken, nonce, address(token)));
    require(!sentMessages[message], "Message already sent");

    sentMessages[message] = true;

    bytes memory encodedMessage = abi.encodeWithSelector(
        IWormhole.bridgeTokens.selector, 
        msg.sender, 
        amount, 
        destinationChainId, 
        receiveToken, 
        nonce
    );

    messenger.sendMessage(encodedMessage);

    emit TokensSent(amount, msg.sender, destinationChainId, receiveToken, nonce);
}


    function receiveTokens(uint amount, address recipient, uint sourceChainId, address receiveToken, uint nonce, bytes32 messageHash) external override {
    require(!processedMessages[messageHash], "Message already processed");

    bool isMessageValid = verifyMessage(messageHash, amount, recipient, sourceChainId, receiveToken, nonce);
    require(isMessageValid, "Invalid message");

    IERC20(receiveToken).transfer(recipient, amount);

    processedMessages[messageHash] = true;

    emit TokensReceived(amount, recipient, nonce, messageHash);
}

function verifyMessage(bytes32 messageHash, uint amount, address recipient, uint sourceChainId, address receiveToken, uint nonce) private view returns (bool) {
    bytes32 expectedHash = keccak256(abi.encodePacked(amount, recipient, sourceChainId, receiveToken, nonce));
    return (messageHash == expectedHash);
}


    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    function updateWormhole(IWormhole newWormhole) external onlyAdmin {
        wormhole = newWormhole;
    }

    function updateMessenger(WormholeMessenger newMessenger) external onlyAdmin {
        messenger = newMessenger;
    }

    function updateGasOracle(IGasOracle newGasOracle) external onlyAdmin {
        gasOracle = newGasOracle;
    }
}
