// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {PausableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";
import {IXERC20} from "xtokens/interfaces/IXERC20.sol";

import {ProposedOwnableUpgradeable} from "./ownership/ProposedOwnableUpgradeable.sol";

interface IOVML2CrossDomainMessenger {
    function xDomainMessageSender() external view returns (address);
    function sendMessage(address _target, bytes memory _message, uint32 _gasLimit) external;
}

contract OpL2XERC20Bridge is ProposedOwnableUpgradeable, PausableUpgradeable {
    IXERC20 public zoomer;
    IOVML2CrossDomainMessenger public constant OVM_L2_CROSS_DOMAIN_MESSENGER =
        IOVML2CrossDomainMessenger(0x4200000000000000000000000000000000000007);
    address public l1Contract;

    event MessageSent(address indexed _from, address indexed _to, uint256 _amount);
    event MessageReceived(address indexed _from, address indexed _to, uint256 _amount);

    error WrongSourceContract(address _l1Contract);
    error NotBridge(address _sender);

    modifier onlyBridge() {
        if (msg.sender != address(OVM_L2_CROSS_DOMAIN_MESSENGER)) {
            revert NotBridge(msg.sender);
        }
        _;
    }

    function initialize(address _owner, address _zoomer) public initializer {
        __ProposedOwnable_init();
        __Pausable_init();

        _setOwner(_owner);
        zoomer = IXERC20(_zoomer);
    }

    function setL1Contract(address _l1Contract) external onlyOwner {
        l1Contract = _l1Contract;
    }

    function mintFromL1(address _from, address _to, uint256 _amount) external whenNotPaused onlyBridge {
        if (OVM_L2_CROSS_DOMAIN_MESSENGER.xDomainMessageSender() != l1Contract) {
            revert WrongSourceContract(OVM_L2_CROSS_DOMAIN_MESSENGER.xDomainMessageSender());
        }
        zoomer.mint(_to, _amount);
        emit MessageReceived(_from, _to, _amount);
    }

    function burnAndBridgeToL1(address _to, uint256 _amount) external whenNotPaused {
        zoomer.burn(msg.sender, _amount);
        OVM_L2_CROSS_DOMAIN_MESSENGER.sendMessage(
            l1Contract,
            abi.encodeWithSignature("mintFromL2(address,address,uint256)", msg.sender, _to, _amount),
            1000000
        );
        emit MessageSent(msg.sender, _to, _amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    // ============ Upgrade Gap ============
    uint256[49] private __GAP; // gap for upgrade safety
}
