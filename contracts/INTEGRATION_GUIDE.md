# Death Mountain Integration Guide

## Table of Contents
1. [Overview](#overview)
2. [Architecture Understanding](#architecture-understanding)
3. [Setup and Dependencies](#setup-and-dependencies)
4. [Core Systems Reference](#core-systems-reference)
5. [Integration Implementation](#integration-implementation)
6. [Complete Workflow](#complete-workflow)
7. [Advanced Usage](#advanced-usage)
8. [Troubleshooting](#troubleshooting)
9. [Examples](#examples)

---

## Overview

Death Mountain is a blockchain-based RPG dungeon generator built on Starknet using the Dojo ECS framework. It provides a complete onchain dungeon crawling experience that can be integrated into your games as a dependency.

### Key Features
- **Procedural Dungeon Generation**: Each game instance creates a unique dungeon experience
- **NFT-Based Game Instances**: Every adventure is represented as an ERC721 token
- **Complete RPG Mechanics**: Combat, equipment, exploration, and progression systems
- **Deterministic Gameplay**: Seed-based randomization for fair and reproducible experiences
- **Modular Architecture**: Easy integration into existing Dojo projects

### Use Cases
- Add dungeon crawling to existing games
- Create tournament-style adventures
- Build roguelike experiences
- Implement procedural content generation

---

## Architecture Understanding

### Core Concepts

#### **Game Instance = Dungeon Adventure**
Each game in Death Mountain represents a single dungeon crawl:
- Represented as an ERC721 NFT token
- Has a unique `adventurer_id`
- Contains complete game state (adventurer, equipment, progress)
- Follows deterministic gameplay based on seeds

#### **Settings = Dungeon Templates**
Settings define the starting configuration for dungeons:
- Starting adventurer stats and equipment
- Difficulty parameters
- Random seeds for procedural generation
- Battle state configuration

#### **Systems = Game Logic Contracts**
Three main system contracts handle different aspects:
- **Game Systems**: Core gameplay (combat, exploration, equipment)
- **Settings Systems**: Dungeon template management
- **Token Systems**: NFT game instance management

### Data Flow

```
1. Create Settings (Dungeon Templates)
   ↓
2. Mint Game NFT (Game Instance)
   ↓
3. Start Game (Initialize Adventure)
   ↓
4. Gameplay Loop (Explore, Combat, Equip)
   ↓
5. Game Completion/Death
```

---

## Setup and Dependencies

### 1. Add Dependencies

Add to your `Scarb.toml`:

```toml
[dependencies]
# Death Mountain contracts
death_mountain = { path = "../death-mountain/contracts" }
# Or from git:
# death_mountain = { git = "https://github.com/your-repo/death-mountain.git" }

# Required dependencies
tournaments = { git = "https://github.com/Provable-Games/tournaments.git" }
dojo = { git = "https://github.com/dojoengine/dojo", tag = "v1.5.1" }
openzeppelin_token = { git = "https://github.com/OpenZeppelin/cairo-contracts.git", tag = "v1.0.0" }
```

### 2. Network Configuration

Update your `dojo_*.toml` files:

```toml
[world]
namespace = "your_namespace"
description = "Your game integrating Death Mountain"

[env]
# Death Mountain contract addresses (Sepolia testnet)
DEATH_MOUNTAIN_WORLD = "0x5246cbbe2bef7fd190adbf05e47bee876ab2ab0e272c3346e0e760cd26adaa7"
GAME_SYSTEMS = "0x543fdf9d549d514dfe115363f090e67314f789daf1bdb33ca60710a8211f3e2"
SETTINGS_SYSTEMS = "0xefb3cd6b2d70109162ca62e57381db51424d085c930f35ac3e888be10922c2"
TOKEN_SYSTEMS = "0x6f261eba018dda4f60bdc1d0874cb7e97bf424979dda63fcbdf8bdcba1fb644"
```

### 3. Import Required Models

```cairo
use death_mountain::models::{
    GameSettings, Adventurer, AdventurerPacked,
    Equipment, Stats, Bag, ItemPrimitive
};
```

---

## Core Systems Reference

### Game Systems (`IGameSystems`)

**Primary Interface**: Controls core gameplay mechanics

```cairo
trait IGameSystems<T> {
    fn start_game(ref self: T, adventurer_id: u64, weapon: u8);
    fn explore(ref self: T, adventurer_id: u64);
    fn attack(ref self: T, adventurer_id: u64, weapon: bool);
    fn flee(ref self: T, adventurer_id: u64);
    fn equip(ref self: T, adventurer_id: u64, item_id: u8);
    fn drop(ref self: T, adventurer_id: u64, item_id: u8);
    fn buy_items(ref self: T, adventurer_id: u64, item_id: u8, equip: bool);
    fn select_stat_upgrades(ref self: T, adventurer_id: u64, strength: u8, dexterity: u8, vitality: u8, intelligence: u8, wisdom: u8, charisma: u8);
}
```

**Key Methods**:
- `start_game()`: Initializes a new dungeon adventure
- `explore()`: Advance through the dungeon, encounter events
- `attack()`/`flee()`: Combat actions
- `equip()`/`drop()`: Equipment management
- `buy_items()`: Purchase from in-dungeon merchants
- `select_stat_upgrades()`: Allocate stat points on level up

### Settings Systems (`ISettingsSystems`)

**Primary Interface**: Manages dungeon templates

```cairo
trait ISettingsSystems<T> {
    fn add_settings(ref self: T, name: ByteArray, adventurer: Adventurer, bag: Bag, game_seed: u64, game_seed_until_xp: u16, in_battle: bool) -> u32;
    fn setting_details(self: @T, settings_id: u32) -> GameSettings;
    fn game_settings(self: @T, adventurer_id: u64) -> GameSettings;
    fn settings_count(self: @T) -> u32;
}
```

**Key Methods**:
- `add_settings()`: Create new dungeon template
- `setting_details()`: Get template configuration
- `game_settings()`: Get settings for specific game instance
- `settings_count()`: Total number of available templates

### Token Systems (`IGameTokenSystems`)

**Primary Interface**: Manages game NFTs (integrates with tournaments)

```cairo
trait IGameTokenSystems<T> {
    // Standard ERC721 methods
    fn name(self: @T) -> ByteArray;
    fn symbol(self: @T) -> ByteArray;
    fn token_uri(self: @T, token_id: u256) -> ByteArray;
    fn balance_of(self: @T, account: ContractAddress) -> u256;
    fn owner_of(self: @T, token_id: u256) -> ContractAddress;

    // Game-specific methods
    fn adventurer_id(self: @T, token_id: u256) -> u64;
    fn token_id(self: @T, adventurer_id: u64) -> u256;
}
```

---

## Integration Implementation

### 1. Basic Integration Contract

```cairo
use starknet::ContractAddress;
use death_mountain::systems::game::IGameSystemsDispatcherTrait;
use death_mountain::systems::settings::ISettingsSystemsDispatcherTrait;
use death_mountain::systems::game_token::IGameTokenSystemsDispatcherTrait;

#[starknet::interface]
pub trait IMyDungeonGame<T> {
    fn create_dungeon_template(ref self: T, name: ByteArray, difficulty: u8) -> u32;
    fn spawn_new_adventure(ref self: T, settings_id: u32, weapon: u8) -> u64;
    fn get_dungeon_details(self: @T, settings_id: u32) -> GameSettings;
    fn get_player_adventures(self: @T, player: ContractAddress) -> Array<u64>;
}

#[dojo::contract]
pub mod my_dungeon_game {
    use super::IMyDungeonGame;
    use starknet::{ContractAddress, get_caller_address};
    use dojo::model::ModelStorage;
    use death_mountain::models::{GameSettings, Adventurer, Equipment, Stats, Bag, ItemPrimitive};
    use death_mountain::systems::settings::{ISettingsSystemsDispatcher, ISettingsSystemsDispatcherTrait};
    use death_mountain::systems::game::{IGameSystemsDispatcher, IGameSystemsDispatcherTrait};
    use death_mountain::systems::game_token::{IGameTokenSystemsDispatcher, IGameTokenSystemsDispatcherTrait};

    // Contract addresses (update for your network)
    const GAME_SYSTEMS_ADDRESS: felt252 = 0x480e2d16e9a394219b17309619ec764b9b85540b274ff636b668bb6585adf58;
    const SETTINGS_SYSTEMS_ADDRESS: felt252 = 0x66bb04604f81385856aa7b8526ccdaeeb6bf1568e3656e1eea1727d41d2f206;
    const TOKEN_SYSTEMS_ADDRESS: felt252 = 0x2e56d1c33ee39d46198aaa6a699e72b6f445eacc243ef2e61719e4198af9aed;

    #[abi(embed_v0)]
    impl MyDungeonGameImpl of IMyDungeonGame<ContractState> {
        fn create_dungeon_template(ref self: ContractState, name: ByteArray, difficulty: u8) -> u32 {
            let mut world = self.world(@"your_namespace");

            let settings_contract = ISettingsSystemsDispatcher {
                contract_address: SETTINGS_SYSTEMS_ADDRESS.try_into().unwrap()
            };

            // Create adventurer configuration based on difficulty
            let adventurer = self.create_adventurer_by_difficulty(difficulty);
            let bag = self.create_starter_bag(difficulty);

            // Create the dungeon template
            settings_contract.add_settings(
                name,
                adventurer,
                bag,
                self.generate_game_seed(),
                100, // game_seed_until_xp
                false // not in_battle initially
            )
        }

        fn spawn_new_adventure(ref self: ContractState, settings_id: u32, weapon: u8) -> u64 {
            let mut world = self.world(@"your_namespace");
            let player = get_caller_address();

            // Get the game systems contract
            let game_contract = IGameSystemsDispatcher {
                contract_address: GAME_SYSTEMS_ADDRESS.try_into().unwrap()
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
                contract_address: SETTINGS_SYSTEMS_ADDRESS.try_into().unwrap()
            };

            settings_contract.setting_details(settings_id)
        }

        fn get_player_adventures(self: @ContractState, player: ContractAddress) -> Array<u64> {
            let token_contract = IGameTokenSystemsDispatcher {
                contract_address: TOKEN_SYSTEMS_ADDRESS.try_into().unwrap()
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
                3 => 75,  // Hard
                _ => 100
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
                    luck: 0
                },
                equipment: Equipment {
                    weapon: ItemPrimitive { id: 0, xp: 0 },
                    chest: ItemPrimitive { id: 0, xp: 0 },
                    head: ItemPrimitive { id: 0, xp: 0 },
                    waist: ItemPrimitive { id: 0, xp: 0 },
                    foot: ItemPrimitive { id: 0, xp: 0 },
                    hand: ItemPrimitive { id: 0, xp: 0 },
                    neck: ItemPrimitive { id: 0, xp: 0 },
                    ring: ItemPrimitive { id: 0, xp: 0 }
                },
                item_specials_seed: 1,
                action_count: 0
            }
        }

        fn create_starter_bag(self: @ContractState, difficulty: u8) -> Bag {
            // Configure starting items based on difficulty
            let gold_amount = match difficulty {
                1 => 50,  // Easy: more gold
                2 => 25,  // Normal: standard gold
                3 => 10,  // Hard: less gold
                _ => 25
            };

            Bag {
                // Configure starting bag items
                item_1: ItemPrimitive { id: 0, xp: 0 },
                item_2: ItemPrimitive { id: 0, xp: 0 },
                // ... other bag items
                gold: gold_amount
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
```

### 2. Game Management Contract

Create a higher-level contract to manage multiple dungeon instances:

```cairo
#[derive(Drop, Serde)]
#[dojo::model]
pub struct PlayerGameRegistry {
    #[key]
    pub player: ContractAddress,
    pub active_games: Array<u64>,
    pub completed_games: Array<u64>,
    pub total_games_played: u32,
}

#[derive(Drop, Serde)]
#[dojo::model]
pub struct DungeonTemplate {
    #[key]
    pub template_id: u32,
    pub name: ByteArray,
    pub difficulty: u8,
    pub description: ByteArray,
    pub creator: ContractAddress,
    pub play_count: u32,
}

#[starknet::interface]
pub trait IDungeonManager<T> {
    fn register_dungeon_template(ref self: T, name: ByteArray, difficulty: u8, description: ByteArray) -> u32;
    fn list_available_dungeons(self: @T) -> Array<DungeonTemplate>;
    fn start_dungeon_adventure(ref self: T, template_id: u32, weapon: u8) -> u64;
    fn get_player_progress(self: @T, player: ContractAddress) -> PlayerGameRegistry;
}
```

---

## Complete Workflow

### Phase 1: Setup (One-time)

```cairo
// 1. Deploy your integration contract
// 2. Create dungeon templates
let easy_dungeon = create_dungeon_template("Goblin Caves", 1);
let normal_dungeon = create_dungeon_template("Orc Stronghold", 2);
let hard_dungeon = create_dungeon_template("Dragon's Lair", 3);
```

### Phase 2: Game Instance Creation

```cairo
// Player starts new adventure
let adventurer_id = spawn_new_adventure(
    settings_id: easy_dungeon, // Use "Goblin Caves" template
    weapon: 1                  // Starting weapon (1=Wand, 2=Katana, 3=Club)
);
```

### Phase 3: Gameplay Loop

```cairo
let game_contract = IGameSystemsDispatcher {
    contract_address: GAME_SYSTEMS_ADDRESS.try_into().unwrap()
};

// Main gameplay loop
loop {
    // 1. Explore the dungeon
    game_contract.explore(adventurer_id);

    // 2. Handle encounters (combat, merchants, etc.)
    match encounter_type {
        Combat => {
            game_contract.attack(adventurer_id, weapon: true);
            // or
            game_contract.flee(adventurer_id);
        },
        Merchant => {
            game_contract.buy_items(adventurer_id, item_id: 5, equip: true);
        },
        LevelUp => {
            game_contract.select_stat_upgrades(
                adventurer_id,
                strength: 1,
                dexterity: 0,
                vitality: 1,
                intelligence: 0,
                wisdom: 0,
                charisma: 0
            );
        }
    }

    // 3. Equipment management
    game_contract.equip(adventurer_id, item_id: 5);
    game_contract.drop(adventurer_id, item_id: 3);

    // 4. Check game state
    if is_game_over(adventurer_id) {
        break;
    }
}
```

### Phase 4: Game Completion

```cairo
// Handle game completion
if adventurer_died {
    handle_death(adventurer_id);
} else if dungeon_completed {
    handle_victory(adventurer_id);
}

// Update player registry
update_player_stats(player, adventurer_id);
```

---

## Advanced Usage

### 1. Custom Game Modes

```cairo
// Tournament Mode
fn create_tournament_dungeon(max_players: u32, entry_fee: u256) -> u32 {
    let settings_id = create_dungeon_template("Tournament Arena", 2);

    // Additional tournament logic
    setup_tournament_rules(settings_id, max_players, entry_fee);

    settings_id
}

// Hardcore Mode (permadeath)
fn create_hardcore_dungeon() -> u32 {
    let mut adventurer = create_adventurer_by_difficulty(3);
    adventurer.health = 1; // One hit point only

    // Create template with hardcore settings
    settings_contract.add_settings(
        "Hardcore Challenge",
        adventurer,
        create_minimal_bag(),
        generate_game_seed(),
        50,
        false
    )
}
```

### 2. Dynamic Dungeon Generation

```cairo
fn create_procedural_dungeon(player: ContractAddress, preferences: DungeonPreferences) -> u32 {
    // Generate dungeon based on player history and preferences
    let difficulty = calculate_adaptive_difficulty(player);
    let theme = select_theme_by_preference(preferences);

    let adventurer = create_themed_adventurer(theme, difficulty);
    let bag = create_themed_bag(theme);

    settings_contract.add_settings(
        generate_dungeon_name(theme),
        adventurer,
        bag,
        generate_themed_seed(theme, player),
        100,
        false
    )
}
```

### 3. Event Listening and State Management

```cairo
// Listen for Death Mountain events
#[derive(Drop, Serde)]
#[dojo::event]
pub struct AdventurerDied {
    #[key]
    pub adventurer_id: u64,
    pub player: ContractAddress,
    pub final_xp: u16,
    pub gold_earned: u16,
}

#[derive(Drop, Serde)]
#[dojo::event]
pub struct DungeonCompleted {
    #[key]
    pub adventurer_id: u64,
    pub player: ContractAddress,
    pub final_level: u8,
    pub completion_time: u64,
}

// Handle events in your contract
fn handle_adventurer_death(adventurer_id: u64) {
    let mut world = self.world(@"your_namespace");

    // Update player statistics
    let mut player_stats: PlayerStats = world.read_model(get_caller_address());
    player_stats.deaths += 1;
    player_stats.total_xp += get_final_xp(adventurer_id);
    world.write_model(@player_stats);

    // Emit your own event
    world.emit_event(@AdventurerDied {
        adventurer_id,
        player: get_caller_address(),
        final_xp: get_final_xp(adventurer_id),
        gold_earned: get_gold_earned(adventurer_id)
    });
}
```

---

## Troubleshooting

### Common Issues

#### 1. Contract Address Errors
**Problem**: `Contract not found` or `Invalid contract address`
**Solution**:
- Verify contract addresses are correct for your network
- Check if contracts are deployed on the target network
- Ensure addresses are properly formatted as `felt252`

#### 2. Permission Errors
**Problem**: `Caller is not authorized` or `Writer permission denied`
**Solution**:
- Ensure your contract has proper permissions to call Death Mountain systems
- Check if you're using the correct namespace
- Verify world configuration

#### 3. Token Minting Issues
**Problem**: `Token already exists` or `Invalid token ID`
**Solution**:
- Implement proper token ID generation
- Check if tournaments framework is properly integrated
- Ensure unique adventurer IDs

#### 4. Game State Inconsistency
**Problem**: Game state doesn't match expected values
**Solution**:
- Always read fresh state before making decisions
- Handle async state updates properly
- Implement proper error handling

### Debug Strategies

```cairo
// 1. Add debug events
#[derive(Drop, Serde)]
#[dojo::event]
pub struct DebugEvent {
    #[key]
    pub adventurer_id: u64,
    pub action: ByteArray,
    pub state: ByteArray,
}

// 2. State validation functions
fn validate_game_state(adventurer_id: u64) -> bool {
    let adventurer = get_adventurer(adventurer_id);

    // Check for impossible states
    assert(adventurer.health > 0, 'Adventurer should be alive');
    assert(adventurer.xp >= 0, 'XP cannot be negative');

    true
}

// 3. Comprehensive error handling
fn safe_game_action(adventurer_id: u64, action: GameAction) -> Result<(), ByteArray> {
    if !validate_game_state(adventurer_id) {
        return Result::Err("Invalid game state");
    }

    match action {
        GameAction::Explore => {
            if is_in_combat(adventurer_id) {
                return Result::Err("Cannot explore during combat");
            }
            game_contract.explore(adventurer_id);
        },
        GameAction::Attack => {
            if !is_in_combat(adventurer_id) {
                return Result::Err("Not in combat");
            }
            game_contract.attack(adventurer_id, true);
        }
    }

    Result::Ok(())
}
```

---

## Examples

### Example 1: Simple Dungeon Crawler

```cairo
// A basic dungeon crawler that creates adventures for players
#[dojo::contract]
pub mod simple_dungeon_crawler {
    use death_mountain::systems::game::{IGameSystemsDispatcher, IGameSystemsDispatcherTrait};
    use death_mountain::systems::settings::{ISettingsSystemsDispatcher, ISettingsSystemsDispatcherTrait};

    const GAME_SYSTEMS: felt252 = 0x480e2d16e9a394219b17309619ec764b9b85540b274ff636b668bb6585adf58;
    const SETTINGS_SYSTEMS: felt252 = 0x66bb04604f81385856aa7b8526ccdaeeb6bf1568e3656e1eea1727d41d2f206;

    #[starknet::interface]
    pub trait ISimpleDungeonCrawler<T> {
        fn quick_adventure(ref self: T, difficulty: u8) -> u64;
        fn continue_adventure(ref self: T, adventurer_id: u64, action: u8);
    }

    #[abi(embed_v0)]
    impl SimpleDungeonCrawlerImpl of ISimpleDungeonCrawler<ContractState> {
        fn quick_adventure(ref self: ContractState, difficulty: u8) -> u64 {
            // Create a quick dungeon template
            let settings_contract = ISettingsSystemsDispatcher {
                contract_address: SETTINGS_SYSTEMS.try_into().unwrap()
            };

            let adventurer = create_quick_adventurer(difficulty);
            let bag = create_quick_bag();

            let settings_id = settings_contract.add_settings(
                "Quick Adventure",
                adventurer,
                bag,
                starknet::get_block_timestamp().into(),
                100,
                false
            );

            // Start the adventure
            let adventurer_id = mint_quick_nft(get_caller_address());

            let game_contract = IGameSystemsDispatcher {
                contract_address: GAME_SYSTEMS.try_into().unwrap()
            };

            game_contract.start_game(adventurer_id, 1); // Start with wand

            adventurer_id
        }

        fn continue_adventure(ref self: ContractState, adventurer_id: u64, action: u8) {
            let game_contract = IGameSystemsDispatcher {
                contract_address: GAME_SYSTEMS.try_into().unwrap()
            };

            match action {
                1 => game_contract.explore(adventurer_id),
                2 => game_contract.attack(adventurer_id, true),
                3 => game_contract.flee(adventurer_id),
                _ => panic!("Invalid action")
            }
        }
    }
}
```

### Example 2: Tournament Integration

```cairo
// Tournament-style dungeon competition
#[derive(Drop, Serde)]
#[dojo::model]
pub struct Tournament {
    #[key]
    pub tournament_id: u32,
    pub name: ByteArray,
    pub entry_fee: u256,
    pub max_participants: u32,
    pub current_participants: u32,
    pub prize_pool: u256,
    pub settings_id: u32,
    pub start_time: u64,
    pub end_time: u64,
}

#[starknet::interface]
pub trait ITournamentDungeon<T> {
    fn create_tournament(ref self: T, name: ByteArray, entry_fee: u256, max_participants: u32) -> u32;
    fn join_tournament(ref self: T, tournament_id: u32) -> u64;
    fn get_tournament_leaderboard(self: @T, tournament_id: u32) -> Array<(ContractAddress, u16)>;
}

#[dojo::contract]
pub mod tournament_dungeon {
    use super::{ITournamentDungeon, Tournament};

    #[abi(embed_v0)]
    impl TournamentDungeonImpl of ITournamentDungeon<ContractState> {
        fn create_tournament(ref self: ContractState, name: ByteArray, entry_fee: u256, max_participants: u32) -> u32 {
            let mut world = self.world(@"tournament_namespace");

            // Create tournament-specific dungeon settings
            let settings_id = create_tournament_settings(name.clone());

            let tournament_id = world.uuid().try_into().unwrap();
            let tournament = Tournament {
                tournament_id,
                name,
                entry_fee,
                max_participants,
                current_participants: 0,
                prize_pool: 0,
                settings_id,
                start_time: starknet::get_block_timestamp(),
                end_time: starknet::get_block_timestamp() + 86400, // 24 hours
            };

            world.write_model(@tournament);
            tournament_id
        }

        fn join_tournament(ref self: ContractState, tournament_id: u32) -> u64 {
            let mut world = self.world(@"tournament_namespace");
            let mut tournament: Tournament = world.read_model(tournament_id);

            // Validate tournament state
            assert(tournament.current_participants < tournament.max_participants, 'Tournament full');
            assert(starknet::get_block_timestamp() < tournament.end_time, 'Tournament ended');

            // Process entry fee (implement payment logic)
            process_entry_fee(get_caller_address(), tournament.entry_fee);

            // Update tournament
            tournament.current_participants += 1;
            tournament.prize_pool += tournament.entry_fee;
            world.write_model(@tournament);

            // Create adventure for participant
            let adventurer_id = spawn_tournament_adventure(tournament.settings_id);

            adventurer_id
        }

        fn get_tournament_leaderboard(self: @ContractState, tournament_id: u32) -> Array<(ContractAddress, u16)> {
            // Implement leaderboard logic
            // Return sorted list of (player, score) pairs
            array![]
        }
    }
}
```

### Example 3: Custom Game Mechanics

```cairo
// Add custom mechanics on top of Death Mountain
#[derive(Drop, Serde)]
#[dojo::model]
pub struct CustomAdventurerData {
    #[key]
    pub adventurer_id: u64,
    pub magic_points: u16,
    pub reputation: u16,
    pub special_abilities: Array<u8>,
    pub achievement_unlocked: Array<u8>,
}

#[starknet::interface]
pub trait IEnhancedDungeon<T> {
    fn cast_spell(ref self: T, adventurer_id: u64, spell_id: u8);
    fn use_special_ability(ref self: T, adventurer_id: u64, ability_id: u8);
    fn check_achievements(ref self: T, adventurer_id: u64);
}

#[dojo::contract]
pub mod enhanced_dungeon {
    use super::{IEnhancedDungeon, CustomAdventurerData};

    #[abi(embed_v0)]
    impl EnhancedDungeonImpl of IEnhancedDungeon<ContractState> {
        fn cast_spell(ref self: ContractState, adventurer_id: u64, spell_id: u8) {
            let mut world = self.world(@"enhanced_namespace");
            let mut custom_data: CustomAdventurerData = world.read_model(adventurer_id);

            // Check if player has enough magic points
            let spell_cost = get_spell_cost(spell_id);
            assert(custom_data.magic_points >= spell_cost, 'Not enough magic points');

            // Consume magic points
            custom_data.magic_points -= spell_cost;

            // Apply spell effects (integrate with Death Mountain combat)
            apply_spell_effects(adventurer_id, spell_id);

            world.write_model(@custom_data);
        }

        fn use_special_ability(ref self: ContractState, adventurer_id: u64, ability_id: u8) {
            let mut world = self.world(@"enhanced_namespace");
            let custom_data: CustomAdventurerData = world.read_model(adventurer_id);

            // Check if ability is available
            assert(has_ability(custom_data.special_abilities, ability_id), 'Ability not available');

            // Execute ability
            match ability_id {
                1 => teleport_to_safe_room(adventurer_id),
                2 => summon_companion(adventurer_id),
                3 => restore_health(adventurer_id),
                _ => panic!("Unknown ability")
            }
        }

        fn check_achievements(ref self: ContractState, adventurer_id: u64) {
            let mut world = self.world(@"enhanced_namespace");
            let mut custom_data: CustomAdventurerData = world.read_model(adventurer_id);

            // Get current Death Mountain adventurer state
            let adventurer = get_death_mountain_adventurer(adventurer_id);

            // Check for new achievements
            let new_achievements = calculate_achievements(adventurer, custom_data.clone());

            // Update achievement list
            custom_data.achievement_unlocked = merge_achievements(
                custom_data.achievement_unlocked,
                new_achievements
            );

            world.write_model(@custom_data);
        }
    }

    // Helper functions
    #[generate_trait]
    impl HelperImpl of HelperTrait {
        fn get_spell_cost(spell_id: u8) -> u16 {
            match spell_id {
                1 => 10, // Fireball
                2 => 15, // Heal
                3 => 20, // Lightning
                _ => 0
            }
        }

        fn apply_spell_effects(adventurer_id: u64, spell_id: u8) {
            // Integration with Death Mountain combat system
            let game_contract = IGameSystemsDispatcher {
                contract_address: GAME_SYSTEMS.try_into().unwrap()
            };

            match spell_id {
                1 => {
                    // Fireball - enhanced attack
                    game_contract.attack(adventurer_id, true);
                    // Apply additional fire damage
                },
                2 => {
                    // Heal - restore health
                    restore_adventurer_health(adventurer_id, 20);
                },
                3 => {
                    // Lightning - area attack
                    game_contract.attack(adventurer_id, true);
                    // Apply chain lightning effect
                }
                _ => {}
            }
        }
    }
}
```

---

## Conclusion

Death Mountain provides a comprehensive dungeon crawling engine that can be easily integrated into your Dojo projects. The key to successful integration is understanding the three-phase workflow:

1. **Setup**: Create dungeon templates using Settings Systems
2. **Instance**: Mint game NFTs and start adventures using Game Systems
3. **Gameplay**: Execute dungeon actions and manage game state

With this foundation, you can build everything from simple dungeon crawlers to complex tournament systems and custom game mechanics. The modular architecture allows you to extend the base functionality while leveraging the robust combat, exploration, and progression systems that Death Mountain provides.

Remember to:
- Always validate game state before actions
- Handle errors gracefully
- Implement proper permission management
- Consider gas optimization for frequent actions
- Test thoroughly on testnets before mainnet deployment

Happy dungeon crawling! 🏔️⚔️

---

## Additional Resources

- [Death Mountain GitHub Repository](https://github.com/your-repo/death-mountain)
- [Dojo Documentation](https://www.dojoengine.org/)
- [StarkNet Documentation](https://docs.starknet.io/)
- [Tournaments Framework](https://github.com/Provable-Games/tournaments)

For questions and support, please check the GitHub issues or join the community Discord.
