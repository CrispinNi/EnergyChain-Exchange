import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Time "mo:base/Time";

actor EnergyTrading {
    // User type
    type User = {
        id: Principal;
        name: Text;
        energyProduction: Nat;
        energyConsumption: Nat;
        balance: Nat;
    };

    // Energy listing type
    type EnergyListing = {
        id: Nat;
        seller: Principal;
        quantity: Nat;
        price: Nat;
        timestamp: Time.Time;
    };

    // Transaction type
    type Transaction = {
        id: Nat;
        buyer: Principal;
        seller: Principal;
        quantity: Nat;
        price: Nat;
        timestamp: Time.Time;
    };

    private stable var nextUserId : Nat = 0;
    private stable var nextListingId : Nat = 0;
    private stable var nextTransactionId : Nat = 0;

    private let users = HashMap.HashMap<Principal, User>(10, Principal.equal, Principal.hash);
    private let energyListings = HashMap.HashMap<Nat, EnergyListing>(10, Nat.equal, Hash.hash);
    private let transactions = HashMap.HashMap<Nat, Transaction>(10, Nat.equal, Hash.hash);

    // User management
    public shared(msg) func registerUser(name: Text) : async Principal {
        let userId = msg.caller;
        let newUser : User = {
            id = userId;
            name = name;
            energyProduction = 0;
            energyConsumption = 0;
            balance = 0;
        };
        users.put(userId, newUser);
        userId
    };

    public shared(msg) func getUser() : async ?User {
        users.get(msg.caller)
    };

    // Energy trading
    public shared(msg) func listEnergy(quantity: Nat, price: Nat) : async Nat {
        let seller = msg.caller;
        let newListing : EnergyListing = {
            id = nextListingId;
            seller = seller;
            quantity = quantity;
            price = price;
            timestamp = Time.now();
        };
        energyListings.put(nextListingId, newListing);
        nextListingId += 1;
        nextListingId - 1
    };

    public query func getEnergyListings() : async [EnergyListing] {
        Array.fromIter(energyListings.vals())
    };

    public query func getTransactions() : async [Transaction] {
        Array.fromIter(transactions.vals())
    };

    // Energy monitoring
    public shared(msg) func updateEnergyProduction(production: Nat) : async () {
        switch (users.get(msg.caller)) {
            case null { /* User not found */ };
            case (?user) {
                let updatedUser = {
                    id = user.id;
                    name = user.name;
                    energyProduction = production;
                    energyConsumption = user.energyConsumption;
                    balance = user.balance;
                };
                users.put(msg.caller, updatedUser);
            };
        };
    };


}