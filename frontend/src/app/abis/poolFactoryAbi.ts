export const poolFactoryAbi = [
    {
        "type": "constructor",
        "inputs": [
            { "name": "_ccipRouter", "type": "address", "internalType": "address" },
            { "name": "_feeToken", "type": "address", "internalType": "address" }
        ],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "ccipReceive",
        "inputs": [
            {
                "name": "message",
                "type": "tuple",
                "internalType": "struct Client.Any2EVMMessage",
                "components": [
                    {
                        "name": "messageId",
                        "type": "bytes32",
                        "internalType": "bytes32"
                    },
                    {
                        "name": "sourceChainSelector",
                        "type": "uint64",
                        "internalType": "uint64"
                    },
                    { "name": "sender", "type": "bytes", "internalType": "bytes" },
                    { "name": "data", "type": "bytes", "internalType": "bytes" },
                    {
                        "name": "destTokenAmounts",
                        "type": "tuple[]",
                        "internalType": "struct Client.EVMTokenAmount[]",
                        "components": [
                            {
                                "name": "token",
                                "type": "address",
                                "internalType": "address"
                            },
                            {
                                "name": "amount",
                                "type": "uint256",
                                "internalType": "uint256"
                            }
                        ]
                    }
                ]
            }
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "deployCCPools",
        "inputs": [
            {
                "name": "_receiverFactory",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "_underlyingTokenOnSourceChain",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "_underlyingTokenOnDestinationChain",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "_destinationChainSelector",
                "type": "uint64",
                "internalType": "uint64"
            },
            { "name": "_poolName", "type": "string", "internalType": "string" }
        ],
        "outputs": [{ "name": "", "type": "address", "internalType": "address" }],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "deployPool",
        "inputs": [
            {
                "name": "_underlyingToken",
                "type": "address",
                "internalType": "address"
            },
            { "name": "_name", "type": "string", "internalType": "string" },
            {
                "name": "_crossChainSelector",
                "type": "uint64",
                "internalType": "uint64"
            },
            {
                "name": "_underlyingTokenOnDestinationChain",
                "type": "address",
                "internalType": "address"
            }
        ],
        "outputs": [
            { "name": "poolAddress", "type": "address", "internalType": "address" },
            { "name": "success", "type": "bool", "internalType": "bool" }
        ],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "getALlDeployedPoolsForChainSelector",
        "inputs": [
            { "name": "chainSelector", "type": "uint64", "internalType": "uint64" }
        ],
        "outputs": [
            { "name": "", "type": "address[]", "internalType": "address[]" }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "getLastReceivedMessageDetails",
        "inputs": [],
        "outputs": [
            { "name": "messageId", "type": "bytes32", "internalType": "bytes32" },
            { "name": "data", "type": "bytes", "internalType": "bytes" }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "getRouter",
        "inputs": [],
        "outputs": [{ "name": "", "type": "address", "internalType": "address" }],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "owner",
        "inputs": [],
        "outputs": [{ "name": "", "type": "address", "internalType": "address" }],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "renounceOwnership",
        "inputs": [],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "supportsInterface",
        "inputs": [
            { "name": "interfaceId", "type": "bytes4", "internalType": "bytes4" }
        ],
        "outputs": [{ "name": "", "type": "bool", "internalType": "bool" }],
        "stateMutability": "pure"
    },
    {
        "type": "function",
        "name": "transferOwnership",
        "inputs": [
            { "name": "newOwner", "type": "address", "internalType": "address" }
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "event",
        "name": "MessageReceived",
        "inputs": [
            {
                "name": "messageId",
                "type": "bytes32",
                "indexed": true,
                "internalType": "bytes32"
            }
        ],
        "anonymous": false
    },
    {
        "type": "event",
        "name": "OwnershipTransferred",
        "inputs": [
            {
                "name": "previousOwner",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            },
            {
                "name": "newOwner",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            }
        ],
        "anonymous": false
    },
    {
        "type": "event",
        "name": "PoolCreated",
        "inputs": [
            {
                "name": "pool",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            }
        ],
        "anonymous": false
    },
    {
        "type": "error",
        "name": "InvalidRouter",
        "inputs": [
            { "name": "router", "type": "address", "internalType": "address" }
        ]
    },
    {
        "type": "error",
        "name": "OwnableInvalidOwner",
        "inputs": [
            { "name": "owner", "type": "address", "internalType": "address" }
        ]
    },
    {
        "type": "error",
        "name": "OwnableUnauthorizedAccount",
        "inputs": [
            { "name": "account", "type": "address", "internalType": "address" }
        ]
    },
    {
        "type": "error",
        "name": "PoolFactory__CrossChainDeploymentFailed",
        "inputs": [{ "name": "call", "type": "bytes", "internalType": "bytes" }]
    },
    {
        "type": "error",
        "name": "PoolFactory__PoolDeploymentFailed",
        "inputs": []
    }
]