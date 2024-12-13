export const CONTRACT_ADDRESS = "0x32C97d9FA176b459C62B2aEBb21E0E7877BE712d";
export const CONTRACT_ABI = [
    {
        inputs: [
            { internalType: "string", name: "_name", type: "string" },
            { internalType: "uint256", name: "_favNum", type: "uint256" },
        ],
        name: "addPerson",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [],
        name: "retrieve",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [{ internalType: "uint256", name: "_favNum", type: "uint256" }],
        name: "store",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
    },
];
