// src/App.tsx
import { useState, useEffect } from "react";
import Web3 from "web3";
import { CONTRACT_ADDRESS, CONTRACT_ABI } from "./config/contract";

function App() {
    const [web3, setWeb3] = useState<Web3 | null>(null);
    const [account, setAccount] = useState<string>("");
    const [favNumber, setFavNumber] = useState<string>("");
    const [storedNumber, setStoredNumber] = useState<string>("");
    const [name, setName] = useState<string>("");

    useEffect(() => {
        const initWeb3 = async () => {
            if (window.ethereum) {
                const web3Instance = new Web3(window.ethereum);
                try {
                    await window.ethereum.request({
                        method: "eth_requestAccounts",
                    });
                    const accounts = await web3Instance.eth.getAccounts();
                    setWeb3(web3Instance);
                    setAccount(accounts[0]);
                } catch (error) {
                    console.error("User denied account access");
                }
            } else {
                console.log("Please install MetaMask!");
            }
        };

        initWeb3();
    }, []);

    const storeNumber = async () => {
        if (!web3) return;
        const contract = new web3.eth.Contract(CONTRACT_ABI, CONTRACT_ADDRESS);
        try {
            await contract.methods.store(favNumber).send({ from: account });
            alert("Number stored successfully!");
        } catch (error) {
            console.error("Error storing number:", error);
        }
    };

    const retrieveNumber = async () => {
        if (!web3) return;
        const contract = new web3.eth.Contract(CONTRACT_ABI, CONTRACT_ADDRESS);
        try {
            const result = await contract.methods.retrieve().call();
            setStoredNumber(result.toString());
        } catch (error) {
            console.error("Error retrieving number:", error);
        }
    };

    const addPerson = async () => {
        if (!web3) return;
        const contract = new web3.eth.Contract(CONTRACT_ABI, CONTRACT_ADDRESS);
        try {
            await contract.methods
                .addPerson(name, favNumber)
                .send({ from: account });
            alert("Person added successfully!");
        } catch (error) {
            console.error("Error adding person:", error);
        }
    };

    return (
        <div className="min-h-screen py-8 px-4 max-w-4xl mx-auto">
            <div className="bg-gray-800 rounded-lg p-8 shadow-xl">
                <h1 className="text-4xl font-bold mb-8 text-center text-purple-400">
                    SimpleStorage DApp
                </h1>

                {!web3 ? (
                    <div className="text-center text-red-400">
                        Please install MetaMask and connect your wallet!
                    </div>
                ) : (
                    <div className="space-y-8">
                        <div className="text-center text-sm text-gray-400">
                            Connected Account: {account}
                        </div>

                        <div className="space-y-4">
                            <div className="bg-gray-700 p-6 rounded-lg">
                                <h2 className="text-xl font-semibold mb-4 text-purple-300">
                                    Store Your Number
                                </h2>
                                <input
                                    type="number"
                                    value={favNumber}
                                    onChange={(e) =>
                                        setFavNumber(e.target.value)
                                    }
                                    className="w-full p-2 rounded bg-gray-600 text-white"
                                    placeholder="Enter your favorite number"
                                />
                                <button
                                    onClick={storeNumber}
                                    className="mt-4 w-full bg-purple-600 hover:bg-purple-700 text-white font-bold py-2 px-4 rounded transition-colors"
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
                                        className="flex-1 bg-purple-600 hover:bg-purple-700 text-white font-bold py-2 px-4 rounded transition-colors"
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
                                        onChange={(e) =>
                                            setName(e.target.value)
                                        }
                                        className="w-full p-2 rounded bg-gray-600 text-white"
                                        placeholder="Enter name"
                                    />
                                    <button
                                        onClick={addPerson}
                                        className="w-full bg-purple-600 hover:bg-purple-700 text-white font-bold py-2 px-4 rounded transition-colors"
                                    >
                                        Add Person
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}

export default App;
