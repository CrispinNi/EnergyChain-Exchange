import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Time "mo:base/Time";
import Hash "mo:base/Hash";
import Text "mo:base/Text";
import ExperimentalCycles "mo:base/ExperimentalCycles";

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

     func natHash(n: Nat): Hash.Hash {
        Text.hash(Nat.toText(n))
    };

    private stable var nextUserId : Nat = 0;
    private stable var nextListingId : Nat = 0;
    private stable var nextTransactionId : Nat = 0;

    private let users = HashMap.HashMap<Principal, User>(10, Principal.equal, Principal.hash);
 private let energyListings = HashMap.HashMap<Nat, EnergyListing>(10, Nat.equal, natHash);
    private let transactions = HashMap.HashMap<Nat, Transaction>(10, Nat.equal, natHash);
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
        Iter.toArray(energyListings.vals())
    };

    public shared(msg) func buyEnergy(listingId: Nat, quantity: Nat) : async ?Transaction {
        switch (energyListings.get(listingId)) {
            case null { null };
            case (?listing) {
                if (listing.quantity < quantity) {
                    return null; // Not enough energy available
                };

                let buyer = msg.caller;
                let cost = quantity * listing.price;

                switch (users.get(buyer), users.get(listing.seller)) {
                    case (?buyerUser, ?sellerUser) {
                        if (buyerUser.balance < cost) {
                            return null; // Insufficient funds
                        };

                        // Update balances
                        let updatedBuyer = {
                            id = buyerUser.id;
                            name = buyerUser.name;
                            energyProduction = buyerUser.energyProduction;
                            energyConsumption = buyerUser.energyConsumption + quantity;
                            balance = buyerUser.balance - cost;
                        };
                        let updatedSeller = {
                            id = sellerUser.id;
                            name = sellerUser.name;
                            energyProduction = sellerUser.energyProduction;
                            energyConsumption = sellerUser.energyConsumption;
                            balance = sellerUser.balance + cost;
                        };
                        users.put(buyer, updatedBuyer);
                        users.put(listing.seller, updatedSeller);

                        // Create transaction
                        let transaction : Transaction = {
                            id = nextTransactionId;
                            buyer = buyer;
                            seller = listing.seller;
                            quantity = quantity;
                            price = listing.price;
                            timestamp = Time.now();
                        };
                        transactions.put(nextTransactionId, transaction);
                        nextTransactionId += 1;

                        // Update or remove listing
                        if (listing.quantity == quantity) {
                            energyListings.delete(listingId);
                        } else {
                            let updatedListing = {
                                id = listing.id;
                                seller = listing.seller;
                                quantity = listing.quantity - quantity;
                                price = listing.price;
                                timestamp = listing.timestamp;
                            };
                            energyListings.put(listingId, updatedListing);
                        };

                        ?transaction
                    };
                    case _ { null };
                };
            };
        };
    };

    public query func getTransactions() : async [Transaction] {
       Iter.toArray(transactions.vals())
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

    public shared(msg) func updateEnergyConsumption(consumption: Nat) : async () {
        switch (users.get(msg.caller)) {
            case null { /* User not found */ };
            case (?user) {
                let updatedUser = {
                    id = user.id;
                    name = user.name;
                    energyProduction = user.energyProduction;
                    energyConsumption = consumption;
                    balance = user.balance;
                };
                users.put(msg.caller, updatedUser);
            };
        };
    };
}
