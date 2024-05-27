export interface Pool {
    pool?: `0x${string}` | undefined;
    tokenCurrentChain?: `0x${string}` | undefined;
    tokenCrossChain?: `0x${string}` | undefined;
    crosschainSelector?: number
}

export interface Deposit {
    address: string;
    args: {
        lp: `0x${string}`;
        lptAmount: bigint;
        underlyingAmount: bigint;
    };
    blockHash: string;
    blockNumber: bigint;
    data: string;
    eventName: string;
    logIndex: number;
    removed: boolean;
    topics: string[];
    transactionHash: string;
    transactionIndex: number;
};

export interface UserDepositEvent {
    address: `0x${string}` // pool address
    args: {
        lp: `0x${string}`
        lptAmount: bigint
        underlyingAmount: bigint
    }
    transactionHash: `0x${string}`
}

export interface UserTeleportEvent {
    address: `0x${string}` // pool address
    args: {
        value: bigint
        to: `0x${string}`
    }
    transactionHash: `0x${string}`
}
export interface UserDeposit {
    poolAddress: `0x${string}`,
    lptAmount: bigint,
    underlyingAmount: bigint,
    txHash: `0x${string}`,
}
export interface UserTeleport {
    poolAddress: `0x${string}`,
    value: bigint,
    to: `0x${string}`,
    txHash: `0x${string}`,
}