// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Deposit.sol";

contract MockERC20 {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    function transferFrom(
        address from,
        address to,
        uint amount
    ) external returns (bool) {
        require(balances[from] >= amount, "Not enough balance");
        require(allowances[from][msg.sender] >= amount, "Not enough allowance");
        balances[from] -= amount;
        balances[to] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;
        return true;
    }

    function mockDeposit(address to, uint256 amount) external {
        balances[to] = amount;
    }
}

contract CrossChainDepositContractTest is Test {
    CrossChainDepositContract depositContract;
    MockERC20 mockERC20;
    address testUser = address(0x123);

    function setUp() public {
        depositContract = new CrossChainDepositContract(address(0)); // Address 0 for simplicity
        mockERC20 = new MockERC20();
    }

    function testETHDeposit() public {
        uint256 depositAmount = 1 ether;
        bytes32 solanaRecipient = bytes32(uint256(uint160(address(0x456))));

        vm.deal(testUser, depositAmount);

        vm.startPrank(testUser);
        depositContract.depositETH{value: depositAmount}(solanaRecipient);
        vm.stopPrank();

        assertEq(
            address(depositContract).balance,
            depositAmount,
            "ETH deposit failed"
        );
    }

    function testERC20Deposit() public {
        uint256 depositAmount = 1000 * 1e18;
        bytes32 solanaRecipient = bytes32(uint256(uint160(address(0x456))));

        mockERC20.mockDeposit(testUser, depositAmount);

        vm.startPrank(testUser);
        mockERC20.approve(address(depositContract), depositAmount);
        depositContract.depositERC20(
            address(mockERC20),
            depositAmount,
            solanaRecipient
        );
        vm.stopPrank();

        assertEq(
            mockERC20.balances(address(depositContract)),
            depositAmount,
            "ERC20 deposit failed"
        );
    }
}
