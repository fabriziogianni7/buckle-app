export const poolFactoryAbi = [
    {
        "type": "constructor",
        "inputs": [
            { "name": "_ccipRouter", "type": "address", "internalType": "address" },
            { "name": "_feeToken", "type": "address", "internalType": "address" },
            {
                "name": "_chainSelector",
                "type": "uint64",
                "internalType": "uint64"
            },
            { "name": "_priceFeed", "type": "address", "internalType": "address" }
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
        "name": "deployCCPoolsCreate2",
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
                "name": "_destinationChainId",
                "type": "uint256",
                "internalType": "uint256"
            },
            { "name": "_poolName", "type": "string", "internalType": "string" }
        ],
        "outputs": [{ "name": "", "type": "address", "internalType": "address" }],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "depositFeeToken",
        "inputs": [
            { "name": "_amount", "type": "uint256", "internalType": "uint256" }
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "getALlDeployedPoolsForChainSelector",
        "inputs": [
            { "name": "_chainSelector", "type": "uint64", "internalType": "uint64" }
        ],
        "outputs": [
            { "name": "", "type": "address[]", "internalType": "address[]" }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "getCcipRouter",
        "inputs": [],
        "outputs": [{ "name": "", "type": "address", "internalType": "address" }],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "getDeployedPoolsInCurrenChain",
        "inputs": [],
        "outputs": [
            { "name": "", "type": "address[]", "internalType": "address[]" }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "getFeeToken",
        "inputs": [],
        "outputs": [{ "name": "", "type": "address", "internalType": "address" }],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "getLastReceivedMessageDetails",
        "inputs": [],
        "outputs": [
            { "name": "", "type": "bytes32", "internalType": "bytes32" },
            { "name": "", "type": "bytes", "internalType": "bytes" }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "getLastSentMsg",
        "inputs": [],
        "outputs": [{ "name": "", "type": "bytes32", "internalType": "bytes32" }],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "getLinkUsdPrice",
        "inputs": [],
        "outputs": [{ "name": "", "type": "int256", "internalType": "int256" }],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "getNetworkDetails",
        "inputs": [
            { "name": "chainId", "type": "uint256", "internalType": "uint256" }
        ],
        "outputs": [
            {
                "name": "",
                "type": "tuple",
                "internalType": "struct Register.NetworkDetails",
                "components": [
                    {
                        "name": "chainSelector",
                        "type": "uint64",
                        "internalType": "uint64"
                    },
                    {
                        "name": "routerAddress",
                        "type": "address",
                        "internalType": "address"
                    },
                    {
                        "name": "linkAddress",
                        "type": "address",
                        "internalType": "address"
                    },
                    {
                        "name": "wrappedNativeAddress",
                        "type": "address",
                        "internalType": "address"
                    },
                    {
                        "name": "ccipBnMAddress",
                        "type": "address",
                        "internalType": "address"
                    },
                    {
                        "name": "ccipLnMAddress",
                        "type": "address",
                        "internalType": "address"
                    }
                ]
            }
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
        "name": "setNetworkDetails",
        "inputs": [
            { "name": "chainId", "type": "uint256", "internalType": "uint256" },
            {
                "name": "networkDetails",
                "type": "tuple",
                "internalType": "struct Register.NetworkDetails",
                "components": [
                    {
                        "name": "chainSelector",
                        "type": "uint64",
                        "internalType": "uint64"
                    },
                    {
                        "name": "routerAddress",
                        "type": "address",
                        "internalType": "address"
                    },
                    {
                        "name": "linkAddress",
                        "type": "address",
                        "internalType": "address"
                    },
                    {
                        "name": "wrappedNativeAddress",
                        "type": "address",
                        "internalType": "address"
                    },
                    {
                        "name": "ccipBnMAddress",
                        "type": "address",
                        "internalType": "address"
                    },
                    {
                        "name": "ccipLnMAddress",
                        "type": "address",
                        "internalType": "address"
                    }
                ]
            }
        ],
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
        "type": "function",
        "name": "withdrawFeeToken",
        "inputs": [],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "event",
        "name": "DeployCCSuccess",
        "inputs": [
            {
                "name": "deployedPool",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            },
            {
                "name": "underlyingOnCurrentChain",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            },
            {
                "name": "poolName",
                "type": "string",
                "indexed": true,
                "internalType": "string"
            },
            {
                "name": "sourceChainSelector",
                "type": "uint64",
                "indexed": false,
                "internalType": "uint64"
            },
            {
                "name": "underlyingTokenOnOtherChain",
                "type": "address",
                "indexed": false,
                "internalType": "address"
            }
        ],
        "anonymous": false
    },
    {
        "type": "event",
        "name": "FeeTokenDeposited",
        "inputs": [
            {
                "name": "sender",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            }
        ],
        "anonymous": false
    },
    {
        "type": "event",
        "name": "FeeTokenWithdrawn",
        "inputs": [],
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
            },
            {
                "name": "tokenCurrentChain",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            },
            {
                "name": "tokenCrossChain",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            },
            {
                "name": "crosschainSelector",
                "type": "uint64",
                "indexed": false,
                "internalType": "uint64"
            }
        ],
        "anonymous": false
    },
    { "type": "event", "name": "RandomSalt", "inputs": [], "anonymous": false },
    {
        "type": "error",
        "name": "AddressEmptyCode",
        "inputs": [
            { "name": "target", "type": "address", "internalType": "address" }
        ]
    },
    {
        "type": "error",
        "name": "AddressInsufficientBalance",
        "inputs": [
            { "name": "account", "type": "address", "internalType": "address" }
        ]
    },
    { "type": "error", "name": "Create2EmptyBytecode", "inputs": [] },
    { "type": "error", "name": "Create2FailedDeployment", "inputs": [] },
    {
        "type": "error",
        "name": "Create2InsufficientBalance",
        "inputs": [
            { "name": "balance", "type": "uint256", "internalType": "uint256" },
            { "name": "needed", "type": "uint256", "internalType": "uint256" }
        ]
    },
    { "type": "error", "name": "FailedInnerCall", "inputs": [] },
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
    },
    {
        "type": "error",
        "name": "SafeERC20FailedOperation",
        "inputs": [
            { "name": "token", "type": "address", "internalType": "address" }
        ]
    }
]