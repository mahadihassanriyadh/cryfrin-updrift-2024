// src/App.tsx
import { useState, useEffect, useCallback } from "react";
import Web3 from "web3";
import { CONTRACT_ADDRESS, CONTRACT_ABI } from "./config/contract";
import type { MetaMaskInpageProvider } from "@metamask/providers";

declare global {
    interface Window {
        ethereum?: MetaMaskInpageProvider;
    }
}

interface Person {
    name: string;
    favNum: string;
}

interface PersonResponse {
    name: string;
    favNum: string;
}

function App() {
    const [web3, setWeb3] = useState<Web3 | null>(null);
    const [account, setAccount] = useState<string>("");
    const [storeNumber, setStoreNumber] = useState<string>("");
    const [storedNumber, setStoredNumber] = useState<string>("");
    const [name, setName] = useState<string>("");
    const [personFavNumber, setPersonFavNumber] = useState<string>("");
    const [people, setPeople] = useState<Person[]>([]);

    // Loading states
    const [isStoring, setIsStoring] = useState(false);
    const [isRetrieving, setIsRetrieving] = useState(false);
    const [isAddingPerson, setIsAddingPerson] = useState(false);
    const [isRefreshing, setIsRefreshing] = useState(false);

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

    const getPeople = useCallback(async () => {
        if (!web3) return;
        setIsRefreshing(true);
        const contract = new web3.eth.Contract(CONTRACT_ABI, CONTRACT_ADDRESS);
        try {
            let index = 0;
            const peopleList: Person[] = [];

            while (true) {
                try {
                    const person = (await contract.methods
                        .dynamicListOfPeople(index)
                        .call()) as PersonResponse;
                    peopleList.push({
                        name: person.name,
                        favNum: person.favNum.toString(),
                    });
                    index++;
                } catch {
                    break;
                }
            }
            setPeople(peopleList);
        } catch (error: unknown) {
            console.error("Error fetching people:", error);
        } finally {
            setIsRefreshing(false);
        }
    }, [web3]);

    const storeNumberFunction = async () => {
        if (!web3 || !account) return;
        setIsStoring(true);
        const contract = new web3.eth.Contract(CONTRACT_ABI, CONTRACT_ADDRESS);
        try {
            await contract.methods.store(storeNumber).send({
                from: account,
                gas: "200000",
            });
            alert("Number stored successfully!");
            setStoreNumber(""); // Clear the input after success
        } catch (error: unknown) {
            console.error("Error storing number:", error);
        } finally {
            setIsStoring(false);
        }
    };

    const retrieveNumber = async () => {
        if (!web3 || !account) return;
        setIsRetrieving(true);
        const contract = new web3.eth.Contract(CONTRACT_ABI, CONTRACT_ADDRESS);
        try {
            const result: number = await contract.methods.retrieve().call();
            setStoredNumber(result.toString());
        } catch (error: unknown) {
            console.error("Error retrieving number:", error);
        } finally {
            setIsRetrieving(false);
        }
    };

    const addPerson = async () => {
        if (!web3 || !account) return;
        if (!name || !personFavNumber) {
            alert("Please enter both name and favorite number");
            return;
        }
        setIsAddingPerson(true);
        const contract = new web3.eth.Contract(CONTRACT_ABI, CONTRACT_ADDRESS);
        try {
            await contract.methods.addPerson(name, personFavNumber).send({
                from: account,
                gas: "200000",
            });
            alert("Person added successfully!");
            await getPeople();
            setName("");
            setPersonFavNumber(""); // Clear person's favorite number
        } catch (error: unknown) {
            console.error("Error adding person:", error);
        } finally {
            setIsAddingPerson(false);
        }
    };

    useEffect(() => {
        if (account) {
            getPeople();
        }
    }, [account, getPeople]);

    const LoadingSpinner = () => (
        <svg
            className="animate-spin -ml-1 mr-3 h-5 w-5 text-white"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
        >
            <circle
                className="opacity-25"
                cx="12"
                cy="12"
                r="10"
                stroke="currentColor"
                strokeWidth="4"
            ></circle>
            <path
                className="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
            ></path>
        </svg>
    );

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
                            value={storeNumber}
                            onChange={(e) => setStoreNumber(e.target.value)}
                            className="w-full p-2 rounded bg-gray-600 text-white"
                            placeholder="Enter your favorite number"
                            disabled={!account || isStoring}
                        />
                        <button
                            onClick={storeNumberFunction}
                            disabled={!account || isStoring || !storeNumber}
                            className={`mt-4 w-full font-bold py-2 px-4 rounded transition-colors ${
                                !account || isStoring || !storeNumber
                                    ? "bg-gray-600 text-gray-400 cursor-not-allowed"
                                    : "bg-purple-600 hover:bg-purple-700 text-white"
                            }`}
                        >
                            {isStoring ? (
                                <span className="flex items-center justify-center">
                                    <LoadingSpinner />
                                    Storing...
                                </span>
                            ) : (
                                "Store Number"
                            )}
                        </button>
                    </div>

                    <div className="bg-gray-700 p-6 rounded-lg">
                        <h2 className="text-xl font-semibold mb-4 text-purple-300">
                            Retrieve Number
                        </h2>
                        <div className="flex space-x-4">
                            <button
                                onClick={retrieveNumber}
                                disabled={!account || isRetrieving}
                                className={`flex-1 font-bold py-2 px-4 rounded transition-colors ${
                                    !account || isRetrieving
                                        ? "bg-gray-600 text-gray-400 cursor-not-allowed"
                                        : "bg-purple-600 hover:bg-purple-700 text-white"
                                }`}
                            >
                                {isRetrieving ? (
                                    <span className="flex items-center justify-center">
                                        <LoadingSpinner />
                                        Getting...
                                    </span>
                                ) : (
                                    "Get Number"
                                )}
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
                                disabled={!account || isAddingPerson}
                            />
                            <input
                                type="number"
                                value={personFavNumber}
                                onChange={(e) =>
                                    setPersonFavNumber(e.target.value)
                                }
                                className="w-full p-2 rounded bg-gray-600 text-white"
                                placeholder="Enter favorite number"
                                disabled={!account || isAddingPerson}
                            />
                            <button
                                onClick={addPerson}
                                disabled={
                                    !account ||
                                    isAddingPerson ||
                                    !name ||
                                    !personFavNumber
                                }
                                className={`w-full font-bold py-2 px-4 rounded transition-colors ${
                                    !account ||
                                    isAddingPerson ||
                                    !name ||
                                    !personFavNumber
                                        ? "bg-gray-600 text-gray-400 cursor-not-allowed"
                                        : "bg-purple-600 hover:bg-purple-700 text-white"
                                }`}
                            >
                                {isAddingPerson ? (
                                    <span className="flex items-center justify-center">
                                        <LoadingSpinner />
                                        Adding...
                                    </span>
                                ) : (
                                    "Add Person"
                                )}
                            </button>
                        </div>
                    </div>

                    <div className="bg-gray-700 p-6 rounded-lg">
                        <h2 className="text-xl font-semibold mb-4 text-purple-300">
                            People List
                        </h2>
                        <div className="space-y-2">
                            {people.length === 0 ? (
                                <p className="text-gray-400">
                                    No people added yet
                                </p>
                            ) : (
                                people.map((person, index) => (
                                    <div
                                        key={index}
                                        className="flex justify-between items-center bg-gray-600 p-3 rounded"
                                    >
                                        <span className="text-purple-300">
                                            {person.name}
                                        </span>
                                        <span className="text-gray-300">
                                            Favorite Number: {person.favNum}
                                        </span>
                                    </div>
                                ))
                            )}
                        </div>
                        <button
                            onClick={getPeople}
                            disabled={!account || isRefreshing}
                            className={`mt-4 w-full font-bold py-2 px-4 rounded transition-colors ${
                                !account || isRefreshing
                                    ? "bg-gray-600 text-gray-400 cursor-not-allowed"
                                    : "bg-purple-600 hover:bg-purple-700 text-white"
                            }`}
                        >
                            {isRefreshing ? (
                                <span className="flex items-center justify-center">
                                    <LoadingSpinner />
                                    Refreshing...
                                </span>
                            ) : (
                                "Refresh List"
                            )}
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
}

export default App;
