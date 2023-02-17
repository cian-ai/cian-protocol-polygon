// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

import "../base/AdapterBase.sol";
import "../../interfaces/stader/IChildPool.sol";

contract StaderAdapter is AdapterBase {
    address public constant maticXAddr =
        0xfa68FB4628DFF1028CFEc22b4162FCcd0d45efb6;

    address public constant maticXpoolAddr =
        0xfd225C9e6601C9d38d8F98d8731BF59eFcF8C0E3;

    constructor(address _adapterManager, address _timelock)
        AdapterBase(_adapterManager, _timelock, "StaderAdapter")
    {}

    event StaderStake(address account, uint256 amount);
    event StaderUnstake(address account, uint256 amount);
    event StaderClaimUnlocked(address account, uint256 amount);

    function stake(uint256 maticAmount) external payable onlyDelegation {
        IChildPool(maticXpoolAddr).swapMaticForMaticXViaInstantPool{
            value: maticAmount
        }();
        emit StaderStake(address(this), maticAmount);
    }

    function requestUnstake(uint256 maticXAmount) external onlyDelegation {
        IChildPool(maticXpoolAddr).requestMaticXSwap(maticXAmount);
        emit StaderUnstake(address(this), maticXAmount);
    }

    function getUserUnstakeRequests(address account)
        external
        view
        returns (IChildPool.MaticXSwapRequest[] memory)
    {
        return IChildPool(maticXpoolAddr).getUserMaticXSwapRequests(account);
    }

    function claimUnlocked(uint256 index) external onlyDelegation {
        IChildPool.MaticXSwapRequest memory request = IChildPool(maticXpoolAddr)
            .getUserMaticXSwapRequests(address(this))[index];

        IChildPool(maticXpoolAddr).claimMaticXSwap(index);

        emit StaderClaimUnlocked(address(this), request.amount);
    }
}
