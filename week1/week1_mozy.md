# BOOM LABS 1차 Todo (mozy)

<br />

## 과제1. 메타마스크 지갑 생성 / 메타마스크로 이더 송금

### 1. 거래소 지갑은 여러 블록체인 네트워크의 개인 키를 가지고 있는건가?

### 2. 처음에 업비트 거래소 서비스를 사용하여 이더를 옮기려고 하니 제약사항이 있어 빗썸 거래소를 사용하였다. 업비트 거래소가 아닌 `업비트 오픈 API`, `pyupbit`를 사용한다면 가능할까?

> 결론은 못했다....

```python
import pyupbit

## 로그인
access = "73kVqowGQOGEjdR31221j31j2ifekjkgjekgjekg"          # 본인 값으로 변경
secret = "egjekgj3iekeEEkej3i3j3iejjwiEejiejeEeijg"          # 본인 값으로 변경
upbit = pyupbit.Upbit(access, secret)
```

```python
## 코인 출금 함수 : withdraw_coin
help(upbit.withdraw_coin)
```

```
Help on method withdraw_coin in module pyupbit.exchange_api:

withdraw_coin(currency, amount, address, secondary_address='None', transaction_type='default', contain_req=False) method of pyupbit.exchange_api.Upbit instance
    코인 출금
    :param currency: Currency symbol
    :param amount: 주문 가격
    :param address: 출금 지갑 주소
    :param secondary_address: 2차 출금주소 (필요한 코인에 한해서)
    :param transaction_type: 출금 유형
    :param contain_req: Remaining-Req 포함여부
    :return:
```

```python
currency = 'ETH'
amount = 0.025
wallet_address = '0xf6Bd559CAa721cAc307DCeB6194AF0B8fD175749' # my metamask wallet address

upbit.withdraw_coin(currency=currency, amount=amount, address=wallet_address)
```

```
{'error': {'name': 'withdraw_address_not_registered',
  'message': '등록된 출금 주소가 아닙니다.'}}
```

** upbit 주소로만 이동 가능한가 보다... **

### 3. 메타마스크 지갑에 연결시 패스워드를 입력한다. 어떤 방식(알고리즘, 사용되는 데이터)으로 키 정보를 만드는 걸까? (지난 수업 시간에 비대칭 알고리즘을 설명해 주셨는데...)

<br />

## 과제2. Ethereum → Polygon 옮기기

- Pending이 생각보다 오래걸린다.

- 이더리움 수수료/가스비가 진짜 비싸다...

