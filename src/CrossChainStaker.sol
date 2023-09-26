// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import {IAcrossMessageHandler} from "./interfaces/IAcrossMessageHandler.sol";
import {IAcceleratingDistributor} from "./interfaces/IAcceleratingDistributor.sol";
import {IHubPool} from "./interfaces/IHubPool.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract CrossChainStaker is IAcrossMessageHandler {
    IHubPool public immutable hubPool;
    IAcceleratingDistributor public immutable acceleratingDistributor;

    constructor(IHubPool _hubPool, IAcceleratingDistributor _acceleratingDistributor) {
        hubPool = _hubPool;
        acceleratingDistributor = _acceleratingDistributor;
    }

    function handleAcrossMessage(address tokenSent, uint256 amount, bool, address, bytes memory message) external {
        (address userAddress) = abi.decode(message, (address));
        (IERC20 lpToken, uint256 lpAmount) = _deposit(tokenSent, amount);
        acceleratingDistributor.stakeFor(address(lpToken), lpAmount, userAddress);
    }

    function _deposit(address token, uint256 depositAmount) private returns (IERC20 lpToken, uint256 lpAmount) {
        IHubPool.PooledToken memory pooledToken = hubPool.pooledTokens(token);
        hubPool.addLiquidity(token, depositAmount);
        lpToken = IERC20(pooledToken.lpToken);
        lpAmount = lpToken.balanceOf(address(this));
    }
}
