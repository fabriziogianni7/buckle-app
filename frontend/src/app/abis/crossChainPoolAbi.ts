export const crossChainPoolAbi = [
    {
        "type": "constructor",
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
            { "name": "_router", "type": "address", "internalType": "address" },
            {
                "name": "_otherChainUnderlyingToken",
                "type": "address",
                "internalType": "address"
            }
        ],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "addCrossChainSender",
        "inputs": [
            { "name": "_sender", "type": "address", "internalType": "address" }
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "allowance",
        "inputs": [
            { "name": "owner", "type": "address", "internalType": "address" },
            { "name": "spender", "type": "address", "internalType": "address" }
        ],
        "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "approve",
        "inputs": [
            { "name": "spender", "type": "address", "internalType": "address" },
            { "name": "value", "type": "uint256", "internalType": "uint256" }
        ],
        "outputs": [{ "name": "", "type": "bool", "internalType": "bool" }],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "balanceOf",
        "inputs": [
            { "name": "account", "type": "address", "internalType": "address" }
        ],
        "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "calculateAmountToRedeem",
        "inputs": [
            { "name": "_lptAmount", "type": "uint256", "internalType": "uint256" }
        ],
        "outputs": [
            {
                "name": "redeemCurrentChain",
                "type": "uint256",
                "internalType": "uint256"
            },
            {
                "name": "redeemCrossChain",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "calculateBuckleAppFees",
        "inputs": [
            { "name": "_value", "type": "uint256", "internalType": "uint256" }
        ],
        "outputs": [
            { "name": "fees", "type": "uint256", "internalType": "uint256" }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "calculateLPTinExchangeOfUnderlying",
        "inputs": [
            {
                "name": "_amountOfUnderlyingToDeposit",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
        "stateMutability": "view"
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
        "name": "decimals",
        "inputs": [],
        "outputs": [{ "name": "", "type": "uint8", "internalType": "uint8" }],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "deposit",
        "inputs": [
            {
                "name": "_token",
                "type": "address",
                "internalType": "contract IERC20"
            },
            { "name": "_amount", "type": "uint256", "internalType": "uint256" }
        ],
        "outputs": [],
        "stateMutability": "payable"
    },
    {
        "type": "function",
        "name": "getCCipFeesForDeposit",
        "inputs": [
            { "name": "_value", "type": "uint256", "internalType": "uint256" }
        ],
        "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "getCCipFeesForRedeem",
        "inputs": [
            { "name": "_lptAmount", "type": "uint256", "internalType": "uint256" },
            { "name": "_to", "type": "address", "internalType": "address" }
        ],
        "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "getCcipFeesForTeleporting",
        "inputs": [
            { "name": "_value", "type": "uint256", "internalType": "uint256" },
            { "name": "_to", "type": "address", "internalType": "address" }
        ],
        "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "getCrossChainBalances",
        "inputs": [],
        "outputs": [
            {
                "name": "crossChainUnderlyingBalance",
                "type": "uint256",
                "internalType": "uint256"
            },
            {
                "name": "crossChainLiquidityPoolTokens",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "getCrossChainSenderAndSelector",
        "inputs": [],
        "outputs": [
            { "name": "", "type": "address", "internalType": "address" },
            { "name": "", "type": "uint64", "internalType": "uint64" }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "getOtherChainUnderlyingToken",
        "inputs": [],
        "outputs": [{ "name": "", "type": "address", "internalType": "address" }],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "getRedeemValueForLP",
        "inputs": [
            { "name": "_lptAmount", "type": "uint256", "internalType": "uint256" }
        ],
        "outputs": [
            { "name": "reedemValue", "type": "uint256", "internalType": "uint256" }
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
        "name": "getTotalProtocolBalances",
        "inputs": [],
        "outputs": [
            {
                "name": "totalUnderlyingBal",
                "type": "uint256",
                "internalType": "uint256"
            },
            { "name": "totalLptBal", "type": "uint256", "internalType": "uint256" }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "getUnderlyingToken",
        "inputs": [],
        "outputs": [
            { "name": "", "type": "address", "internalType": "contract IERC20" }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "getValueOfOneLpt",
        "inputs": [],
        "outputs": [
            { "name": "value", "type": "uint256", "internalType": "uint256" }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "name",
        "inputs": [],
        "outputs": [{ "name": "", "type": "string", "internalType": "string" }],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "redeem",
        "inputs": [
            { "name": "_lptAmount", "type": "uint256", "internalType": "uint256" },
            { "name": "_to", "type": "address", "internalType": "address" }
        ],
        "outputs": [],
        "stateMutability": "payable"
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
        "name": "symbol",
        "inputs": [],
        "outputs": [{ "name": "", "type": "string", "internalType": "string" }],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "teleport",
        "inputs": [
            { "name": "_value", "type": "uint256", "internalType": "uint256" },
            { "name": "_to", "type": "address", "internalType": "address" }
        ],
        "outputs": [],
        "stateMutability": "payable"
    },
    {
        "type": "function",
        "name": "totalSupply",
        "inputs": [],
        "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "transfer",
        "inputs": [
            { "name": "to", "type": "address", "internalType": "address" },
            { "name": "value", "type": "uint256", "internalType": "uint256" }
        ],
        "outputs": [{ "name": "", "type": "bool", "internalType": "bool" }],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "transferFrom",
        "inputs": [
            { "name": "from", "type": "address", "internalType": "address" },
            { "name": "to", "type": "address", "internalType": "address" },
            { "name": "value", "type": "uint256", "internalType": "uint256" }
        ],
        "outputs": [{ "name": "", "type": "bool", "internalType": "bool" }],
        "stateMutability": "nonpayable"
    },
    {
        "type": "event",
        "name": "Approval",
        "inputs": [
            {
                "name": "owner",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            },
            {
                "name": "spender",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            },
            {
                "name": "value",
                "type": "uint256",
                "indexed": false,
                "internalType": "uint256"
            }
        ],
        "anonymous": false
    },
    {
        "type": "event",
        "name": "DepositedAndMintedLpt",
        "inputs": [
            {
                "name": "lp",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            },
            {
                "name": "lptAmount",
                "type": "uint256",
                "indexed": true,
                "internalType": "uint256"
            },
            {
                "name": "underlyingAmount",
                "type": "uint256",
                "indexed": true,
                "internalType": "uint256"
            }
        ],
        "anonymous": false
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
        "name": "RedeemedCrossChain",
        "inputs": [
            {
                "name": "lp",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            },
            {
                "name": "underlyingAmount",
                "type": "uint256",
                "indexed": true,
                "internalType": "uint256"
            },
            {
                "name": "chainid",
                "type": "uint256",
                "indexed": false,
                "internalType": "uint256"
            },
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
        "name": "RedeemedCurrentChain",
        "inputs": [
            {
                "name": "lp",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            },
            {
                "name": "lptAmountBurnt",
                "type": "uint256",
                "indexed": true,
                "internalType": "uint256"
            },
            {
                "name": "underlyingAmount",
                "type": "uint256",
                "indexed": true,
                "internalType": "uint256"
            },
            {
                "name": "chainid",
                "type": "uint256",
                "indexed": false,
                "internalType": "uint256"
            }
        ],
        "anonymous": false
    },
    {
        "type": "event",
        "name": "TeleportStarted",
        "inputs": [
            {
                "name": "value",
                "type": "uint256",
                "indexed": true,
                "internalType": "uint256"
            },
            {
                "name": "to",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            }
        ],
        "anonymous": false
    },
    {
        "type": "event",
        "name": "Transfer",
        "inputs": [
            {
                "name": "from",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            },
            {
                "name": "to",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            },
            {
                "name": "value",
                "type": "uint256",
                "indexed": false,
                "internalType": "uint256"
            }
        ],
        "anonymous": false
    },
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
    { "type": "error", "name": "CrossChainPool__AmountTooSmall", "inputs": [] },
    {
        "type": "error",
        "name": "CrossChainPool__NotEnoughBalanceOnDestinationPool",
        "inputs": []
    },
    {
        "type": "error",
        "name": "CrossChainPool__NotEnoughBalanceToRedeem",
        "inputs": []
    },
    {
        "type": "error",
        "name": "CrossChainPool__NotEnoughBalanceToRedeemCrossChain",
        "inputs": []
    },
    {
        "type": "error",
        "name": "CrossChainPool__NotEnoughBalanceToRedeemCurrentChain",
        "inputs": []
    },
    { "type": "error", "name": "CrossChainPool__NotLP", "inputs": [] },
    {
        "type": "error",
        "name": "CrossChainPool__SenderOrSelectorNotAllowed",
        "inputs": []
    },
    {
        "type": "error",
        "name": "CrossChainPool__ShouldBeMoreThanZero",
        "inputs": []
    },
    {
        "type": "error",
        "name": "CrossChainPool__UserCCipFeesNotEnough",
        "inputs": []
    },
    {
        "type": "error",
        "name": "CrossChainPool__WrongUnderlying",
        "inputs": []
    },
    {
        "type": "error",
        "name": "ERC20InsufficientAllowance",
        "inputs": [
            { "name": "spender", "type": "address", "internalType": "address" },
            { "name": "allowance", "type": "uint256", "internalType": "uint256" },
            { "name": "needed", "type": "uint256", "internalType": "uint256" }
        ]
    },
    {
        "type": "error",
        "name": "ERC20InsufficientBalance",
        "inputs": [
            { "name": "sender", "type": "address", "internalType": "address" },
            { "name": "balance", "type": "uint256", "internalType": "uint256" },
            { "name": "needed", "type": "uint256", "internalType": "uint256" }
        ]
    },
    {
        "type": "error",
        "name": "ERC20InvalidApprover",
        "inputs": [
            { "name": "approver", "type": "address", "internalType": "address" }
        ]
    },
    {
        "type": "error",
        "name": "ERC20InvalidReceiver",
        "inputs": [
            { "name": "receiver", "type": "address", "internalType": "address" }
        ]
    },
    {
        "type": "error",
        "name": "ERC20InvalidSender",
        "inputs": [
            { "name": "sender", "type": "address", "internalType": "address" }
        ]
    },
    {
        "type": "error",
        "name": "ERC20InvalidSpender",
        "inputs": [
            { "name": "spender", "type": "address", "internalType": "address" }
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
    { "type": "error", "name": "ReentrancyGuardReentrantCall", "inputs": [] },
    {
        "type": "error",
        "name": "SafeERC20FailedOperation",
        "inputs": [
            { "name": "token", "type": "address", "internalType": "address" }
        ]
    }
]