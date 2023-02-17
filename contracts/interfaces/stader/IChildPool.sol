// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IChildPool {
    struct MaticXSwapRequest {
        uint256 amount;
        uint256 requestTime;
        uint256 withdrawalTime;
    }

    function version() external view returns (string memory);

    function claimedMatic() external view returns (uint256);

    function maticXSwapLockPeriod() external view returns (uint256);

    function treasury() external view returns (address payable);

    function instantPoolOwner() external view returns (address payable);

    function instantPoolMatic() external view returns (uint256);

    function instantPoolMaticX() external view returns (uint256);

    function instantWithdrawalFees() external view returns (uint256);

    function instantWithdrawalFeeBps() external view returns (uint256);

    function provideInstantPoolMatic() external payable;

    function provideInstantPoolMaticX(uint256 _amount) external;

    function withdrawInstantPoolMaticX(uint256 _amount) external;

    function withdrawInstantPoolMatic(uint256 _amount) external;

    function setMaticXSwapLockPeriod(uint256 _hours) external;

    function setTreasury(address payable _address) external;

    function setInstantPoolOwner(address payable _address) external;

    function setFxStateChildTunnel(address _address) external;

    function setInstantWithdrawalFeeBps(uint256 _feeBps) external;

    function setTrustedForwarder(address _address) external;

    function setVersion(string calldata _version) external;

    function togglePause() external;

    function withdrawInstantWithdrawalFees(uint256 _amount) external;

    function swapMaticForMaticXViaInstantPool() external payable;

    ///@dev returns maticXSwapLockPeriod or 24 hours (default value) in seconds
    function getMaticXSwapLockPeriod() external view returns (uint256);

    ///@dev request maticX->matic swap from instant pool
    function requestMaticXSwap(uint256 _amount) external returns (uint256);

    function getUserMaticXSwapRequests(address _address)
        external
        view
        returns (MaticXSwapRequest[] memory);

    ///@dev claim earlier requested maticX->matic swap from instant pool
    function claimMaticXSwap(uint256 _idx) external;

    ///@dev it is disabled for now!
    // TODO: it is disabled for now!
    function swapMaticXForMaticViaInstantPool(uint256 _amount) external;

    function convertMaticXToMatic(uint256 _balance)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function convertMaticToMaticX(uint256 _balance)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getAmountAfterInstantWithdrawalFees(uint256 _amount)
        external
        view
        returns (uint256, uint256);

    function getContracts()
        external
        view
        returns (
            address _fxStateChildTunnel,
            address _maticX,
            address _trustedForwarder
        );

    function isTrustedForwarder(address _address) external view returns (bool);
}
