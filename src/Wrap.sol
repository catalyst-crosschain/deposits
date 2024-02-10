// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract Wrap {
    address public owner;
    mapping(address => address) public wrappedTokens; // OriginalToken => WrappedToken
    mapping(address => address) public unwrappedTokens; // WrappedToken => OriginalToken

    event TokenWrapped(address indexed originalToken, address indexed wrappedToken, uint256 amount, address indexed user);
    event TokenUnwrapped(address indexed wrappedToken, address indexed originalToken, uint256 amount, address indexed user);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function wrap(address originalToken, uint256 amount) external returns (address wrappedToken) {
        require(amount > 0, "Amount must be greater than 0");
        require(wrappedTokens[originalToken] != address(0), "Original token not supported");

        wrappedToken = wrappedTokens[originalToken];

        // Transfer original tokens from user to this contract
        require(IERC20(originalToken).transferFrom(msg.sender, address(this), amount), "Transfer of original token failed");

        // "Mint" wrapped tokens to user - Assuming wrappedToken implements this functionality
        require(IERC20(wrappedToken).transfer(msg.sender, amount), "Transfer of wrapped token failed");

        emit TokenWrapped(originalToken, wrappedToken, amount, msg.sender);
    }

    function unwrap(address wrappedToken, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(unwrappedTokens[wrappedToken] != address(0), "Wrapped token not supported");

        address originalToken = unwrappedTokens[wrappedToken];

        // Transfer wrapped tokens from user to this contract
        require(IERC20(wrappedToken).transferFrom(msg.sender, address(this), amount), "Transfer of wrapped token failed");

        // "Burn" wrapped tokens and release original tokens to user
        require(IERC20(originalToken).transfer(msg.sender, amount), "Transfer of original token failed");

        emit TokenUnwrapped(wrappedToken, originalToken, amount, msg.sender);
    }

    function addTokenPair(address originalToken, address wrappedToken) external onlyOwner {
        wrappedTokens[originalToken] = wrappedToken;
        unwrappedTokens[wrappedToken] = originalToken;
    }

    // Additional functions like removeTokenPair, updateOwner can be added here
}
