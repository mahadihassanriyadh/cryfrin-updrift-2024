// src/App.tsx
import { useState } from "react";
import Web3 from "web3";
import { CONTRACT_ADDRESS, CONTRACT_ABI } from "./config/contract";
import type { MetaMaskInpageProvider } from "@metamask/providers";

declare global {
    interface Window {
        ethereum?: MetaMaskInpageProvider;
    }
}

function App() {
    const [web3, setWeb3] = useState<Web3 | null>(null);
    const [account, setAccount] = useState<string>("");
    const [favNumber, setFavNumber] = useState<string>("");
    const [storedNumber, setStoredNumber] = useState<string>("");
    const [name, setName] = useState<string>("");

    const connectWallet = async () => {
        if (window.ethereum) {
            try {
                const web3Instance = new Web3(window.ethereum);
                await window.ethereum.request({
                    method: "eth_requestAccounts",
                });
                const accounts = await web3Instance.eth.getAccounts();
                setWeb3(web3Instance);
                setAccount(accounts[0]);
            } catch (error: unknown) {
                console.error("User denied account access", error);
            }
        } else {
            alert("Please install MetaMask!");
        }
    };

    const storeNumber = async () => {
        if (!web3 || !account) return;
        const contract = new web3.eth.Contract(CONTRACT_ABI, CONTRACT_ADDRESS);
        try {
            await contract.methods.store(favNumber).send({ from: account });
            alert("Number stored successfully!");
        } catch (error: unknown) {
            console.error("Error storing number:", error);
        }
    };

    const retrieveNumber = async () => {
        if (!web3 || !account) return;
        const contract = new web3.eth.Contract(CONTRACT_ABI, CONTRACT_ADDRESS);
        try {
            const result: number = await contract.methods.retrieve().call();
            setStoredNumber(result.toString());
        } catch (error: unknown) {
            console.error("Error retrieving number:", error);
        }
    };

    const addPerson = async () => {
        if (!web3 || !account) return;
        const contract = new web3.eth.Contract(CONTRACT_ABI, CONTRACT_ADDRESS);
        try {
            await contract.methods
                .addPerson(name, favNumber)
                .send({ from: account });
            alert("Person added successfully!");
        } catch (error: unknown) {
            console.error("Error adding person:", error);
        }
    };

    return (
        <div className="min-h-screen py-8 px-4 max-w-4xl mx-auto">
            <div className="bg-gray-800 rounded-lg p-8 shadow-xl">
                <h1 className="text-4xl font-bold mb-8 text-center text-purple-400">
                    SimpleStorage DApp
                </h1>

                <div className="mb-8 text-center">
                    {!account ? (
                        <button
                            onClick={connectWallet}
                            className="bg-purple-600 hover:bg-purple-700 text-white font-bold py-2 px-6 rounded-lg transition-colors"
                        >
                            Connect Wallet
                        </button>
                    ) : (
                        <div className="text-sm text-gray-400">
                            Connected: {account.slice(0, 6)}...
                            {account.slice(-4)}
                        </div>
                    )}
                </div>

                <div className="space-y-8">
                    <div className="bg-gray-700 p-6 rounded-lg">
                        <h2 className="text-xl font-semibold mb-4 text-purple-300">
                            Store Your Number
                        </h2>
                        <input
                            type="number"
                            value={favNumber}
                            onChange={(e) => setFavNumber(e.target.value)}
                            className="w-full p-2 rounded bg-gray-600 text-white"
                            placeholder="Enter your favorite number"
                            disabled={!account}
                        />
                        <button
                            onClick={storeNumber}
                            className={`mt-4 w-full font-bold py-2 px-4 rounded transition-colors ${
                                account
                                    ? "bg-purple-600 hover:bg-purple-700 text-white"
                                    : "bg-gray-600 text-gray-400 cursor-not-allowed"
                            }`}
                            disabled={!account}
                        >
                            Store Number
                        </button>
                    </div>

                    <div className="bg-gray-700 p-6 rounded-lg">
                        <h2 className="text-xl font-semibold mb-4 text-purple-300">
                            Retrieve Number
                        </h2>
                        <div className="flex space-x-4">
                            <button
                                onClick={retrieveNumber}
                                className={`flex-1 font-bold py-2 px-4 rounded transition-colors ${
                                    account
                                        ? "bg-purple-600 hover:bg-purple-700 text-white"
                                        : "bg-gray-600 text-gray-400 cursor-not-allowed"
                                }`}
                                disabled={!account}
                            >
                                Get Number
                            </button>
                            <div className="flex-1 p-2 bg-gray-600 rounded text-center">
                                {storedNumber || "No number retrieved"}
                            </div>
                        </div>
                    </div>

                    <div className="bg-gray-700 p-6 rounded-lg">
                        <h2 className="text-xl font-semibold mb-4 text-purple-300">
                            Add Person
                        </h2>
                        <div className="space-y-4">
                            <input
                                type="text"
                                value={name}
                                onChange={(e) => setName(e.target.value)}
                                className="w-full p-2 rounded bg-gray-600 text-white"
                                placeholder="Enter name"
                                disabled={!account}
                            />
                            <button
                                onClick={addPerson}
                                className={`w-full font-bold py-2 px-4 rounded transition-colors ${
                                    account
                                        ? "bg-purple-600 hover:bg-purple-700 text-white"
                                        : "bg-gray-600 text-gray-400 cursor-not-allowed"
                                }`}
                                disabled={!account}
                            >
                                Add Person
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}

export default App;
