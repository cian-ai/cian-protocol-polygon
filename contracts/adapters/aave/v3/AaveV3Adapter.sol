// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

import "../../base/AdapterBase.sol";
import "../../../interfaces/aave/v2/IAToken.sol";
import "../../../interfaces/aave/v2/IWMATICGateway.sol";
import "../../../interfaces/aave/v2/IVariableDebtToken.sol";
import "../../../interfaces/aave/v2/IProtocolDataProvider.sol";
import "../../../interfaces/aave/v3/ILendingPoolV3.sol";
import "../../../interfaces/aave/v3/IRewardsController.sol";

contract AaveV3Adapter is AdapterBase {
    mapping(address => address) public trustATokenAddr;

    event AaveDeposit(address token, uint256 amount, address account);
    event AaveWithDraw(address token, uint256 amount, address account);
    event AaveBorrow(
        address token,
        uint256 amount,
        address account,
        uint256 rateMode
    );
    event AaveRepay(
        address token,
        uint256 amount,
        address account,
        uint256 rateMode
    );
    event AaveClaim(address target, uint256 amount);

    constructor(address _adapterManager, address _timelock)
        AdapterBase(_adapterManager, _timelock, "AaveV3Adapter")
    {}

    function initialize(
        address[] calldata tokenAddr,
        address[] calldata aTokenAddr
    ) external onlyTimelock {
        require(
            tokenAddr.length > 0 && tokenAddr.length == aTokenAddr.length,
            "Set length mismatch."
        );
        IProtocolDataProvider dataProvider = IProtocolDataProvider(
            aaveDataAddr
        );
        for (uint256 i = 0; i < tokenAddr.length; i++) {
            (address _aTokenAddr, , ) = dataProvider.getReserveTokensAddresses(
                tokenAddr[i]
            );
            if (tokenAddr[i] == maticAddr) {
                (address _awethAddr, , ) = dataProvider
                    .getReserveTokensAddresses(wmaticAddr);
                require(aTokenAddr[i] == _awethAddr, "Address mismatch.");
            } else {
                require(_aTokenAddr == aTokenAddr[i], "Address mismatch.");
            }
            trustATokenAddr[tokenAddr[i]] = aTokenAddr[i];
        }
    }

    address public constant aaveDataAddr =
        0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654;
    address public constant wmaticGatewayAddr =
        0x9BdB5fcc80A49640c7872ac089Cc0e00A98451B6;
    address public constant aaveV3PoolAddr =
        0x794a61358D6845594F94dc1DB02A252b5b4814aD;
    address public constant debtMaticAddr =
        0x4a1c3aD6Ed28a636ee1751C69071f6be75DEb8B8;
    address public constant incentivesController =
        0x929EC64c34a17401F460460D4B9390518E5B473e;

    /// @dev Aave Referral Code
    uint16 internal constant referralCode = 0;

    function deposit(address account, bytes calldata encodedData)
        external
        payable
        onlyAdapterManager
    {
        (address token, uint256 amount) = abi.decode(
            encodedData,
            (address, uint256)
        );
        require(trustATokenAddr[token] != address(0), "token error");

        if (token == maticAddr) {
            IWMATICGateway(wmaticGatewayAddr).depositETH{value: msg.value}(
                aaveV3PoolAddr,
                account,
                referralCode
            );
            emit AaveDeposit(token, msg.value, account);
        } else {
            require(msg.value == 0, "invalid msgValue");
            pullAndApprove(token, account, aaveV3PoolAddr, amount);
            ILendingPoolV3(aaveV3PoolAddr).supply(
                token,
                amount,
                account,
                referralCode
            );
            emit AaveDeposit(token, amount, account);
        }
    }

    function setCollateral(address token, bool isCollateral)
        external
        onlyDelegation
    {
        ILendingPoolV3(aaveV3PoolAddr).setUserUseReserveAsCollateral(
            token,
            isCollateral
        );
    }

    function withdraw(address account, bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (address token, uint256 amount) = abi.decode(
            encodedData,
            (address, uint256)
        );

        address atoken = trustATokenAddr[token];
        require(atoken != address(0), "token error!");

        if (token == maticAddr) {
            pullAndApprove(atoken, account, wmaticGatewayAddr, amount);
            IWMATICGateway(wmaticGatewayAddr).withdrawETH(
                aaveV3PoolAddr,
                amount,
                account
            );
        } else {
            pullAndApprove(atoken, account, aaveV3PoolAddr, amount);
            ILendingPoolV3(aaveV3PoolAddr).withdraw(token, amount, account);
        }
        emit AaveWithDraw(token, amount, account);
    }

    function borrow(
        address token,
        uint256 amount,
        uint256 rateMode
    ) external onlyDelegation {
        if (token == maticAddr) {
            IWMATICGateway(wmaticGatewayAddr).borrowETH(
                aaveV3PoolAddr,
                amount,
                rateMode,
                referralCode
            );
        } else {
            ILendingPoolV3(aaveV3PoolAddr).borrow(
                token,
                amount,
                rateMode,
                referralCode,
                address(this)
            );
        }
        emit AaveBorrow(token, amount, address(this), rateMode);
    }

    function approveDelegation(uint256 amount) external onlyDelegation {
        IVariableDebtToken(debtMaticAddr).approveDelegation(
            wmaticGatewayAddr,
            amount
        );
    }

    function payback(
        address tokenAddr,
        uint256 amount,
        uint256 rateMode
    ) external onlyDelegation {
        if (tokenAddr == maticAddr) {
            if (amount == type(uint256).max) {
                amount = IERC20(debtMaticAddr).balanceOf(address(this));
                IWMATICGateway(wmaticGatewayAddr).repayETH{value: amount}(
                    aaveV3PoolAddr,
                    amount,
                    rateMode,
                    address(this)
                );
            } else {
                IWMATICGateway(wmaticGatewayAddr).repayETH{value: amount}(
                    aaveV3PoolAddr,
                    amount,
                    rateMode,
                    address(this)
                );
            }
        } else {
            ILendingPoolV3(aaveV3PoolAddr).repay(
                tokenAddr,
                amount,
                rateMode,
                address(this)
            );
        }
        emit AaveRepay(tokenAddr, amount, address(this), rateMode);
    }

    function claimRewards(
        address[] calldata assetAddress,
        uint256 amount,
        address reward
    ) external onlyDelegation {
        IRewardsController(incentivesController).claimRewardsToSelf(
            assetAddress,
            amount,
            reward
        );
        emit AaveClaim(incentivesController, amount);
    }

    function setUserEMode(uint8 categoryId) external onlyDelegation {
        ILendingPoolV3(aaveV3PoolAddr).setUserEMode(categoryId);
    }
}
