// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// D swaps DIMP/WMATIC for single path swaps and tokenIn/WMATIC/tokenOut for multi path swaps.
contract DIMPSwap is Ownable {
    using Math for uint256;

    ISwapRouter private immutable _swapRouter;
    IUniswapV3Factory private immutable _uniswapFactory;
    IQuoter private immutable _quoter;
    address private immutable _WMATIC;
    uint24 private _fee;

    constructor(
        IUniswapV3Factory uniswapFactory_,
        ISwapRouter swapRouter_,
        IQuoter quoter_,
        address WMATIC_
    ) Ownable(_msgSender()) {
        _uniswapFactory = uniswapFactory_;
        _swapRouter = swapRouter_;
        _quoter = quoter_;
        _WMATIC = WMATIC_;
        _fee = 3000;
    }

    function swapRouter() external view returns (ISwapRouter) {
        return _swapRouter;
    }

    function uniswapFactory() external view returns (IUniswapV3Factory) {
        return _uniswapFactory;
    }

    function WMATIC() external view returns (address) {
        return _WMATIC;
    }

    function fee() external view returns (uint24) {
        return _fee;
    }

    function setFee(uint24 fee_) external onlyOwner {
        _fee = fee_;
    }

    function _quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal returns (uint256 amountOut) {
        amountOut = _quoter.quoteExactInputSingle(tokenIn, tokenOut, _fee, amountIn, 0);
    }

    function _quoteExactInput(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal returns (uint256 amountOut) {
        amountOut = _quoter.quoteExactInput(
            abi.encodePacked(tokenIn, _fee, _WMATIC, _fee, tokenOut),
            amountIn
        );
    }

    function quoteExactInputSmartRouter(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external payable returns (uint256 amountOut) {
        address pool = _uniswapFactory.getPool(tokenIn, tokenOut, _fee);
        if (pool == address(0)) {
            return _quoteExactInput(tokenIn, tokenOut, amountIn);
        } else {
            return _quoteExactInputSingle(tokenIn, tokenOut, amountIn);
        }
    }

    function swapExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) public payable returns (uint256 amountOut) {
        if (tokenIn != _WMATIC) {
            TransferHelper.safeTransferFrom(tokenIn, _msgSender(), address(this), amountIn);
            TransferHelper.safeApprove(tokenIn, address(_swapRouter), amountIn);
        }

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: _fee,
            recipient: _msgSender(),
            deadline: block.timestamp + 2,
            amountIn: amountIn,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: 0
        });

        amountOut = _swapRouter.exactInputSingle{value: msg.value}(params);
    }

    function swapExactInput(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) public payable returns (uint256 amountOut) {
        if (tokenIn != _WMATIC) {
            TransferHelper.safeTransferFrom(tokenIn, _msgSender(), address(this), amountIn);
            TransferHelper.safeApprove(tokenIn, address(_swapRouter), amountIn);
        }

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: abi.encodePacked(tokenIn, _fee, _WMATIC, _fee, tokenOut),
            recipient: _msgSender(),
            deadline: block.timestamp + 2,
            amountIn: amountIn,
            amountOutMinimum: amountOutMinimum
        });
        amountOut = _swapRouter.exactInput{value: msg.value}(params);
    }

    function swapExactInputSmartRouter(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) external payable returns (uint256 amountOut) {
        if (tokenIn != _WMATIC) {
            TransferHelper.safeTransferFrom(tokenIn, _msgSender(), address(this), amountIn);
            TransferHelper.safeApprove(tokenIn, address(_swapRouter), amountIn);
        }

        address pool = _uniswapFactory.getPool(tokenIn, tokenOut, _fee);
        if (pool != address(0)) {
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: _fee,
                recipient: _msgSender(),
                deadline: block.timestamp + 2,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

            amountOut = _swapRouter.exactInputSingle{value: msg.value}(params);
        } else {
            ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
                path: abi.encodePacked(tokenIn, _fee, _WMATIC, _fee, tokenOut),
                recipient: _msgSender(),
                deadline: block.timestamp + 2,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum
            });
            amountOut = _swapRouter.exactInput{value: msg.value}(params);
        }
    }
}
