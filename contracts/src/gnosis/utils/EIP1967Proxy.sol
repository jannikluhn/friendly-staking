// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

import "./EIP1967Admin.sol";

/**
 * @title EIP1967Proxy
 * @dev Upgradeable proxy pattern implementation according to minimalistic EIP1967.
 */
contract EIP1967Proxy is EIP1967Admin {
    // EIP 1967
    // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    uint256 internal constant EIP1967_IMPLEMENTATION_STORAGE =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    event Upgraded(address indexed implementation);
    event AdminChanged(address previousAdmin, address newAdmin);

    function admin() public view returns (address) {
        return _admin();
    }

    function implementation() public view returns (address res) {
        assembly {
            res := sload(EIP1967_IMPLEMENTATION_STORAGE)
        }
    }

    function setAdmin(address _admin) external onlyAdmin {
        _setAdmin(_admin);
    }

    function upgradeTo(address _implementation) external onlyAdmin {
        _setImplementation(_implementation);
    }

    /**
     * @dev Fallback function allowing to perform a delegatecall to the given implementation.
     * This function will return whatever the implementation call returns
     */
    fallback() external payable {
        address impl = implementation();
        require(impl != address(0));
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev Internal function for transfer current admin rights to a different account.
     * @param _admin address of the new administrator.
     */
    function _setAdmin(address _admin) internal {
        address previousAdmin = admin();
        require(_admin != address(0));
        require(previousAdmin != _admin);
        assembly {
            sstore(EIP1967_ADMIN_STORAGE, _admin)
        }
        emit AdminChanged(previousAdmin, _admin);
    }

    /**
     * @dev Internal function for setting a new implementation address.
     * @param _implementation address of the new implementation contract.
     */
    function _setImplementation(address _implementation) internal {
        require(_implementation != address(0));
        require(implementation() != _implementation);
        assembly {
            sstore(EIP1967_IMPLEMENTATION_STORAGE, _implementation)
        }
        emit Upgraded(_implementation);
    }
}
