// use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
// use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
// use elysium_descent::models::loot_box::{LootBox, LootTable, LevelConfig};
// use elysium_descent::types::loot::Loot;
// use elysium_descent::types::loot::IntoLootU8;
// use elysium_descent::types::loot::IntoU8Loot;

// #[starknet::interface]
// trait ILootBoxActions<TContractState> {
//     fn spawn_loot_box(ref self: TContractState, game_id: u128, level: u32);
//     fn collect_loot_box(ref self: TContractState, game_id: u128, level: u32, box_id: u32);
//     fn cleanup_expired_boxes(ref self: TContractState, game_id: u128, level: u32);
//     fn set_loot_table(ref self: TContractState, level: u32, loot_type: Loot, probability: u32, min_amount: u32, max_amount: u32);
//     fn set_level_config(ref self: TContractState, level: u32, max_boxes: u32, spawn_interval: u64, box_lifetime: u64, gold_mult: u32, lords_mult: u32);
// }

// #[starknet::contract]
// mod loot_box_actions {
//     use super::ILootBoxActions;
//     use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
//     use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
//     use elysium_descent::models::loot_box::{LootBox, LootTable, LevelConfig};
//     use elysium_descent::types::loot::{Loot, IntoLootU8, IntoU8Loot};

//     #[storage]
//     struct Storage {
//         world: IWorldDispatcher,
//     }

//     #[external(v0)]
//     impl LootBoxActionsImpl of ILootBoxActions<ContractState> {
//         fn spawn_loot_box(ref self: ContractState, game_id: u128, level: u32) {
//             let world = self.world.read();
//             let current_time = get_block_timestamp();
            
//             // Get level configuration
//             let level_config = world.entity('LevelConfig', array![level.into()]);
            
//             // Check if we can spawn more boxes
//             let existing_boxes = world.entities('LootBox', array![game_id.into(), level.into()]);
//             if existing_boxes.len() >= level_config.max_loot_boxes {
//                 return;
//             }
            
//             // Generate random loot based on loot table
//             let loot_type = self._generate_random_loot(world, level);
//             let amount = self._generate_random_amount(world, level, loot_type);
            
//             // Create new loot box
//             let box_id = existing_boxes.len() + 1;
//             let new_box = LootBox {
//                 game_id,
//                 level,
//                 box_id,
//                 loot_type,
//                 amount,
//                 is_collected: false,
//                 spawn_time: current_time,
//                 expires_at: current_time + level_config.box_lifetime,
//             };
            
//             world.set_entity('LootBox', array![game_id.into(), level.into(), box_id.into()], array![
//                 loot_type.into().into(),
//                 amount.into(),
//                 false.into(),
//                 current_time.into(),
//                 (current_time + level_config.box_lifetime).into(),
//             ]);
//         }

//         fn collect_loot_box(ref self: ContractState, game_id: u128, level: u32, box_id: u32) {
//             let world = self.world.read();
//             let current_time = get_block_timestamp();
            
//             // Get loot box
//             let box_data = world.entity('LootBox', array![game_id.into(), level.into(), box_id.into()]);
            
//             // Check if box exists and is not collected
//             assert(box_data.is_collected == false, 'Box already collected');
//             assert(current_time <= box_data.expires_at, 'Box expired');
            
//             // Mark as collected
//             world.set_entity('LootBox', array![game_id.into(), level.into(), box_id.into()], array![
//                 box_data.loot_type.into().into(),
//                 box_data.amount.into(),
//                 true.into(),
//                 box_data.spawn_time.into(),
//                 box_data.expires_at.into(),
//             ]);
            
//             // TODO: Add loot to player's inventory/game state
//             // This would integrate with your existing game model
//         }

//         fn cleanup_expired_boxes(ref self: ContractState, game_id: u128, level: u32) {
//             let world = self.world.read();
//             let current_time = get_block_timestamp();
            
//             // Get all boxes for this level
//             let boxes = world.entities('LootBox', array![game_id.into(), level.into()]);
            
//             // Remove expired boxes
//             // Note: In a real implementation, you might want to mark them as expired
//             // rather than deleting them for audit purposes
//         }

//         fn set_loot_table(ref self: ContractState, level: u32, loot_type: Loot, probability: u32, min_amount: u32, max_amount: u32) {
//             let world = self.world.read();
            
//             world.set_entity('LootTable', array![level.into(), loot_type.into().into()], array![
//                 probability.into(),
//                 min_amount.into(),
//                 max_amount.into(),
//             ]);
//         }

//         fn set_level_config(ref self: ContractState, level: u32, max_boxes: u32, spawn_interval: u64, box_lifetime: u64, gold_mult: u32, lords_mult: u32) {
//             let world = self.world.read();
            
//             world.set_entity('LevelConfig', array![level.into()], array![
//                 max_boxes.into(),
//                 spawn_interval.into(),
//                 box_lifetime.into(),
//                 gold_mult.into(),
//                 lords_mult.into(),
//             ]);
//         }
//     }

//     impl LootBoxActionsInternalImpl of InternalImpl<ContractState> {
//         fn _generate_random_loot(self: @ContractState, world: IWorldDispatcher, level: u32) -> Loot {
//             // Get loot table for this level
//             let loot_table = world.entities('LootTable', array![level.into()]);
            
//             // Simple random selection based on probabilities
//             // In a real implementation, you'd use a proper RNG
//             let random_value = get_block_timestamp() % 10000;
//             let mut cumulative_prob = 0;
            
//             loop {
//                 if loot_table.is_empty() {
//                     break Loot::Gold; // Default fallback
//                 }
                
//                 let table_entry = loot_table.pop_front().unwrap();
//                 cumulative_prob += table_entry.probability;
                
//                 if random_value <= cumulative_prob {
//                     break table_entry.loot_type;
//                 }
//             }
//         }

//         fn _generate_random_amount(self: @ContractState, world: IWorldDispatcher, level: u32, loot_type: Loot) -> u32 {
//             let loot_table = world.entity('LootTable', array![level.into(), loot_type.into().into()]);
//             let level_config = world.entity('LevelConfig', array![level.into()]);
            
//             let base_amount = loot_table.min_amount + (get_block_timestamp() % (loot_table.max_amount - loot_table.min_amount + 1));
            
//             // Apply level multipliers
//             match loot_type {
//                 Loot::Gold => base_amount * level_config.gold_multiplier,
//                 Loot::LORDS => base_amount * level_config.lords_multiplier,
//                 _ => base_amount,
//             }
//         }
//     }
// } 