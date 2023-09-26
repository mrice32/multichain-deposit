// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import {IAcrossMessageHandler} from "./interfaces/IAcrossMessageHandler.sol";
import {IAcceleratingDistributor} from "./interfaces/IAcceleratingDistributor.sol";
import {IHubPool} from "./interfaces/IHubPool.sol";

contract CrossChainStaker is IAcrossMessageHandler {
    IHubPool public immutable hubPool;
    IAcceleratingDistributor public immutable acceleratingDistributor;

    constructor(IHubPool _hubPool, IAcceleratingDistributor _acceleratingDistributor) {
        hubPool = _hubPool;
        acceleratingDistributor = _acceleratingDistributor;
    }

    function handleAcrossMessage(
        address tokenSent,
        uint256 amount,
        bool fillCompleted,
        address relayer,
        bytes memory message
    ) external {}

    function _deposit(address token, uint256 amount) private returns (address lpToken, uint256 amount) {
        IHubPool.PooledToken memory pooledToken = hubPool.pooledTokens(token);
        hubPool.addLiquidity(token, amount);
    }
}
