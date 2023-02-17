// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

import "../../base/AdapterBase.sol";
import "../../../interfaces/balancer/v2/IVault.sol";
import "../../../interfaces/balancer/v2/IAsset.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BalancerV2Adapter is AdapterBase, ReentrancyGuard {
    address public constant vaultAddr =
        0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    constructor(address _adapterManager, address _timelock)
        AdapterBase(_adapterManager, _timelock, "BalancerV2Adapter")
    {}

    event BalancerSingleSwap(
        address account,
        IVault.SingleSwap singleSwapParam,
        IVault.FundManagement funds,
        uint256 limit
    );

    event BalancerBatchSwap(
        address account,
        uint8 kind,
        IVault.BatchSwapStep[],
        address[] assets,
        int256[] limits
    );

    function batchSwap(address account, bytes calldata encodedData)
        external
        payable
        nonReentrant
        onlyAdapterManager
    {
        (
            uint8 kind, //0:in  1:out
            IVault.BatchSwapStep[] memory swaps,
            address[] memory assets,
            int256[] memory limits
        ) = abi.decode(
                encodedData,
                (uint8, IVault.BatchSwapStep[], address[], int256[])
            );

        IVault.FundManagement memory funds = IVault.FundManagement(
            address(this),
            false,
            payable(account),
            false
        );

        // zero address means MATIC in balancer
        if (assets[0] != maticAddr && assets[0] != address(0)) {
            require(msg.value == 0, "invalid msgValue");
            uint256 tokenBeforePull = IERC20(assets[0]).balanceOf(
                address(this)
            );
            pullAndApprove(assets[0], account, vaultAddr, uint256(limits[0]));
            uint256 tokenBeforeSwap = IERC20(assets[0]).balanceOf(
                address(this)
            );
            if (tokenBeforeSwap - tokenBeforePull < uint256(limits[0]))
                limits[0] = int256(tokenBeforeSwap - tokenBeforePull);
            IVault(vaultAddr).batchSwap(
                kind,
                swaps,
                assets,
                funds,
                limits,
                block.timestamp
            );
            uint256 tokenAfterSwap = IERC20(assets[0]).balanceOf(address(this));
            if (tokenBeforeSwap - tokenAfterSwap < uint256(limits[0]))
                returnAsset(
                    assets[0],
                    account,
                    uint256(limits[0]) + tokenAfterSwap - tokenBeforeSwap
                );
        } else {
            require(
                msg.value == uint256(limits[0]),
                "BalancerV2: AmountIn and msgValue mismatch."
            );
            uint256 maticBefore = address(this).balance;
            IVault(vaultAddr).batchSwap{value: msg.value}(
                kind,
                swaps,
                assets,
                funds,
                limits,
                block.timestamp
            );
            uint256 maticAfter = address(this).balance;
            if (maticBefore - maticAfter < msg.value)
                returnAsset(
                    maticAddr,
                    account,
                    msg.value + maticAfter - maticBefore
                );
        }

        emit BalancerBatchSwap(account, kind, swaps, assets, limits);
    }

    function singleSwap(address account, bytes calldata encodedData)
        external
        payable
        nonReentrant
        onlyAdapterManager
    {
        (
            IVault.SingleSwap memory singleSwapParam,
            uint256[] memory limits
        ) = abi.decode(encodedData, (IVault.SingleSwap, uint256[]));

        require(limits.length == 2, "BalancerV2: Wrong length of limits.");
        uint256 limit = singleSwapParam.kind == IVault.SwapKind.GIVEN_IN
            ? limits[1]
            : limits[0];

        IVault.FundManagement memory funds = IVault.FundManagement(
            address(this),
            false,
            payable(account),
            false
        );

        if (
            singleSwapParam.assetIn != IAsset(maticAddr) &&
            singleSwapParam.assetIn != IAsset(address(0)) //matic address in balancer is 0x0
        ) {
            require(msg.value == 0, "invalid msgValue");
            uint256 tokenBeforePull = IERC20(address(singleSwapParam.assetIn))
                .balanceOf(address(this));
            pullAndApprove(
                address(singleSwapParam.assetIn),
                account,
                vaultAddr,
                limits[0]
            );
            uint256 tokenBeforeSwap = IERC20(address(singleSwapParam.assetIn))
                .balanceOf(address(this));
            if (tokenBeforeSwap - tokenBeforePull < limits[0])
                limits[0] = tokenBeforeSwap - tokenBeforePull;
            IVault(vaultAddr).swap(
                singleSwapParam,
                funds,
                limit,
                block.timestamp
            );
            uint256 tokenAfterSwap = IERC20(address(singleSwapParam.assetIn))
                .balanceOf(address(this));
            if (tokenBeforeSwap - tokenAfterSwap < limits[0])
                returnAsset(
                    address(singleSwapParam.assetIn),
                    account,
                    limits[0] + tokenAfterSwap - tokenBeforeSwap
                );
        } else {
            require(
                msg.value == limits[0],
                "BalancerV2: AmountIn and msgValue mismatch."
            );
            uint256 maticBefore = address(this).balance;
            IVault(vaultAddr).swap{value: msg.value}(
                singleSwapParam,
                funds,
                limit,
                block.timestamp
            );
            uint256 maticAfter = address(this).balance;
            if (maticBefore - maticAfter < msg.value)
                returnAsset(
                    maticAddr,
                    account,
                    msg.value + maticAfter - maticBefore
                );
        }

        emit BalancerSingleSwap(account, singleSwapParam, funds, limit);
    }
}
