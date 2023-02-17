// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

import "../base/AdapterBase.sol";
import "../../interfaces/quickswap/IQuickSwapRouter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract QuickSwapAdapter is AdapterBase, ReentrancyGuard {
    address public constant routerAddr =
        0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    IQuickSwapRouter internal router = IQuickSwapRouter(routerAddr);

    constructor(address _adapterManager, address _timelock)
        AdapterBase(_adapterManager, _timelock, "QuickSwap")
    {}

    event QuickSwapETHForExactTokens(
        address account,
        address[] path,
        uint256[] amounts
    );

    event QuickSwapExactETHForTokens(
        address account,
        address[] path,
        uint256[] amounts
    );

    event QuickSwapTokensForExactTokens(
        address account,
        address[] path,
        uint256[] amounts
    );

    event QuickSwapExactTokensForTokens(
        address account,
        address[] path,
        uint256[] amounts
    );

    event QuickSwapTokensForExactETH(
        address account,
        address[] path,
        uint256[] amounts
    );

    event QuickSwapExactTokensForETH(
        address account,
        address[] path,
        uint256[] amounts
    );

    /// @dev swap matic for fixed amount of tokens
    function swapETHForExactTokens(address account, bytes calldata encodedData)
        external
        payable
        onlyAdapterManager
    {
        (uint256 amountOut, address[] memory path) = abi.decode(
            encodedData,
            (uint256, address[])
        );
        uint256[] memory amounts = router.swapETHForExactTokens{
            value: msg.value
        }(amountOut, path, account, block.timestamp);
        if (msg.value > amounts[0])
            returnAsset(maticAddr, account, msg.value - amounts[0]);

        emit QuickSwapETHForExactTokens(account, path, amounts);
    }

    /// @dev swap fixed amount of matic for tokens
    function swapExactETHForTokens(address account, bytes calldata encodedData)
        external
        payable
        onlyAdapterManager
    {
        (uint256 amountOutMin, address[] memory path) = abi.decode(
            encodedData,
            (uint256, address[])
        );
        uint256[] memory amounts = router.swapExactETHForTokens{
            value: msg.value
        }(amountOutMin, path, account, block.timestamp);

        emit QuickSwapExactETHForTokens(account, path, amounts);
    }

    /// @dev swap tokens for fixed amount of matic
    function swapTokensForExactTokens(
        address account,
        bytes calldata encodedData
    ) external nonReentrant onlyAdapterManager {
        (uint256 amountOut, uint256 amountInMax, address[] memory path) = abi
            .decode(encodedData, (uint256, uint256, address[]));
        uint256 tokenBeforePull = IERC20(path[0]).balanceOf(address(this));
        pullAndApprove(path[0], account, routerAddr, amountInMax);
        uint256 tokenAfterPull = IERC20(path[0]).balanceOf(address(this));
        if (tokenAfterPull - tokenBeforePull < amountInMax)
            amountInMax = tokenAfterPull - tokenBeforePull;
        uint256[] memory amounts = router.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            account,
            block.timestamp
        );

        if (amountInMax > amounts[0])
            returnAsset(path[0], account, amountInMax - amounts[0]);

        emit QuickSwapTokensForExactTokens(account, path, amounts);
    }

    /// @dev swap fixed amount of tokens for matic
    function swapExactTokensForTokens(
        address account,
        bytes calldata encodedData
    ) external nonReentrant onlyAdapterManager {
        (uint256 amountIn, uint256 amountOutMin, address[] memory path) = abi
            .decode(encodedData, (uint256, uint256, address[]));
        uint256 tokenBeforePull = IERC20(path[0]).balanceOf(address(this));
        pullAndApprove(path[0], account, routerAddr, amountIn);
        uint256 tokenAfterPull = IERC20(path[0]).balanceOf(address(this));
        if (tokenAfterPull - tokenBeforePull < amountIn)
            amountIn = tokenAfterPull - tokenBeforePull;
        uint256[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            account,
            block.timestamp
        );

        emit QuickSwapExactTokensForTokens(account, path, amounts);
    }

    function swapTokensForExactETH(address account, bytes calldata encodedData)
        external
        nonReentrant
        onlyAdapterManager
    {
        (uint256 amountOut, uint256 amountInMax, address[] memory path) = abi
            .decode(encodedData, (uint256, uint256, address[]));
        uint256 tokenBeforePull = IERC20(path[0]).balanceOf(address(this));
        pullAndApprove(path[0], account, routerAddr, amountInMax);
        uint256 tokenAfterPull = IERC20(path[0]).balanceOf(address(this));
        if (tokenAfterPull - tokenBeforePull < amountInMax)
            amountInMax = tokenAfterPull - tokenBeforePull;
        uint256[] memory amounts = router.swapTokensForExactETH(
            amountOut,
            amountInMax,
            path,
            account,
            block.timestamp
        );

        if (amountInMax > amounts[0])
            returnAsset(path[0], account, amountInMax - amounts[0]);

        emit QuickSwapTokensForExactETH(account, path, amounts);
    }

    function swapExactTokensForETH(address account, bytes calldata encodedData)
        external
        nonReentrant
        onlyAdapterManager
    {
        (uint256 amountIn, uint256 amountOutMin, address[] memory path) = abi
            .decode(encodedData, (uint256, uint256, address[]));
        uint256 tokenBeforePull = IERC20(path[0]).balanceOf(address(this));
        pullAndApprove(path[0], account, routerAddr, amountIn);
        uint256 tokenAfterPull = IERC20(path[0]).balanceOf(address(this));
        if (tokenAfterPull - tokenBeforePull < amountIn)
            amountIn = tokenAfterPull - tokenBeforePull;
        uint256[] memory amounts = router.swapExactTokensForETH(
            amountIn,
            amountOutMin,
            path,
            account,
            block.timestamp
        );

        emit QuickSwapExactTokensForETH(account, path, amounts);
    }
}
