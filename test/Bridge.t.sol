// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Bridge.sol";
import "../src/MockERC20.sol";

contract BridgeTest is Test {
    Bridge bridge;
    MockERC20 token;
    address user;

    function setUp() public {
        // Deploy MockERC20 token
        token = new MockERC20("Mock Token", "MTKN", 1e18);

        // Deploy Bridge contract
        // Note: You'll need to provide the actual arguments for the Bridge constructor
        bridge = new Bridge(/* constructor arguments */);

        // Set up a test user address
        user = address(1);
    }

    function testBridgeTokens() public {
        // Assign some tokens to the user
        token.mint(user, 1000 ether);

        // Set up the user to call the bridgeTokens function
        vm.prank(user);
        token.approve(address(bridge), 1000 ether);

        // Call the bridgeTokens function
        vm.prank(user);
        bridge.bridgeTokens(token, 500 ether, 2 /* destinationChainId */, address(token), 1 /* nonce */);

        // Check if the tokens have been transferred to the bridge contract
        assertEq(token.balanceOf(address(bridge)), 500 ether, "Bridge should have 500 tokens");

        // Additional assertions can be added to verify the state of the bridge contract
    }

    // Additional test cases as needed
}
