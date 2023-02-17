// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

interface IRewardsController {
    function REVISION() external view returns (uint256);

    function claimAllRewards(address[] calldata assets, address to)
        external
        returns (
            address[] calldata rewardsList,
            uint256[] calldata claimedAmounts
        );

    function claimAllRewardsOnBehalf(
        address[] calldata assets,
        address user,
        address to
    )
        external
        returns (
            address[] calldata rewardsList,
            uint256[] calldata claimedAmounts
        );

    function claimAllRewardsToSelf(address[] calldata assets)
        external
        returns (address[] memory rewardsList, uint256[] memory claimedAmounts);

    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to,
        address reward
    ) external returns (uint256);

    function claimRewardsOnBehalf(
        address[] calldata assets,
        uint256 amount,
        address user,
        address to,
        address reward
    ) external returns (uint256);

    function claimRewardsToSelf(
        address[] calldata assets,
        uint256 amount,
        address reward
    ) external returns (uint256);

    function getAllUserRewards(address[] calldata assets, address user)
        external
        view
        returns (
            address[] calldata rewardsList,
            uint256[] calldata unclaimedAmounts
        );

    function getAssetDecimals(address asset) external view returns (uint8);

    function getClaimer(address user) external view returns (address);

    function getDistributionEnd(address asset, address reward)
        external
        view
        returns (uint256);

    function getEmissionManager() external view returns (address);

    function getRewardOracle(address reward) external view returns (address);

    function getRewardsByAsset(address asset)
        external
        view
        returns (address[] memory);

    function getRewardsData(address asset, address reward)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getRewardsList() external view returns (address[] memory);

    function getTransferStrategy(address reward)
        external
        view
        returns (address);

    function getUserAccruedRewards(address user, address reward)
        external
        view
        returns (uint256);

    function getUserAssetIndex(
        address user,
        address asset,
        address reward
    ) external view returns (uint256);

    function getUserRewards(
        address[] calldata assets,
        address user,
        address reward
    ) external view returns (uint256);

    function handleAction(
        address user,
        uint256 totalSupply,
        uint256 userBalance
    ) external;

    function initialize(address emissionManager) external;

    function setClaimer(address user, address caller) external;

    function setDistributionEnd(
        address asset,
        address reward,
        uint32 newDistributionEnd
    ) external;

    function setEmissionManager(address emissionManager) external;

    function setEmissionPerSecond(
        address asset,
        address[] calldata rewards,
        uint88[] calldata newEmissionsPerSecond
    ) external;

    function setRewardOracle(address reward, address rewardOracle) external;

    function setTransferStrategy(address reward, address transferStrategy)
        external;
}
