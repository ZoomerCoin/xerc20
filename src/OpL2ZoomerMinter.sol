// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {PausableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";

import {ProposedOwnableUpgradeable} from "./ownership/ProposedOwnableUpgradeable.sol";

interface IZoomer {
    function mint(address _to, uint256 _amount) external;
    function burn(address _from, uint256 _amount) external;
}

interface IOVML2CrossDomainMessenger {
    function xDomainMessageSender() external view returns (address);
}

contract OpL2XERC20Bridge is ProposedOwnableUpgradeable, PausableUpgradeable {
    IZoomer public zoomer;
    IOVML2CrossDomainMessenger public constant OVM_L2_CROSS_DOMAIN_MESSENGER =
        IOVML2CrossDomainMessenger(0x4200000000000000000000000000000000000007);
    address public l1Contract;

    event MessageReceived(address indexed _from, address indexed _to, uint256 _amount);

    error WrongSourceContract(address _l1Contract);

    modifier onlyBridge() {
        require(msg.sender == address(OVM_L2_CROSS_DOMAIN_MESSENGER));
        _;
    }

    function initialize(address _owner, address _zoomer, address _l1Contract) public initializer {
        __ProposedOwnable_init();
        __Pausable_init();

        _setOwner(_owner);
        zoomer = IZoomer(_zoomer);
        l1Contract = _l1Contract;
    }

    function mintFromL1(address _from, address _to, uint256 _amount) external onlyBridge whenNotPaused {
        if (OVM_L2_CROSS_DOMAIN_MESSENGER.xDomainMessageSender() == l1Contract) {
            revert WrongSourceContract(OVM_L2_CROSS_DOMAIN_MESSENGER.xDomainMessageSender());
        }
        emit MessageReceived(_from, _to, _amount);
        zoomer.mint(_to, _amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    // ============ Upgrade Gap ============
    uint256[49] private __GAP; // gap for upgrade safety
}
