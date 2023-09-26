// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ISpokePool} from "../src/interfaces/ISpokePool.sol";
import {IHubPool} from "../src/interfaces/IHubPool.sol";
import {IAcceleratingDistributor} from "../src/interfaces/IAcceleratingDistributor.sol";
import {CrossChainStaker} from "../src/CrossChainStaker.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Test} from "forge-std/Test.sol";

contract ForkTest is Test {
    // the identifiers of the forks
    uint256 mainnetFork;
    IHubPool constant HUB_POOL = IHubPool(0xc186fA914353c44b2E33eBE05f21846F1048bEda);
    IAcceleratingDistributor constant ACCELERATING_DISTRIBUTOR =
        IAcceleratingDistributor(0x9040e41eF5E8b281535a96D9a48aCb8cfaBD9a48);
    ISpokePool constant SPOKE_POOL = ISpokePool(0x5c7BCd6E7De5423a257D81B442095A1a6ced35C5);
    address constant RELAYER_ADDRESS = 0x428AB2BA90Eba0a4Be7aF34C9Ac451ab061AC010;
    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    CrossChainStaker crossChainStaker;
    address userAddress;

    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

    // create two _different_ forks during setup
    function setUp() public {
        mainnetFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(mainnetFork);
        crossChainStaker = new CrossChainStaker(HUB_POOL, ACCELERATING_DISTRIBUTOR);
        userAddress = vm.createWallet("test across wallet").addr;
    }

    function test_RelayWorks() public {
        vm.prank(RELAYER_ADDRESS);
        SPOKE_POOL.fillRelay(
            userAddress,
            address(crossChainStaker),
            address(USDC),
            1e8,
            1e8,
            1,
            10,
            0,
            0,
            1,
            abi.encode(address(userAddress)),
            type(uint256).max
        );

        startHoax(userAddress);
        IERC20 lpToken = IERC20(HUB_POOL.pooledTokens(address(USDC)).lpToken);
        ACCELERATING_DISTRIBUTOR.exit(address(lpToken));
        HUB_POOL.removeLiquidity(address(USDC), lpToken.balanceOf(userAddress), false);

        // There could be some small loss due to conversion.
        assertApproxEqAbs(USDC.balanceOf(userAddress), 1e8, 1e3);

        vm.stopPrank();
    }

    function test_RevertIfMessageIsTooShort() public {
        vm.expectRevert();
        vm.prank(RELAYER_ADDRESS);
        SPOKE_POOL.fillRelay(
            userAddress,
            address(crossChainStaker),
            address(USDC),
            1e8,
            1e8,
            1,
            10,
            0,
            0,
            1,
            abi.encodePacked(address(userAddress)),
            type(uint256).max
        );
    }

    function test_RevertIfMessageIsTooLong() public {
        vm.expectRevert();
        vm.prank(RELAYER_ADDRESS);
        SPOKE_POOL.fillRelay(
            userAddress,
            address(crossChainStaker),
            address(USDC),
            1e8,
            1e8,
            1,
            10,
            0,
            0,
            1,
            abi.encodePacked(address(userAddress), bytes13(0)),
            type(uint256).max
        );
    }

    function test_DepositAndStake() public {
        vm.startPrank(RELAYER_ADDRESS);
        USDC.approve(address(crossChainStaker), 1e8);
        crossChainStaker.depositAndStake(USDC, 1e8);

        uint256 postStakeBalance = USDC.balanceOf(RELAYER_ADDRESS);

        IERC20 lpToken = IERC20(HUB_POOL.pooledTokens(address(USDC)).lpToken);
        ACCELERATING_DISTRIBUTOR.exit(address(lpToken));
        HUB_POOL.removeLiquidity(address(USDC), lpToken.balanceOf(RELAYER_ADDRESS), false);

        // There could be some small loss due to conversion.
        assertApproxEqAbs(USDC.balanceOf(RELAYER_ADDRESS) - postStakeBalance, 1e8, 1e3);

        vm.stopPrank();
    }

    function test_DepositAndDonateStake() public {
        vm.startPrank(RELAYER_ADDRESS);
        USDC.approve(address(crossChainStaker), 1e8);
        crossChainStaker.depositAndDonateStake(USDC, 1e8, userAddress);
        vm.stopPrank();

        vm.startPrank(userAddress);
        IERC20 lpToken = IERC20(HUB_POOL.pooledTokens(address(USDC)).lpToken);
        ACCELERATING_DISTRIBUTOR.exit(address(lpToken));
        HUB_POOL.removeLiquidity(address(USDC), lpToken.balanceOf(userAddress), false);

        // There could be some small loss due to conversion.
        assertApproxEqAbs(USDC.balanceOf(userAddress), 1e8, 1e3);

        vm.stopPrank();
    }
}
