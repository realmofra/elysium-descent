#[dojo::contract]
pub mod elysium_dungeon_game {
    use elysium_descent::interfaces::IElysiumDungeonGame;
    use starknet::{ContractAddress, get_caller_address};
    use death_mountain::models::adventurer::adventurer::Adventurer;
    use death_mountain::models::adventurer::bag::Bag;
    use death_mountain::models::adventurer::equipment::Equipment;
    use death_mountain::models::game::GameSettings;
    use death_mountain::models::adventurer::stats::Stats;
    use death_mountain::models::adventurer::item::{IItemPrimitive, ImplItem, Item};
    use death_mountain::systems::settings::contracts::{
        ISettingsSystemsDispatcher, ISettingsSystemsDispatcherTrait,
    };
    use death_mountain::systems::game::contracts::{
        IGameSystemsDispatcher, IGameSystemsDispatcherTrait,
    };
    use death_mountain::systems::game_token::contracts::{
        IGameTokenSystemsDispatcher, IGameTokenSystemsDispatcherTrait,
    };

    // Contract addresses (update for your network)
    const GAME_SYSTEMS_ADDRESS: felt252 =
        0x543fdf9d549d514dfe115363f090e67314f789daf1bdb33ca60710a8211f3e2;
    const SETTINGS_SYSTEMS_ADDRESS: felt252 =
        0xefb3cd6b2d70109162ca62e57381db51424d085c930f35ac3e888be10922c2;
    const TOKEN_SYSTEMS_ADDRESS: felt252 =
        0x6f261eba018dda4f60bdc1d0874cb7e97bf424979dda63fcbdf8bdcba1fb644;

    #[abi(embed_v0)]
    impl ElysiumDungeonGameImpl of IElysiumDungeonGame<ContractState> {
        fn create_dungeon_template(
            ref self: ContractState, name: ByteArray, difficulty: u8,
        ) -> u32 {
            let mut world = self.world(@"your_namespace");

            let settings_contract = ISettingsSystemsDispatcher {
                contract_address: SETTINGS_SYSTEMS_ADDRESS.try_into().unwrap(),
            };

            // Create adventurer configuration based on difficulty
            let adventurer = self.create_adventurer_by_difficulty(difficulty);
            let bag = self.create_starter_bag(difficulty);

            // Create the dungeon template
            settings_contract
                .add_settings(name, adventurer, bag, self.generate_game_seed(), 100, false)
        }

        fn spawn_new_adventure(ref self: ContractState, settings_id: u32, weapon: u8) -> u64 {
            let mut world = self.world(@"your_namespace");
            let player = get_caller_address();

            // Get the game systems contract
            let game_contract = IGameSystemsDispatcher {
                contract_address: GAME_SYSTEMS_ADDRESS.try_into().unwrap(),
            };

            // This requires integration with tournaments framework
            // or your own token minting system
            let adventurer_id = self.mint_game_nft(player, settings_id);

            // Start the actual game
            game_contract.start_game(adventurer_id, weapon);

            adventurer_id
        }

        fn get_dungeon_details(self: @ContractState, settings_id: u32) -> GameSettings {
            let settings_contract = ISettingsSystemsDispatcher {
                contract_address: SETTINGS_SYSTEMS_ADDRESS.try_into().unwrap(),
            };

            settings_contract.setting_details(settings_id)
        }

        fn get_player_adventures(self: @ContractState, player: ContractAddress) -> Array<u64> {
            let token_contract = IGameTokenSystemsDispatcher {
                contract_address: TOKEN_SYSTEMS_ADDRESS.try_into().unwrap(),
            };

            // Implementation depends on your token tracking system
            self.get_player_tokens(player)
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn create_adventurer_by_difficulty(self: @ContractState, difficulty: u8) -> Adventurer {
            let base_health = match difficulty {
                1 => 150, // Easy
                2 => 100, // Normal
                3 => 75, // Hard
                _ => 100,
            };

            Adventurer {
                health: base_health,
                xp: 0,
                gold: 25,
                beast_health: 0,
                stat_upgrades_available: 0,
                stats: Stats {
                    strength: 0,
                    dexterity: 0,
                    vitality: 0,
                    intelligence: 0,
                    wisdom: 0,
                    charisma: 0,
                    luck: 0,
                },
                equipment: Equipment {
                    weapon: ImplItem::new(0),
                    chest: ImplItem::new(0),
                    head: ImplItem::new(0),
                    waist: ImplItem::new(0),
                    foot: ImplItem::new(0),
                    hand: ImplItem::new(0),
                    neck: ImplItem::new(0),
                    ring: ImplItem::new(0),
                },
                item_specials_seed: 1,
                action_count: 0,
            }
        }

        fn create_starter_bag(self: @ContractState, difficulty: u8) -> Bag {
            // Configure starting items based on difficulty
            let gold_amount = match difficulty {
                1 => 50, // Easy: more gold
                2 => 25, // Normal: standard gold
                3 => 10, // Hard: less gold
                _ => 25,
            };

            Bag {
                item_1: Item { id: 0, xp: 0 },
                item_2: Item { id: 0, xp: 0 },
                item_3: Item { id: 0, xp: 0 },
                item_4: Item { id: 0, xp: 0 },
                item_5: Item { id: 0, xp: 0 },
                item_6: Item { id: 0, xp: 0 },
                item_7: Item { id: 0, xp: 0 },
                item_8: Item { id: 0, xp: 0 },
                item_9: Item { id: 0, xp: 0 },
                item_10: Item { id: 0, xp: 0 },
                item_11: Item { id: 0, xp: 0 },
                item_12: Item { id: 0, xp: 0 },
                item_13: Item { id: 0, xp: 0 },
                item_14: Item { id: 0, xp: 0 },
                item_15: Item { id: 0, xp: 0 },
                mutated: false,
            }
        }

        fn generate_game_seed(self: @ContractState) -> u64 {
            // Implement your seed generation logic
            // Consider using block timestamp, caller address, etc.
            1234567890_u64
        }

        fn mint_game_nft(self: @ContractState, player: ContractAddress, settings_id: u32) -> u64 {
            // This needs to be implemented based on your token system
            // Either integrate with tournaments framework or create your own
            1_u64 // Placeholder
        }

        fn get_player_tokens(self: @ContractState, player: ContractAddress) -> Array<u64> {
            // Implement token enumeration for player
            array![]
        }
    }
}
