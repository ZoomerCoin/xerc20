// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {XERC20} from "xtokens/contracts/XERC20.sol";
import {XERC20Factory} from "xtokens/contracts/XERC20Factory.sol";

import {OpL1XERC20Bridge, IOVML1CrossDomainMessenger} from "../src/OpL1XERC20Bridge.sol";

contract OpL1XERC20BridgeTest is Test {
    XERC20 public xzoomer;
    address OWNER = address(0x1);
    address L1CROSSDOMAINMESSENGER = address(0x2);
    address L2CONTRACT = address(0x3);
    OpL1XERC20Bridge public bridge;
    address ALICE = address(0x4);
    address MINTER = address(0x5);
    address BOB = address(0x6);

    function setUp() public {
        XERC20Factory factory = new XERC20Factory();
        address _xzoomer =
            factory.deployXERC20("ZoomerCoin", "ZOOMER", new uint256[](0), new uint256[](0), new address[](0));
        xzoomer = XERC20(_xzoomer);
        bridge = new OpL1XERC20Bridge();
        bridge.initialize(OWNER, _xzoomer, L1CROSSDOMAINMESSENGER);
        bridge.setL2Contract(L2CONTRACT);
        xzoomer.setLimits(address(bridge), type(uint256).max, type(uint256).max);
        xzoomer.setLimits(MINTER, type(uint256).max, type(uint256).max);
        vm.prank(MINTER);
        xzoomer.mint(ALICE, 100000);
    }

    function test__burnAndBridgeToL2__revertsWhenPaused() public {
        vm.prank(OWNER);
        bridge.pause();
        vm.expectRevert("Pausable: paused");
        bridge.burnAndBridgeToL2(ALICE, 100);
    }

    function test__burnAndBridgeToL2_works(uint256 _amount) public {
        vm.assume(_amount <= xzoomer.balanceOf(ALICE));
        vm.mockCall(
            L1CROSSDOMAINMESSENGER,
            abi.encodeWithSelector(IOVML1CrossDomainMessenger(L1CROSSDOMAINMESSENGER).sendMessage.selector),
            abi.encode()
        );
        uint256 supply = xzoomer.totalSupply();
        uint256 balance = xzoomer.balanceOf(ALICE);
        vm.prank(ALICE);
        bridge.burnAndBridgeToL2(ALICE, _amount);
        assertEq(supply - xzoomer.totalSupply(), _amount);
        assertEq(balance - xzoomer.balanceOf(ALICE), _amount);
    }

    function test__mintFromL2_revertsWhenPaused() public {
        vm.prank(OWNER);
        bridge.pause();
        vm.expectRevert("Pausable: paused");
        bridge.mintFromL2(BOB, ALICE, 100);
    }

    function test__mintFromL2_revertsWhenNotBridge(address _sender) public {
        vm.assume(_sender != address(bridge) || _sender != MINTER);
        vm.prank(_sender);
        vm.expectRevert(abi.encodeWithSelector(OpL1XERC20Bridge.NotBridge.selector, _sender));
        bridge.mintFromL2(BOB, ALICE, 100);
    }

    function test__mintFromL2_revertsIfWrongSourceContract(address _source) public {
        vm.assume(_source != L2CONTRACT);
        vm.mockCall(
            L1CROSSDOMAINMESSENGER,
            abi.encodeWithSelector(IOVML1CrossDomainMessenger(L1CROSSDOMAINMESSENGER).xDomainMessageSender.selector),
            abi.encode(_source)
        );
        vm.prank(L1CROSSDOMAINMESSENGER);
        vm.expectRevert(abi.encodeWithSelector(OpL1XERC20Bridge.WrongSourceContract.selector, _source));
        bridge.mintFromL2(BOB, ALICE, 100);
    }

    function test__mintFromL2_works(uint256 amount) public {
        vm.assume(amount <= type(uint256).max - xzoomer.totalSupply());
        vm.mockCall(
            L1CROSSDOMAINMESSENGER,
            abi.encodeWithSelector(IOVML1CrossDomainMessenger(L1CROSSDOMAINMESSENGER).xDomainMessageSender.selector),
            abi.encode(L2CONTRACT)
        );
        uint256 supply = xzoomer.totalSupply();
        uint256 balance = xzoomer.balanceOf(ALICE);
        vm.prank(L1CROSSDOMAINMESSENGER);
        bridge.mintFromL2(BOB, ALICE, amount);
        assertEq(xzoomer.balanceOf(ALICE), amount + balance);
        assertEq(xzoomer.totalSupply(), amount + supply);
    }
}
