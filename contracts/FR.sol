// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract FR is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant PERCENTAGE_BASE = 100000;

    mapping(address => uint256) tokenLeftover;

    receive() external payable {}

    function swapExactEthForTokensUniV2(
        address router,
        address[] calldata path,
        uint256 amountEth, // todo calculate amount inside this function
        uint256 maxSlippage,
        uint256 deadline
    )
        external
        onlyOwner
        returns (
            uint256 amountOutGet,
            uint256 amountOutMin,
            uint256 priceImpact
        )
    {
        uint256 tokenIndex = path.length - 1;
        address token = path[tokenIndex];

        IUniswapV2Router02 _router = IUniswapV2Router02(router);

        uint256 amountOut = _router.getAmountsOut(amountEth, path)[tokenIndex];

        amountOutMin = subSlippage(amountOut, maxSlippage);
        // todo: calculate price impact

        amountOutGet = _router.swapExactETHForTokens{value: amountEth}(
            amountOutMin,
            path,
            address(this),
            deadline
        )[tokenIndex];
        // todo

        tokenLeftover[token] = tokenLeftover[token].add(amountOutGet);
    }

    function swapExactTokensForEthUniV2(
        address router,
        address[] calldata path,
        uint256 maxSlippage,
        uint256 deadline
    )
        external
        onlyOwner
        returns (uint256 amountOutGet, uint256 amountOutEthMin)
    {
        uint256 lastIndex = path.length - 1;
        address token = path[0];

        uint256 amountToSwap = tokenLeftover[token];

        IUniswapV2Router02 _router = IUniswapV2Router02(router);

        uint256 amountOutEth = _router.getAmountsOut(amountToSwap, path)[
            lastIndex
        ];

        amountOutEthMin = subSlippage(amountOutEth, maxSlippage);

        amountOutGet = _router.swapExactTokensForETH(
            amountToSwap,
            amountOutEthMin,
            path,
            address(this),
            deadline
        )[lastIndex];

        tokenLeftover[token] = 0;
    }

    function withdrawEth(uint256 amount) external onlyOwner {
        payable(address(msg.sender)).transfer(amount);
    }

    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amount);
        if (tokenLeftover[msg.sender] >= amount)
            tokenLeftover[msg.sender] = tokenLeftover[msg.sender].sub(amount);
    }

    function subSlippage(uint256 val, uint256 slippage)
        private
        pure
        returns (uint256)
    {
        return val.sub(val.mul(slippage).div(PERCENTAGE_BASE));
    }
}
