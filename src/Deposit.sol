// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20 {
    function transferFrom(address from, address to, uint amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract CrossChainDepositContract {
    address public owner;
    address public wormholeBridge;

    event Deposit(address indexed sender, uint256 amount, address indexed tokenAddress, bytes32 solanaRecipient);

    constructor(address _wormholeBridge) {
        owner = msg.sender;
        wormholeBridge = _wormholeBridge;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function updateWormholeBridge(address _newBridge) external onlyOwner {
        wormholeBridge = _newBridge;
    }

    function depositETH(bytes32 solanaRecipient) external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        emit Deposit(msg.sender, msg.value, address(0), solanaRecipient);
    }

    function depositERC20(address tokenAddress, uint256 amount, bytes32 solanaRecipient) external {
        require(amount > 0, "Deposit amount must be greater than 0");
        bool sent = IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        require(sent, "Token transfer failed");

        emit Deposit(msg.sender, amount, tokenAddress, solanaRecipient);
    }

    function emergencyWithdrawETH() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function emergencyWithdrawERC20(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner, balance);
    }
}
