// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {TransparentUpgradeableProxy} from "openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {XZoomerCoin} from "../src/XZoomerCoin.sol";

/**
 * @title XZoomerCoinTest
 * @author @rhlsthrm
 * @notice This test does not test the proxy functionality due to Forge tooling unavailability.
 * The proxy functionality is tested in Typescript using xzoomer.test.ts.
 */
contract XZoomerCoinTest is Test {
    XZoomerCoin xzoomer;
    address ALICE = address(0x1);
    address BOB = address(0x2);
    address BRIDGE = address(0x3);

    function setUp() public {
        vm.startPrank(ALICE);
        xzoomer = new XZoomerCoin();
        xzoomer.initialize(ALICE, "XZoomerCoin", "ZOOMER");
        vm.stopPrank();
    }

    function test_XZoomerCoin__details() public {
        assertEq(xzoomer.name(), "XZoomerCoin");
        assertEq(xzoomer.symbol(), "ZOOMER");
        assertEq(xzoomer.decimals(), 18);
        assertEq(xzoomer.totalSupply(), 0);
        assertEq(xzoomer.owner(), ALICE);
    }

    function test_XZoomerCoin__addBridge_failsIfNotOwner(address sender) public {
        vm.assume(sender != ALICE);
        vm.prank(sender);
        vm.expectRevert(bytes("!owner"));
        xzoomer.addBridge(BRIDGE);
    }

    function test_XZoomerCoin__bridgeCanMintAndBurn(address bridge) public {
        vm.prank(ALICE);
        xzoomer.addBridge(bridge);
        vm.prank(bridge);
        xzoomer.mint(BOB, 100);
        assertEq(xzoomer.balanceOf(BOB), 100);
        assertEq(xzoomer.totalSupply(), 100);
        vm.prank(bridge);
        xzoomer.burn(BOB, 50);
        assertEq(xzoomer.balanceOf(BOB), 50);
        assertEq(xzoomer.totalSupply(), 50);
    }

    function test_XZoomerCoin__removeBridge_failsIfNotOwner(address sender) public {
        vm.prank(ALICE);
        xzoomer.addBridge(BRIDGE);
        vm.assume(sender != ALICE);
        vm.prank(sender);
        vm.expectRevert(bytes("!owner"));
        xzoomer.removeBridge(BRIDGE);
    }

    function test_XZoomerCoin__removeBridge_works(address bridge) public {
        vm.prank(ALICE);
        xzoomer.addBridge(bridge);
        vm.prank(ALICE);
        xzoomer.removeBridge(bridge);
        vm.prank(bridge);
        vm.expectRevert(XZoomerCoin.XERC20__onlyBridge_notBridge.selector);
        xzoomer.mint(BOB, 100);
    }
}
