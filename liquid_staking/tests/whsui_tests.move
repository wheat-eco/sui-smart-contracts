// SPDX-License-Identifier: MIT

#[test_only]
module liquid_staking::whsui_tests {

use liquid_staking::whsui::{Self, WHSUI, Metadata};
use liquid_staking::ownership::{Self, OwnerCap};
use sui::coin::{Coin};
use sui::test_scenario::{Self, next_tx, ctx};
use sui::test_utils;
use sui::transfer;
use sui::balance;

#[test]
fun trigger_migration() {
let addr = @0xA;
let scenario = test_scenario::begin(addr);
{
whsui::test_init(ctx(&mut scenario));
ownership::test_init(ctx(&mut scenario));
};

next_tx(&mut scenario, addr);
{
let owner_cap = test_scenario::take_from_sender<OwnerCap>(&scenario);
  let metadata = test_scenario::take_shared<Metadata<WHSUI>>(&scenario);
    
    whsui::test_update_version(&mut metadata, 0);
    whsui::test_migrate(&mut metadata, &owner_cap);
    
    test_scenario::return_shared<Metadata<WHSUI>>(metadata);
      test_scenario::return_to_address<OwnerCap>(addr, owner_cap);
        };
        
        test_scenario::end(scenario);
        }
        
        #[test, expected_failure]
        fun trigger_migration_gt_version() {
        let addr = @0xA;
        let scenario = test_scenario::begin(addr);
        {
        whsui::test_init(ctx(&mut scenario));
        ownership::test_init(ctx(&mut scenario));
        };
        
        next_tx(&mut scenario, addr);
        {
        let owner_cap = test_scenario::take_from_sender<OwnerCap>(&scenario);
          let metadata = test_scenario::take_shared<Metadata<WHSUI>>(&scenario);
            
            whsui::test_update_version(&mut metadata, 5);
            whsui::test_migrate(&mut metadata, &owner_cap);
            
            test_scenario::return_shared<Metadata<WHSUI>>(metadata);
              test_scenario::return_to_address<OwnerCap>(addr, owner_cap);
                };
                
                test_scenario::end(scenario);
                }
                
                #[test, expected_failure]
                fun failed_to_assert_migration() {
                let addr = @0xA;
                let scenario = test_scenario::begin(addr);
                {
                whsui::test_init(ctx(&mut scenario));
                ownership::test_init(ctx(&mut scenario));
                };
                
                next_tx(&mut scenario, addr);
                {
                let owner_cap = test_scenario::take_from_sender<OwnerCap>(&scenario);
                  let metadata = test_scenario::take_shared<Metadata<WHSUI>>(&scenario);
                    
                    whsui::test_update_version(&mut metadata, 20);
                    whsui::test_assert_version(&metadata);
                    
                    test_scenario::return_shared<Metadata<WHSUI>>(metadata);
                      test_scenario::return_to_address<OwnerCap>(addr, owner_cap);
                        };
                        
                        test_scenario::end(scenario);
                        }
                        
                        #[test]
                        fun mint_burn() {
                        let addr1 = @0xA;
                        
                        let scenario = test_scenario::begin(addr1);
                        
                        {
                        whsui::test_init(ctx(&mut scenario));
                        ownership::test_init(ctx(&mut scenario));
                        };
                        
                        // Mint WHSUI
                        next_tx(&mut scenario, addr1);
                        {
                        let metadata = test_scenario::take_shared<Metadata<WHSUI>>(&scenario);
                          
                          let whsui_coin = whsui::mint_coin_for_testing(&mut metadata, 1_000_000, test_scenario::ctx(&mut scenario));
                          
                          let supply = whsui::get_total_supply(&metadata);
                          test_utils::assert_eq(balance::supply_value(supply), 1_000_000);
                          let supply_value = whsui::get_total_supply_value(&metadata);
                          test_utils::assert_eq(supply_value, 1_000_000);
                          
                          test_scenario::return_shared<Metadata<WHSUI>>(metadata);
                            transfer::public_transfer(whsui_coin, addr1);
                            };
                            
                            // Burn WHSUI
                            next_tx(&mut scenario, addr1);
                            {
                            let metadata = test_scenario::take_shared<Metadata<WHSUI>>(&scenario);
                              let coin = test_scenario::take_from_sender<Coin<WHSUI>>(&scenario);
                                whsui::burn_coin_for_testing(&mut metadata, coin);
                                test_scenario::return_shared<Metadata<WHSUI>>(metadata);
                                  };
                                  
                                  test_scenario::end(scenario);
                                  }
                                  
                                  }