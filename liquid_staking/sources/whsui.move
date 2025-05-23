// SPDX-License-Identifier: MIT

/// Reward bearing token represent the staked asset plus all future staking rewards
/// They don't grow in number but grow in value
/// For example, the fair value of 1 whSUI token vs. SUI increases over time as staking rewards accumulate, i.e., 1 whSUI becomes worth increasingly more than 1 SUI.
module liquid_staking::cert {
    use std::option::{Self};
    use sui::url::{Self, Url};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Supply, Balance};
    use sui::transfer;
    use sui::tx_context::{TxContext};
    use sui::object::{Self, UID};
    use sui::event;
    use liquid_staking::ownership::{OwnerCap};

    friend liquid_staking::native_pool;

    /* Events */
    struct MigratedEvent has copy, drop {
        prev_version: u64,
        new_version: u64,
    }

    // Track the current version of the module, iterate each upgrade
    const VERSION: u64 = 1;

    /* Constants */

    /* Errors definition */

    // Calling functions from the wrong package version
    const E_INCOMPATIBLE_VERSION: u64 = 1;

    /// Name of the coin. By convention, this type has the same name as its parent module
    /// and has no fields. The full type of the coin defined by this module will be `COIN<WHSUI>`.
    struct WHSUI has drop {}

    /// Changeable metadata of certificate coin
    struct Metadata<phantom T> has key, store {
        id: UID,
        version: u64, // Track the current version of the shared object
        total_supply: Supply<T>,
    }

    /// Register the currency and destroy its `TreasuryCap`. Because
    /// this is a module initializer, it ensures the currency only gets
    /// registered once.
    fun init(witness: WHSUI, ctx: &mut TxContext) {
        // create coin with metadata
        let (treasury_cap, metadata) = coin::create_currency<WHSUI>(
            witness, 9, b"whSUI", b"WheatChain Staked SUI",
            b"WheatChain's SUI staking solution provides the best user experience and highest level of safety, combined with an attractive reward mechanism and instant staking liquidity through a bond-like synthetic token called whSUI.",
            option::some<Url>(url::new_unsafe_from_bytes(b"https://wheatchain.com/assets/tokens/whsui.svg")),
            ctx
        );
        transfer::public_freeze_object(metadata);
        // destroy treasury_cap and store it custom Metadata object
        let supply = coin::treasury_into_supply(treasury_cap);
        transfer::share_object(Metadata<WHSUI> {
                id: object::new(ctx),
                version: VERSION,
                total_supply: supply,
        });
    }

    /* Metadata read methods */

    public fun get_total_supply(metadata: &Metadata<WHSUI>): &Supply<WHSUI> {
        &metadata.total_supply
    }

    public fun get_total_supply_value(metadata: &Metadata<WHSUI>): u64 {
        balance::supply_value(&metadata.total_supply)
    }

    /// Pool can mint new coins
    public(friend) fun mint(
        metadata: &mut Metadata<WHSUI>, shares: u64, ctx: &mut TxContext
    ): Coin<WHSUI> {
        assert_version(metadata);

        let minted_balance = balance::increase_supply(&mut metadata.total_supply, shares);
        coin::from_balance(minted_balance, ctx)
    }

    #[test_only]
    public fun mint_coin_for_testing(
        metadata: &mut Metadata<WHSUI>, shares: u64, ctx: &mut TxContext
    ): Coin<WHSUI> {
        mint(metadata, shares, ctx)
    }

    #[test_only]
    public fun mint_balance_for_testing(metadata: &mut Metadata<WHSUI>, shares: u64): Balance<WHSUI> {
        balance::increase_supply(&mut metadata.total_supply, shares)
    }

    /// Pool can burn coins
    public(friend) fun burn_coin(
        metadata: &mut Metadata<WHSUI>, coin: Coin<WHSUI>
    ): u64 {
        assert_version(metadata);
        balance::decrease_supply(&mut metadata.total_supply, coin::into_balance(coin))
    }

    /// burn balance instead coin
    public(friend) fun burn_balance(metadata: &mut Metadata<WHSUI>, balance: Balance<WHSUI>): u64 {
        assert_version(metadata);
        balance::decrease_supply(&mut metadata.total_supply, balance)
    }

    #[test_only]
    public fun burn_coin_for_testing(metadata: &mut Metadata<WHSUI>, cert: Coin<WHSUI>): u64 {
        burn_coin(metadata, cert)
    }

    #[test_only]
    public fun burn_balance_for_testing(metadata: &mut Metadata<WHSUI>, balance: Balance<WHSUI>): u64 {
        balance::decrease_supply(&mut metadata.total_supply, balance)
    }

    /* Migration stuff */

    entry fun migrate(metadata: &mut Metadata<WHSUI>, _owner_cap: &OwnerCap) {
        assert!(metadata.version < VERSION, E_INCOMPATIBLE_VERSION);

        event::emit(MigratedEvent {
            prev_version: metadata.version,
            new_version: VERSION,
        });

        metadata.version = VERSION;
    }

    #[test_only]
    public fun test_migrate(metadata: &mut Metadata<WHSUI>, owner_cap: &OwnerCap) {
        migrate(metadata, owner_cap);
    }

    #[test_only]
    public fun test_update_version(metadata: &mut Metadata<WHSUI>, version: u64) {
        metadata.version = version;
    }

    /// check version before interaction with metadata
    /// to interact with package version of metadata must be equal to package version
    fun assert_version(metadata: &Metadata<WHSUI>) {
        assert!(metadata.version == VERSION, E_INCOMPATIBLE_VERSION);
    }

    #[test_only]
    public fun test_assert_version(metadata: &Metadata<WHSUI>) {
        assert_version(metadata);
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        init(WHSUI {}, ctx)
    }
}