# FullMath in Huff
## Huff
Huff is a low-level programming language designed for developing highly optimized smart contracts that run on the Ethereum Virtual Machine (EVM). Huff does not hide the inner workings of the EVM and instead exposes its programming stack to the developer for manual manipulation.

## FullMathHuff
FullMathHuff is a re-implementation of Uniswap's `FullMath.sol` in Huff. The contracts aren't unique to Uniswap and several versions exist but their code served as the template for writing out the Huff. A test-driven development philosophy was followed to implement. The test cases were copied from [Solady](https://github.com/Vectorized/solady/blob/main/test/FixedPointMathLib.t.sol) since the Uniswap test cases were in javascript and Solidity tests were required to use Foundry.

## Gas Snapshots
Huff, of course, is designed to write *highly* optimized contracts for the EVM. While Uniswap's `FullMath.sol` was already highly optimized, the Huff reimplementation still was able to eek out gas improvements. Numbers can be found in `.gas-snapshot`.
