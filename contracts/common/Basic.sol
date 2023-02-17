// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

abstract contract Basic {
    /// @dev Return MATIC address
    address public constant maticAddr =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Return Wrapped MATIC address
    address public constant wmaticAddr =
        0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    function safeTransferMATIC(address to, uint256 value) internal {
        if (value != 0) {
            (bool success, ) = to.call{value: value}(new bytes(0));
            require(
                success,
                "helper::safeTransferMATIC: MATIC transfer failed"
            );
        }
    }
}
