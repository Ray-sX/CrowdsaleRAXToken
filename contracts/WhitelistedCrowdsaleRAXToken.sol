// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./interfaces/ICrowdsale.sol";
import "./interfaces/IPancakeRouter.sol";
import "./CrowdsaleRAXToken.sol";

contract WhitelistedCrowdsaleRAXToken is CrowdsaleRAXToken, IWhitelistedCrowdsale {

    bytes32 public whitelistMerkleRoot;

    constructor(uint256 price_, uint256 raise_, address BUSD_, address USDT_, address USDC_, address RAX_, address pancakeRouter_, address factory_)
        CrowdsaleRAXToken(price_, raise_, BUSD_, USDT_, USDC_, RAX_, pancakeRouter_, factory_) {
    }

    function isInWhitelist(address user, bytes32[] memory proof) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(user));
        return MerkleProof.verify(proof, whitelistMerkleRoot, leaf);
    }

    function setWhitelist(bytes32 whitelistMerkleRoot_) external onlyOwner {
        whitelistMerkleRoot = whitelistMerkleRoot_;
    }

    function buy(address, uint256, uint256, address) external payable virtual override(ICrowdsale, CrowdsaleRAXToken) onlySalePeriod {
        revert("Sale: proof not given");
    }

    function buyWithProof(bytes32[] memory proof, address token, uint256 amountIn, uint256 minAmountOut, address referrer) external payable virtual override onlySalePeriod whenNotPaused nonReentrant {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, whitelistMerkleRoot, leaf), "Sale: invalid merkle proof");
        _buy(token, amountIn, minAmountOut, referrer);
    }
}