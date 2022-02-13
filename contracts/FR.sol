// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract FR is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    uint256 private constant PERCENTAGE_BASE = 100000;

    mapping(address => uint256) public tokenLeftover;

    receive() external payable {}

    function initialize() external initializer {
        __Ownable_init();
    }

    function swapExactEthForTokensUniV2(
        address router,
        address[] calldata path,
        uint256 amountEthMax,
        uint256 amountOutMin,
        uint256 deadline
    ) external onlyOwner returns (uint256 amountOutGet, uint256 amountOut) {
        uint256 tokenIndex = path.length - 1;
        address token = path[tokenIndex];

        IUniswapV2Router02 _router = IUniswapV2Router02(router);

        amountOut = _router.getAmountsOut(amountEthMax, path)[path.length - 1];

        amountOutGet = _router.swapExactETHForTokens{value: amountEthMax}(
            amountOutMin,
            path,
            address(this),
            deadline
        )[tokenIndex];

        tokenLeftover[token] += amountOutGet;
    }

    function swapExactTokensForEthUniV2(
        address router,
        address[] calldata path,
        uint256 slippage,
        uint256 deadline
    ) external onlyOwner returns (uint256 amountOutGet, uint256 amountOut) {
        uint256 lastIndex = path.length - 1;
        address token = path[0];

        uint256 amountToSwap = tokenLeftover[token];

        IUniswapV2Router02 _router = IUniswapV2Router02(router);

        amountOut = _router.getAmountsOut(amountToSwap, path)[path.length - 1];

        _approveIfNeeded(token, router, amountToSwap);

        amountOutGet = _router.swapExactTokensForETH(
            amountToSwap,
            (amountOut * PERCENTAGE_BASE) / (slippage + PERCENTAGE_BASE),
            path,
            address(this),
            deadline
        )[lastIndex];

        tokenLeftover[token] = 0;
    }

    function approve(
        address token,
        address spender,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).approve(spender, amount);
    }

    function withdrawEth(uint256 amount, address payable to)
        external
        onlyOwner
    {
        to.transfer(amount);
    }

    function withdrawTokens(
        address token,
        uint256 amount,
        address to
    ) external onlyOwner {
        require(to != address(0), "!address");

        IERC20(token).safeTransfer(to, amount);

        updateLeftover(token);

        if (tokenLeftover[token] == 0) return;

        if (tokenLeftover[token] >= amount) tokenLeftover[token] -= amount;
        else tokenLeftover[token] = 0;
    }

    function updateLeftover(address token) public {
        tokenLeftover[token] = IERC20(token).balanceOf(address(this));
    }

    function getReservesV2(
        address router,
        address tokenA,
        address tokenB
    ) external view returns (uint256 reserveA, uint256 reserveB) {
        IUniswapV2Pair pair = IUniswapV2Pair(
            IUniswapV2Factory(IUniswapV2Router02(router).factory()).getPair(
                tokenA,
                tokenB
            )
        );

        address token0 = tokenA < tokenB ? tokenA : tokenB;

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    function _approveIfNeeded(
        address token,
        address spender,
        uint256 transferAmount
    ) private {
        if (transferAmount > IERC20(token).allowance(address(this), spender))
            IERC20(token).approve(spender, type(uint256).max);
    }
}
