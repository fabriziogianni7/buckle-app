export interface Pool {
    pool?: `0x${string}` | undefined;
    tokenCurrentChain?: `0x${string}` | undefined;
    tokenCrossChain?: `0x${string}` | undefined;
    crosschainSelector?: number
}