// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;


interface ISpokePool {
        function fillRelay(
        address depositor,
        address recipient,
        address destinationToken,
        uint256 amount,
        uint256 maxTokensToSend,
        uint256 repaymentChainId,
        uint256 originChainId,
        int64 realizedLpFeePct,
        int64 relayerFeePct,
        uint32 depositId,
        bytes memory message,
        uint256 maxCount
    ) external;
}