> [Transaction Details](https://etherscan.io/tx/0x1833bb8418aa8111d7e9a8dd2f40c03356ea9e8cc001292dab783ab03f037a56)

[Uniswap V3 : Router 2](https://etherscan.io/address/0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45) 스마트 컨트랙트를 사용하여 스왑

```solidity
// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/libraries/SafeCast.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-periphery/contracts/libraries/Path.sol';
import '@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol';
import '@uniswap/v3-periphery/contracts/libraries/CallbackValidation.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './interfaces/IV3SwapRouter.sol';
import './base/PeripheryPaymentsWithFeeExtended.sol';
import './base/OracleSlippage.sol';
import './libraries/Constants.sol';

/// @title Uniswap V3 Swap Router
/// @notice Router for stateless execution of swaps against Uniswap V3
abstract contract V3SwapRouter is IV3SwapRouter, PeripheryPaymentsWithFeeExtended, OracleSlippage {
    using Path for bytes;
    using SafeCast for uint256;

    /// @dev Used as the placeholder value for amountInCached, because the computed amount in for an exact output swap
    /// can never actually be this value
    uint256 private constant DEFAULT_AMOUNT_IN_CACHED = type(uint256).max;

    /// @dev Transient storage variable used for returning the computed amount in for an exact output swap.
    uint256 private amountInCached = DEFAULT_AMOUNT_IN_CACHED;

    /// @dev Returns the pool for the given token pair and fee. The pool contract may or may not exist.
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) private view returns (IUniswapV3Pool) {
        return IUniswapV3Pool(PoolAddress.computeAddress(factory, PoolAddress.getPoolKey(tokenA, tokenB, fee)));
    }

    struct SwapCallbackData {
        bytes path;
        address payer;
    }

    /// @inheritdoc IUniswapV3SwapCallback
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported
        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
        (address tokenIn, address tokenOut, uint24 fee) = data.path.decodeFirstPool();
        CallbackValidation.verifyCallback(factory, tokenIn, tokenOut, fee);

        (bool isExactInput, uint256 amountToPay) =
            amount0Delta > 0
                ? (tokenIn < tokenOut, uint256(amount0Delta))
                : (tokenOut < tokenIn, uint256(amount1Delta));

        if (isExactInput) {
            pay(tokenIn, data.payer, msg.sender, amountToPay);
        } else {
            // either initiate the next swap or pay
            if (data.path.hasMultiplePools()) {
                data.path = data.path.skipToken();
                exactOutputInternal(amountToPay, msg.sender, 0, data);
            } else {
                amountInCached = amountToPay;
                // note that because exact output swaps are executed in reverse order, tokenOut is actually tokenIn
                pay(tokenOut, data.payer, msg.sender, amountToPay);
            }
        }
    }

    /// @dev Performs a single exact input swap
    function exactInputInternal(
        uint256 amountIn,
        address recipient,
        uint160 sqrtPriceLimitX96,
        SwapCallbackData memory data
    ) private returns (uint256 amountOut) {
        // find and replace recipient addresses
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        (address tokenIn, address tokenOut, uint24 fee) = data.path.decodeFirstPool();

        bool zeroForOne = tokenIn < tokenOut;

        (int256 amount0, int256 amount1) =
            getPool(tokenIn, tokenOut, fee).swap(
                recipient,
                zeroForOne,
                amountIn.toInt256(),
                sqrtPriceLimitX96 == 0
                    ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                    : sqrtPriceLimitX96,
                abi.encode(data)
            );

        return uint256(-(zeroForOne ? amount1 : amount0));
    }

    /// @inheritdoc IV3SwapRouter
    function exactInputSingle(ExactInputSingleParams memory params)
        external
        payable
        override
        returns (uint256 amountOut)
    {
        // use amountIn == Constants.CONTRACT_BALANCE as a flag to swap the entire balance of the contract
        bool hasAlreadyPaid;
        if (params.amountIn == Constants.CONTRACT_BALANCE) {
            hasAlreadyPaid = true;
            params.amountIn = IERC20(params.tokenIn).balanceOf(address(this));
        }

        amountOut = exactInputInternal(
            params.amountIn,
            params.recipient,
            params.sqrtPriceLimitX96,
            SwapCallbackData({
                path: abi.encodePacked(params.tokenIn, params.fee, params.tokenOut),
                payer: hasAlreadyPaid ? address(this) : msg.sender
            })
        );
        require(amountOut >= params.amountOutMinimum, 'Too little received');
    }

    /// @inheritdoc IV3SwapRouter
    function exactInput(ExactInputParams memory params) external payable override returns (uint256 amountOut) {
        // use amountIn == Constants.CONTRACT_BALANCE as a flag to swap the entire balance of the contract
        bool hasAlreadyPaid;
        if (params.amountIn == Constants.CONTRACT_BALANCE) {
            hasAlreadyPaid = true;
            (address tokenIn, , ) = params.path.decodeFirstPool();
            params.amountIn = IERC20(tokenIn).balanceOf(address(this));
        }

        address payer = hasAlreadyPaid ? address(this) : msg.sender;

        while (true) {
            bool hasMultiplePools = params.path.hasMultiplePools();

            // the outputs of prior swaps become the inputs to subsequent ones
            params.amountIn = exactInputInternal(
                params.amountIn,
                hasMultiplePools ? address(this) : params.recipient, // for intermediate swaps, this contract custodies
                0,
                SwapCallbackData({
                    path: params.path.getFirstPool(), // only the first pool in the path is necessary
                    payer: payer
                })
            );

            // decide whether to continue or terminate
            if (hasMultiplePools) {
                payer = address(this);
                params.path = params.path.skipToken();
            } else {
                amountOut = params.amountIn;
                break;
            }
        }

        require(amountOut >= params.amountOutMinimum, 'Too little received');
    }

    /// @dev Performs a single exact output swap
    function exactOutputInternal(
        uint256 amountOut,
        address recipient,
        uint160 sqrtPriceLimitX96,
        SwapCallbackData memory data
    ) private returns (uint256 amountIn) {
        // find and replace recipient addresses
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        (address tokenOut, address tokenIn, uint24 fee) = data.path.decodeFirstPool();

        bool zeroForOne = tokenIn < tokenOut;

        (int256 amount0Delta, int256 amount1Delta) =
            getPool(tokenIn, tokenOut, fee).swap(
                recipient,
                zeroForOne,
                -amountOut.toInt256(),
                sqrtPriceLimitX96 == 0
                    ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                    : sqrtPriceLimitX96,
                abi.encode(data)
            );

        uint256 amountOutReceived;
        (amountIn, amountOutReceived) = zeroForOne
            ? (uint256(amount0Delta), uint256(-amount1Delta))
            : (uint256(amount1Delta), uint256(-amount0Delta));
        // it's technically possible to not receive the full output amount,
        // so if no price limit has been specified, require this possibility away
        if (sqrtPriceLimitX96 == 0) require(amountOutReceived == amountOut);
    }

    /// @inheritdoc IV3SwapRouter
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        override
        returns (uint256 amountIn)
    {
        // avoid an SLOAD by using the swap return data
        amountIn = exactOutputInternal(
            params.amountOut,
            params.recipient,
            params.sqrtPriceLimitX96,
            SwapCallbackData({path: abi.encodePacked(params.tokenOut, params.fee, params.tokenIn), payer: msg.sender})
        );

        require(amountIn <= params.amountInMaximum, 'Too much requested');
        // has to be reset even though we don't use it in the single hop case
        amountInCached = DEFAULT_AMOUNT_IN_CACHED;
    }

    /// @inheritdoc IV3SwapRouter
    function exactOutput(ExactOutputParams calldata params) external payable override returns (uint256 amountIn) {
        exactOutputInternal(
            params.amountOut,
            params.recipient,
            0,
            SwapCallbackData({path: params.path, payer: msg.sender})
        );

        amountIn = amountInCached;
        require(amountIn <= params.amountInMaximum, 'Too much requested');
        amountInCached = DEFAULT_AMOUNT_IN_CACHED;
    }
}
```

아직 소스 이해는 되지않는다...

<br />

## 과제3. Opensea 에서 Polygon 기반 NFT 구매 (optional)

<br />

## 과제4. Polygon 기반 Lending protocol으로 예치하고, 대출해보기

- metamask 에 mumbai 테스트넷 추가

- mumbai faucet

처리가 빠르다..?
