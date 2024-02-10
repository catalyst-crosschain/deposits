// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Wrap.sol";
import "../src/MockERC20.sol";

contract WrapTest is Test {
    Wrap wrap;
    MockERC20 originalToken;
    MockERC20 wrappedToken;

    address testUser = address(1);

    function setUp() public {
    originalToken = new MockERC20("Original Token", "OT", 1000 ether);
    wrappedToken = new MockERC20("Wrapped Token", "WT", 1000 ether);
    wrap = new Wrap();

    wrap.addTokenPair(address(originalToken), address(wrappedToken));

    // Transfer tokens to testUser and approve Wrap contract for both tokens
    originalToken.transfer(testUser, 500 ether);
    wrappedToken.transfer(testUser, 500 ether);
    vm.startPrank(testUser);
    originalToken.approve(address(wrap), 500 ether);
    wrappedToken.approve(address(wrap), 500 ether);
    vm.stopPrank();
}

function testWrap() public {
    uint256 amount = 100 ether;

    vm.startPrank(testUser);
    wrap.wrap(address(originalToken), amount);

    assertEq(originalToken.balanceOf(testUser), 400 ether, "Incorrect original token balance after wrap");
    assertEq(wrappedToken.balanceOf(testUser), 600 ether, "Incorrect wrapped token balance after wrap");
    vm.stopPrank();
}

function testUnwrap() public {
    uint256 amount = 100 ether;

    vm.startPrank(testUser);
    wrap.wrap(address(originalToken), amount); // Wrap first to get some wrapped tokens

    wrappedToken.approve(address(wrap), amount);
    wrap.unwrap(address(wrappedToken), amount);

    assertEq(originalToken.balanceOf(testUser), 400 ether, "Incorrect original token balance after unwrap");
    assertEq(wrappedToken.balanceOf(testUser), 500 ether, "Incorrect wrapped token balance after unwrap");
    vm.stopPrank();
}

}
