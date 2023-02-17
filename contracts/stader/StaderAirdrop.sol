// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract StaderAirdrop is Pausable, Ownable {
    using SafeERC20 for IERC20;

    address public immutable token;
    uint256 public round;
    bytes32 public merkleRoot;
    mapping(uint256 => mapping(address => bool)) private claimed; //round x address if claimed

    constructor(address _token, address _admin) {
        token = _token;
        pause();
        _transferOwnership(_admin);
    }

    event UpdateMerkleRoot(uint256 newRound, bytes32 newMerkleRoot);
    event Claimed(uint256 round, address account, uint256 amount);

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    //Handle when someone else accidentally transfers assets to this contract, or if we
    //need to migration to a new contract.
    function sweep(address[] memory _tokens, address _receiver)
        external
        onlyOwner
        whenPaused
    {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address _token = _tokens[i];
            if (_token == address(0)) continue;
            uint256 amount = IERC20(_token).balanceOf(address(this));
            if (amount > 0) {
                IERC20(_token).safeTransfer(_receiver, amount);
            }
        }
    }

    //If someone does not claim the reward in the x round, we will add to the x+1 round.
    //So he doesn't lose any reward.
    function updateMerkleRoot(bytes32 _newMerkleRoot)
        external
        onlyOwner
        whenPaused
    {
        merkleRoot = _newMerkleRoot;
        round++;
        unpause();

        emit UpdateMerkleRoot(round, _newMerkleRoot);
    }

    function isClaimed(address _account) public view returns (bool) {
        return claimed[round][_account];
    }

    function _setClaimed(address _account) internal {
        claimed[round][_account] = true;
    }

    function claim(
        address _account,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external whenNotPaused {
        require(
            !isClaimed(_account),
            "MerkleDistributor: Drop already claimed."
        );

        bytes32 node = keccak256(abi.encodePacked(_account, _amount));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );

        _setClaimed(_account);
        IERC20(token).safeTransfer(_account, _amount);

        emit Claimed(round, _account, _amount);
    }
}
