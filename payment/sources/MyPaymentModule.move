module MyPaymentModule {
    use std::signer;
    use std::vector;
    use std::address;
    use std::assert;
    use std::move;

    const EINSUFFICIENT_BALANCE: u64 = 0;
    const EALREADY_HAS_BALANCE: u64 = 1;
    const EEQUAL_ADDR: u64 = 2;

    struct Coin has store {
        value: u64
    }

    struct StartupBalance has key {
        coin: Coin
    }

    struct InvestorBalance has key {
        coin: Coin
    }

    public entry fun publish_investor_balance(account: &signer) {
        let empty_coin = Coin { value: 0 };
        assert!(!exists<InvestorBalance>(signer::address_of(account)), EALREADY_HAS_BALANCE);
        move_to(account, InvestorBalance { coin: empty_coin });
    }

    public entry fun publish_startup_balance(account: &signer) {
        let empty_coin = Coin { value: 0 };
        assert!(!exists<StartupBalance>(signer::address_of(account)), EALREADY_HAS_BALANCE);
        move_to(account, StartupBalance { coin: empty_coin });
    }

    public entry fun fund_startup(investor: &signer, startup_addr: address, amount: u64) acquires InvestorBalance, StartupBalance {
        let investor_addr = signer::address_of(investor);
        assert!(investor_addr != startup_addr, EEQUAL_ADDR);  
        
        if (!exists<InvestorBalance>(investor_addr)) {
            publish_investor_balance(investor);
        };
        
        let balance = balance_of_investor(investor_addr);
        assert!(balance >= amount, EINSUFFICIENT_BALANCE);

        let coin = withdraw_from_investor(investor_addr, amount);

        deposit_to_startup(startup_addr, coin);
    }

    public fun balance_of_investor(owner: address): u64 acquires InvestorBalance {
        borrow_global<InvestorBalance>(owner).coin.value
    }

    fun withdraw_from_investor(addr: address, amount: u64): Coin acquires InvestorBalance {
        let balance = balance_of_investor(addr);
        assert!(balance >= amount, EINSUFFICIENT_BALANCE);
        let balance_ref = &mut borrow_global_mut<InvestorBalance>(addr).coin.value;
        *balance_ref = balance - amount;
        Coin { value: amount }
    }

    fun deposit_to_startup(addr: address, coin: Coin) acquires StartupBalance {
        let balance = balance_of_startup(addr);
        let balance_ref = &mut borrow_global_mut<StartupBalance>(addr).coin.value;
        let Coin { value } = coin;
        *balance_ref = balance + value;
    }

    public fun balance_of_startup(owner: address): u64 acquires StartupBalance {
        borrow_global<StartupBalance>(owner).coin.value
    }
}
