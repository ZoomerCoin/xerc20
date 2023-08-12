// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {XERC20} from "xtokens/contracts/XERC20.sol";
import {XERC20Factory} from "xtokens/contracts/XERC20Factory.sol";

import {OpL2XERC20Bridge, IOVML2CrossDomainMessenger} from "../src/OpL2XERC20Bridge.sol";

contract OpL2XERC20BridgeTest is Test {
    XERC20 public xzoomer;
    address OWNER = address(0x1);
    address L2CROSSDOMAINMESSENGER = 0x4200000000000000000000000000000000000007;
    address L1CONTRACT = address(0x3);
    OpL2XERC20Bridge public bridge;
    address ALICE = address(0x4);
    address MINTER = address(0x5);
    address BOB = address(0x6);

    function setUp() public {
        XERC20Factory factory = new XERC20Factory();
        address _xzoomer =
            factory.deployXERC20("ZoomerCoin", "ZOOMER", new uint256[](0), new uint256[](0), new address[](0));
        xzoomer = XERC20(_xzoomer);
        bridge = new OpL2XERC20Bridge();
        bridge.initialize(OWNER, _xzoomer, L1CONTRACT);
        xzoomer.setLimits(address(bridge), type(uint256).max, type(uint256).max);
        xzoomer.setLimits(MINTER, type(uint256).max, type(uint256).max);
        vm.prank(MINTER);
        xzoomer.mint(ALICE, 100000);
    }

    function test__burnAndBridgeToL1__revertsWhenPaused() public {
        vm.prank(OWNER);
        bridge.pause();
        vm.expectRevert("Pausable: paused");
        bridge.burnAndBridgeToL1(ALICE, 100);
    }

    function test__burnAndBridgeToL1_works(uint256 _amount) public {
        vm.assume(_amount <= xzoomer.balanceOf(ALICE));
        vm.mockCall(
            L2CROSSDOMAINMESSENGER,
            abi.encodeWithSelector(IOVML2CrossDomainMessenger(L2CROSSDOMAINMESSENGER).sendMessage.selector),
            abi.encode()
        );
        uint256 supply = xzoomer.totalSupply();
        uint256 balance = xzoomer.balanceOf(ALICE);
        vm.prank(ALICE);
        bridge.burnAndBridgeToL1(ALICE, _amount);
        assertEq(supply - xzoomer.totalSupply(), _amount);
        assertEq(balance - xzoomer.balanceOf(ALICE), _amount);
    }

    function test__mintFromL1_revertsWhenPaused() public {
        vm.prank(OWNER);
        bridge.pause();
        vm.expectRevert("Pausable: paused");
        bridge.mintFromL1(BOB, ALICE, 100);
    }

    function test__mintFromL1_revertsWhenNotBridge(address _sender) public {
        vm.assume(_sender != address(bridge) || _sender != MINTER);
        vm.prank(_sender);
        vm.expectRevert(abi.encodeWithSelector(OpL2XERC20Bridge.NotBridge.selector, _sender));
        bridge.mintFromL1(BOB, ALICE, 100);
    }

    function test__mintFromL1_revertsIfWrongSourceContract(address _source) public {
        vm.assume(_source != L1CONTRACT);
        vm.mockCall(
            L2CROSSDOMAINMESSENGER,
            abi.encodeWithSelector(IOVML2CrossDomainMessenger(L2CROSSDOMAINMESSENGER).xDomainMessageSender.selector),
            abi.encode(_source)
        );
        vm.prank(L2CROSSDOMAINMESSENGER);
        vm.expectRevert(abi.encodeWithSelector(OpL2XERC20Bridge.WrongSourceContract.selector, _source));
        bridge.mintFromL1(BOB, ALICE, 100);
    }

    function test__mintFromL1_works(uint256 amount) public {
        vm.assume(amount <= type(uint256).max - xzoomer.totalSupply());
        vm.mockCall(
            L2CROSSDOMAINMESSENGER,
            abi.encodeWithSelector(IOVML2CrossDomainMessenger(L2CROSSDOMAINMESSENGER).xDomainMessageSender.selector),
            abi.encode(L1CONTRACT)
        );
        uint256 supply = xzoomer.totalSupply();
        uint256 balance = xzoomer.balanceOf(ALICE);
        vm.prank(L2CROSSDOMAINMESSENGER);
        bridge.mintFromL1(BOB, ALICE, amount);
        assertEq(xzoomer.balanceOf(ALICE), amount + balance);
        assertEq(xzoomer.totalSupply(), amount + supply);
    }
}
