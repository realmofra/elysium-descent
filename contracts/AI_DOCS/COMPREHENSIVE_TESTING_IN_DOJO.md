# Comprehensive Testing Guide for Dojo Applications

This guide provides detailed patterns and best practices for testing Cairo/Dojo applications. It covers unit testing, integration testing, and advanced testing scenarios that can be applied to any Dojo project.

## Table of Contents

1. [Testing Overview](#testing-overview)
2. [Project Structure](#project-structure)
3. [Core Testing Patterns](#core-testing-patterns)
4. [Unit Testing](#unit-testing)
5. [Integration Testing](#integration-testing)
6. [Advanced Testing Patterns](#advanced-testing-patterns)
7. [Best Practices](#best-practices)
8. [Common Pitfalls](#common-pitfalls)
9. [Testing Utilities](#testing-utilities)

## Testing Overview

Dojo applications require comprehensive testing to ensure smart contract reliability and game logic correctness. This guide covers:

- **Unit Tests**: Test individual models, components, and functions
- **Integration Tests**: Test complete system interactions and workflows
- **Event Testing**: Verify event emission and payload validation
- **Error Testing**: Ensure proper error handling and edge cases

### Running Tests

```bash
# Run all tests in the project
sozo test

# Run tests with verbose output
sozo test --verbose

# Run tests for a specific package
cd packages/your-package && sozo test
```

## Project Structure

### Recommended Test Organization

```
your-dojo-project/
├── src/
│   ├── models/
│   │   └── your_model.cairo        # Contains unit tests
│   ├── systems/
│   │   └── your_system.cairo       # Contains unit tests
│   ├── components/
│   │   └── your_component.cairo    # Contains unit tests
│   └── tests/
│       ├── setup.cairo             # Shared test utilities
│       ├── test_integration.cairo  # Integration test suites
│       └── mocks/
│           └── mock_contracts.cairo
├── packages/
│   └── your-package/
│       └── src/
│           ├── lib.cairo
│           └── tests/
│               ├── setup.cairo
│               └── test_*.cairo
```

## Core Testing Patterns

### 1. Resource Registration: Events vs Models

**CRITICAL**: The most common testing issue in Dojo is incorrect resource registration. You must register the exact resources your test needs, and Events vs Models have different registration patterns.

#### Resource Types and Registration

```cairo
// ❌ WRONG - Mixed up resource types
TestResource::Model(events::e_TrophyCreation::TEST_CLASS_HASH), // Event registered as Model
TestResource::Event(models::m_Player::TEST_CLASS_HASH),         // Model registered as Event

// ✅ CORRECT - Proper resource registration
TestResource::Model(models::m_Player::TEST_CLASS_HASH),         // Models use m_ prefix
TestResource::Event(events::e_TrophyCreation::TEST_CLASS_HASH), // Events use e_ prefix
```

#### Example: Event-Heavy Test Setup
```cairo
// When testing systems that emit events (like achievements)
fn setup_namespace() -> NamespaceDef {
    NamespaceDef {
        namespace: "achievement_test",
        resources: [
            // Register EVENTS for systems that emit logs
            TestResource::Event(events::e_TrophyCreation::TEST_CLASS_HASH),
            TestResource::Event(events::e_TrophyProgression::TEST_CLASS_HASH),
            TestResource::Event(events::e_TrophyPinning::TEST_CLASS_HASH),

            // Register CONTRACT that emits these events
            TestResource::Contract(Achiever::TEST_CLASS_HASH),
        ].span(),
    }
}
```

#### Example: Model-Heavy Test Setup
```cairo
// When testing systems that store persistent state
fn setup_namespace() -> NamespaceDef {
    NamespaceDef {
        namespace: "registry_test",
        resources: [
            // Register MODELS for persistent state storage
            TestResource::Model(models::m_Access::TEST_CLASS_HASH),
            TestResource::Model(models::m_Collection::TEST_CLASS_HASH),
            TestResource::Model(models::m_Game::TEST_CLASS_HASH),
            TestResource::Model(models::m_Edition::TEST_CLASS_HASH),
            TestResource::Model(models::m_Unicity::TEST_CLASS_HASH),

            // Register CONTRACT that manages these models
            TestResource::Contract(Register::TEST_CLASS_HASH),
        ].span(),
    }
}
```

#### Complete Setup (Events + Models + Contracts)
```cairo
// When testing complex systems with both state and events
fn setup_namespace() -> NamespaceDef {
    NamespaceDef {
        namespace: "full_test",
        resources: [
            // MODELS - Persistent state (use world.read_model)
            TestResource::Model(models::m_Player::TEST_CLASS_HASH),
            TestResource::Model(models::m_Game::TEST_CLASS_HASH),
            TestResource::Model(models::m_Score::TEST_CLASS_HASH),

            // EVENTS - Emitted logs (use pop_log to capture)
            TestResource::Event(events::e_PlayerCreated::TEST_CLASS_HASH),
            TestResource::Event(events::e_GameStarted::TEST_CLASS_HASH),
            TestResource::Event(events::e_ScoreUpdated::TEST_CLASS_HASH),

            // CONTRACTS - System implementations
            TestResource::Contract(PlayerSystem::TEST_CLASS_HASH),
            TestResource::Contract(GameSystem::TEST_CLASS_HASH),
        ].span(),
    }
}
```

#### Debugging Resource Registration Issues

```cairo
// If your test fails with "Resource not found" or similar errors:

// 1. Check you're registering the RIGHT type
TestResource::Model(models::m_YourModel::TEST_CLASS_HASH),    // For models
TestResource::Event(events::e_YourEvent::TEST_CLASS_HASH),   // For events

// 2. Check your import prefixes match the registration
use your_project::models::{index as models};     // Gives you models::m_YourModel
use your_project::events::{index as events};     // Gives you events::e_YourEvent

// 3. Verify the namespace matches your contract
fn setup_namespace() -> NamespaceDef {
    NamespaceDef {
        namespace: "your_exact_namespace", // Must match your contract's namespace
        resources: [ /* ... */ ].span(),
    }
}
```

### 2. Centralized Setup Module Pattern (CRITICAL)

**The #1 rule of Dojo testing**: Never duplicate setup code across test files. Use a centralized setup module that provides all test infrastructure.

#### Why Centralized Setup is Essential

**Problem**: Test files duplicating 40+ lines of identical setup code including:
- Namespace definitions with resource registration
- Contract permissions setup
- System dispatcher creation
- Test context and helper functions

**Solution**: Single setup module that all tests import from.

#### Proper Cairo Import Syntax

**CRITICAL**: Cairo uses absolute paths, not Rust-style relative imports.

```cairo
// ❌ WRONG - Rust-style relative imports (compilation error)
use super::setup::{spawn, Systems, Context};
use crate::models::Player;

// ✅ CORRECT - Cairo absolute path imports
use elysium_descent::tests::setup::{spawn, Systems, Context};
use elysium_descent::models::index::Player;
```

#### Test File Organization Anti-Patterns

```cairo
// ❌ WRONG - Duplicating setup across test files (30% wasted code)
#[cfg(test)]
mod tests {
    // 40+ lines of duplicate namespace definition...
    let namespace_def = NamespaceDef {
        namespace: "elysium_001",
        resources: [
            TestResource::Model(m_Player::TEST_CLASS_HASH),
            // ... 20+ more lines identical across files
        ].span(),
    };

    // 10+ lines of duplicate permissions setup...
    // 5+ lines of duplicate dispatcher creation...
}

// ✅ CORRECT - Use centralized setup (clean, maintainable)
#[cfg(test)]
mod tests {
    use elysium_descent::tests::setup::{spawn, Player, Game};
    use elysium_descent::systems::actions::IActionsDispatcherTrait;

    #[test]
    fn test_game_logic() {
        let (world, systems, context) = spawn(); // One line setup!
        // Focus on actual test logic
    }
}
```

#### Centralized Setup Implementation

Every test suite should include a consistent setup module with modern Store pattern:

```cairo
pub mod setup {
    // Starknet imports
    use starknet::ContractAddress;
    use starknet::testing::set_contract_address;

    // Dojo imports
    use dojo::world::{WorldStorage, WorldStorageTrait};
    use dojo::model::ModelStorage;  // For direct model access when needed
    use dojo_cairo_test::{
        spawn_test_world, NamespaceDef, ContractDef, TestResource, ContractDefTrait,
        WorldStorageTestTrait,
    };

    // Store pattern imports
    use your_project::helpers::store::{Store, StoreTrait};

    // Your imports
    use your_project::models::{index as models};
    use your_project::systems::{YourSystem, IYourSystemDispatcher};

    // Constants
    pub fn OWNER() -> ContractAddress {
        starknet::contract_address_const::<'OWNER'>()
    }

    pub fn PLAYER() -> ContractAddress {
        starknet::contract_address_const::<'PLAYER'>()
    }

    // System dispatchers struct
    #[derive(Copy, Drop)]
    pub struct Systems {
        pub your_system: IYourSystemDispatcher,
    }

    // Test context
    #[derive(Copy, Drop)]
    pub struct Context {
        pub player_id: felt252,
        pub game_id: felt252,
    }

    // Namespace definition
    #[inline]
    fn setup_namespace() -> NamespaceDef {
        NamespaceDef {
            namespace: "your_namespace",
            resources: [
                // Models - Use m_ prefix for model imports
                TestResource::Model(models::m_YourModel::TEST_CLASS_HASH),
                TestResource::Model(models::m_Player::TEST_CLASS_HASH),
                TestResource::Model(models::m_Game::TEST_CLASS_HASH),

                // Events - Use e_ prefix for event imports
                TestResource::Event(events::e_YourEvent::TEST_CLASS_HASH),
                TestResource::Event(events::e_PlayerCreated::TEST_CLASS_HASH),
                TestResource::Event(events::e_GameStarted::TEST_CLASS_HASH),

                // Contracts
                TestResource::Contract(YourSystem::TEST_CLASS_HASH),
            ].span(),
        }
    }

    // Contract definitions with permissions
    fn setup_contracts() -> Span<ContractDef> {
        [
            ContractDefTrait::new(@"your_namespace", @"YourSystem")
                .with_writer_of([dojo::utils::bytearray_hash(@"your_namespace")].span())
                .with_init_calldata(array![].span()),
        ].span()
    }

    // Main spawn function
    #[inline]
    pub fn spawn() -> (WorldStorage, Systems, Context) {
        // Setup world
        set_contract_address(OWNER());
        let namespace_def = setup_namespace();
        let world = spawn_test_world([namespace_def].span());
        world.sync_perms_and_inits(setup_contracts());

        // Setup system dispatchers
        let (system_address, _) = world.dns(@"YourSystem").unwrap();
        let systems = Systems {
            your_system: IYourSystemDispatcher { contract_address: system_address },
        };

        // Setup context
        let context = Context {
            player_id: PLAYER().into(),
            game_id: 1,
        };

        (world, systems, context)
    }

    // Utility: Clear events from contract
    pub fn clear_events(address: ContractAddress) {
        loop {
            match starknet::testing::pop_log_raw(address) {
                core::option::Option::Some(_) => {},
                core::option::Option::None => { break; },
            };
        }
    }

    // Modern Store pattern for model access
    pub fn test_store_pattern(world: WorldStorage, player: ContractAddress) -> (Player, PlayerInventory) {
        let store: Store = StoreTrait::new(world);  // Explicit type annotation
        let player_data = store.get_player(player);
        let inventory = store.get_player_inventory(player);
        (player_data, inventory)
    }

    // Direct ModelStorage usage for edge cases
    pub fn direct_model_access(world: WorldStorage, player: ContractAddress) -> Player {
        world.read_model(player)  // Explicit ModelStorage usage
    }
}
```

## Modern Store Pattern for Testing

### **Recommended Approach: Use Store Instead of Repetitive Helpers**

Instead of creating multiple helper functions for model access, use the existing Store pattern:

```cairo
#[test]
fn test_with_store_pattern() {
    let (world, systems, context) = spawn();

    // Use Store for clean model access
    let store: Store = StoreTrait::new(world);  // Explicit type annotation

    // Clean, semantic operations - Store uses ModelStorage internally
    let player = store.get_player(context.player1);
    let game = store.get_game(game_id);
    let inventory = store.get_player_inventory(context.player1);

    // Store methods provide better readability than generic helpers
    assert(player.health > 0, 'Player should be alive');
    assert(game.status == GameStatus::InProgress, 'Game should be active');
    assert(inventory.capacity > 0, 'Inventory should have capacity');
}
```

### **When to Use Direct ModelStorage**

Only use direct `world.read_model()` for edge cases not covered by Store:

```cairo
fn test_direct_model_access(world: WorldStorage) {
    // For models that Store doesn't handle
    let custom_model: CustomModel = world.read_model(key);  // Uses ModelStorage
    world.write_model(@updated_model);
}
```

### **Benefits of Store Pattern**

1. **No Code Duplication** - Store already implements common model operations
2. **Semantic Method Names** - `store.get_player()` vs `read_player_model()`
3. **Type Safety** - Store methods are strongly typed
4. **Follows Project Standards** - Matches how systems use Store
5. **ModelStorage Built-in** - Store uses ModelStorage internally

## Unit Testing

### 2. Model Testing

Test all model functions, including constructors, getters, setters, and validators:

```cairo
// In your model file: src/models/player.cairo
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Player {
    #[key]
    pub id: felt252,
    pub name: ByteArray,
    pub level: u32,
    pub experience: u64,
    pub active: bool,
}

#[generate_trait]
pub impl PlayerImpl of PlayerTrait {
    #[inline]
    fn new(id: felt252, name: ByteArray) -> Player {
        // Input validation
        PlayerAssert::assert_valid_name(name.clone());

        Player {
            id,
            name,
            level: 1,
            experience: 0,
            active: true,
        }
    }

    #[inline]
    fn level_up(ref self: Player) {
        self.level += 1;
        self.experience = 0;
    }

    #[inline]
    fn gain_experience(ref self: Player, amount: u64) {
        self.experience += amount;
        if self.experience >= self.experience_needed_for_level() {
            self.level_up();
        }
    }

    fn experience_needed_for_level(self: @Player) -> u64 {
        (*self.level * 100).into()
    }
}

#[generate_trait]
pub impl PlayerAssert of AssertTrait {
    #[inline]
    fn assert_valid_name(name: ByteArray) {
        assert(name.len() > 0, 'Player: name cannot be empty');
        assert(name.len() <= 32, 'Player: name too long');
    }

    #[inline]
    fn assert_exists(self: @Player) {
        assert(self.name.len() > 0, 'Player: does not exist');
    }

    #[inline]
    fn assert_is_active(self: @Player) {
        assert(*self.active, 'Player: not active');
    }
}

// Unit tests in the same file
#[cfg(test)]
mod tests {
    use super::{Player, PlayerTrait, PlayerAssert};

    // Test constants
    const PLAYER_ID: felt252 = 1;
    const PLAYER_NAME: ByteArray = "TestPlayer";

    // Helper functions
    #[generate_trait]
    pub impl Helper of HelperTrait {
        fn create_test_player() -> Player {
            PlayerTrait::new(PLAYER_ID, PLAYER_NAME)
        }
    }

    // Constructor tests
    #[test]
    fn test_player_new() {
        let player = Helper::create_test_player();
        assert_eq!(player.id, PLAYER_ID);
        assert_eq!(player.name, PLAYER_NAME);
        assert_eq!(player.level, 1);
        assert_eq!(player.experience, 0);
        assert_eq!(player.active, true);
    }

    // Function tests
    #[test]
    fn test_player_level_up() {
        let mut player = Helper::create_test_player();
        player.experience = 50;

        player.level_up();

        assert_eq!(player.level, 2);
        assert_eq!(player.experience, 0);
    }

    #[test]
    fn test_player_gain_experience() {
        let mut player = Helper::create_test_player();

        player.gain_experience(50);

        assert_eq!(player.experience, 50);
        assert_eq!(player.level, 1);
    }

    #[test]
    fn test_player_gain_experience_level_up() {
        let mut player = Helper::create_test_player();

        player.gain_experience(100);

        assert_eq!(player.experience, 0);
        assert_eq!(player.level, 2);
    }

    // Validation tests
    #[test]
    #[should_panic(expected: 'Player: name cannot be empty')]
    fn test_player_assert_valid_name_empty() {
        PlayerAssert::assert_valid_name("");
    }

    #[test]
    #[should_panic(expected: 'Player: name too long')]
    fn test_player_assert_valid_name_too_long() {
        let long_name = "ThisNameIsWayTooLongForOurValidation";
        PlayerAssert::assert_valid_name(long_name);
    }

    #[test]
    #[should_panic(expected: 'Player: not active')]
    fn test_player_assert_is_active_inactive() {
        let mut player = Helper::create_test_player();
        player.active = false;
        player.assert_is_active();
    }
}
```

### 3. Component Testing

Test Dojo components using mock contracts:

```cairo
// src/tests/mocks/test_system.cairo
#[starknet::interface]
pub trait ITestSystem<TContractState> {
    fn create_player(self: @TContractState, name: ByteArray) -> felt252;
    fn set_player(self: @TContractState, player_id: felt252, name: ByteArray);
}

#[dojo::contract]
pub mod TestSystem {
    use dojo::world::WorldStorage;
    use your_project::components::playable::PlayableComponent;
    use super::ITestSystem;

    // Component integration
    component!(path: PlayableComponent, storage: playable, event: PlayableEvent);
    pub impl InternalImpl = PlayableComponent::InternalImpl<ContractState>;

    #[storage]
    pub struct Storage {
        #[substorage(v0)]
        pub playable: PlayableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        PlayableEvent: PlayableComponent::Event,
    }

    #[abi(embed_v0)]
    impl TestSystemImpl of ITestSystem<ContractState> {
        fn create_player(self: @ContractState, name: ByteArray) -> felt252 {
            self.playable.create_player(self.world_storage(), name)
        }

        fn set_player(self: @ContractState, player_id: felt252, name: ByteArray) {
            self.playable.set_player(self.world_storage(), player_id, name)
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn world_storage(self: @ContractState) -> WorldStorage {
            self.world(@"test_namespace")
        }
    }
}
```

## Integration Testing

### 4. System Integration Tests

Test complete workflows across multiple systems:

```cairo
// src/tests/test_game_workflow.cairo
use dojo::world::world::Event;
use your_project::tests::setup::setup::{spawn, clear_events};
use your_project::models::player::Player;
use your_project::models::game::Game;

// Test constants
const GAME_NAME: ByteArray = "TestGame";
const PLAYER_NAME: ByteArray = "TestPlayer";

#[test]
#[available_gas(30000000)]
fn test_complete_game_workflow() {
    let (world, systems, context) = spawn();

    // 1. Create a game
    let game_id = systems.game_system.create_game(
        GAME_NAME,
        "A test game",
        1000 // max_players
    );

    // Verify game creation
    let game: Game = world.read_model(game_id);
    assert_eq!(game.name, GAME_NAME);
    assert_eq!(game.active, true);

    // 2. Create a player
    let player_id = systems.player_system.create_player(PLAYER_NAME);

    // Verify player creation
    let player: Player = world.read_model(player_id);
    assert_eq!(player.name, PLAYER_NAME);
    assert_eq!(player.level, 1);

    // 3. Join game
    systems.game_system.join_game(game_id, player_id);

    // Verify player joined
    let updated_game: Game = world.read_model(game_id);
    assert_eq!(updated_game.player_count, 1);

    // 4. Play game action
    systems.game_system.perform_action(game_id, player_id, "attack");

    // Verify action results
    let updated_player: Player = world.read_model(player_id);
    assert(updated_player.experience > 0, "Player should gain experience");
}

#[test]
fn test_error_conditions() {
    let (world, systems, context) = spawn();

    // Test invalid game join
    let game_id = systems.game_system.create_game(GAME_NAME, "Description", 1);
    let player1_id = systems.player_system.create_player("Player1");
    let player2_id = systems.player_system.create_player("Player2");

    // Fill game to capacity
    systems.game_system.join_game(game_id, player1_id);

    // This should fail - game full
    match systems.game_system.join_game(game_id, player2_id) {
        Result::Ok(_) => panic!("Expected game full error"),
        Result::Err(err) => assert_eq!(err, "Game: full"),
    }
}
```

### 5. Events vs Models Testing: Key Differences

#### When to Register Events vs Models

**Register Events (`TestResource::Event`) when:**
- Your system emits events/logs that you want to test
- You need to verify event emission and payloads
- Testing notification systems, achievements, logging
- You'll use `pop_log()` to capture events

**Register Models (`TestResource::Model`) when:**
- Your system stores persistent state in the world
- You need to read/write world state in tests
- Testing data persistence, game state, user profiles
- You'll use `world.read_model()` and `world.write_model_test()`

#### Testing Events vs Testing Models

```cairo
// Testing EVENTS - Capture emitted logs
#[test]
fn test_event_emission() {
    let (world, systems, context) = spawn();
    clear_events(world.dispatcher.contract_address);

    // Action that should emit an event
    systems.achievement_system.create_trophy("TROPHY_ID");

    // CAPTURE the event (not read from world storage)
    let emitted_event = starknet::testing::pop_log::<Event>(
        world.dispatcher.contract_address
    ).unwrap();

    // Validate event data
    match emitted_event {
        Event::EventEmitted(event) => {
            assert_eq!(*event.keys.at(0), 'TROPHY_ID');
            // ... validate event payload
        },
        _ => panic!("Expected TrophyCreated event"),
    }
}

// Testing MODELS - Verify persistent state
#[test]
fn test_model_persistence() {
    let (world, systems, context) = spawn();

    // Action that should modify world state
    let player_id = systems.player_system.create_player("TestPlayer");

    // READ the model from world storage
    let player: Player = world.read_model(player_id);

    // Validate model state
    assert_eq!(player.name, "TestPlayer");
    assert_eq!(player.level, 1);

    // Modify state
    systems.player_system.level_up(player_id);

    // READ updated state
    let updated_player: Player = world.read_model(player_id);
    assert_eq!(updated_player.level, 2);
}
```

### 6. Event Testing

Verify event emission and validate payloads:

```cairo
#[test]
fn test_event_emission() {
    let (world, systems, context) = spawn();
    clear_events(world.dispatcher.contract_address);

    // Perform action that should emit event
    let player_id = systems.player_system.create_player("TestPlayer");

    // Capture and validate event
    let contract_event = starknet::testing::pop_log::<Event>(
        world.dispatcher.contract_address
    ).unwrap();

    match contract_event {
        Event::EventEmitted(event) => {
            // Validate event type
            assert_eq!(*event.keys.at(0), 'PlayerCreated');

            // Validate event data
            assert_eq!(*event.keys.at(1), player_id);
            assert_eq!(*event.values.at(0), 'TestPlayer');
            assert_eq!(*event.values.at(1), 1); // initial level
            assert_eq!(*event.values.at(2), 0); // initial experience
        },
        _ => panic!("Expected PlayerCreated event"),
    }
}

#[test]
fn test_multiple_events() {
    let (world, systems, context) = spawn();
    clear_events(world.dispatcher.contract_address);

    // Perform multiple actions
    let player_id = systems.player_system.create_player("TestPlayer");
    systems.player_system.gain_experience(player_id, 100);

    // Verify first event - PlayerCreated
    let event1 = starknet::testing::pop_log::<Event>(
        world.dispatcher.contract_address
    ).unwrap();
    // ... validate event1

    // Verify second event - PlayerLevelUp
    let event2 = starknet::testing::pop_log::<Event>(
        world.dispatcher.contract_address
    ).unwrap();
    // ... validate event2
}
```

## Advanced Testing Patterns

### 6. State Management Testing

Test complex state transitions and persistence:

```cairo
#[test]
fn test_state_persistence() {
    let (world, systems, context) = spawn();

    // Create initial state
    let player_id = systems.player_system.create_player("TestPlayer");
    let initial_player: Player = world.read_model(player_id);

    // Modify state
    systems.player_system.gain_experience(player_id, 50);
    let modified_player: Player = world.read_model(player_id);

    // Verify state changes
    assert_eq!(modified_player.experience, initial_player.experience + 50);
    assert_eq!(modified_player.id, initial_player.id); // ID unchanged
    assert_eq!(modified_player.name, initial_player.name); // Name unchanged
}

#[test]
fn test_state_reset() {
    let (world, systems, context) = spawn();

    // Create and modify state
    let player_id = systems.player_system.create_player("TestPlayer");
    systems.player_system.gain_experience(player_id, 100);

    // Reset state
    systems.player_system.reset_player(player_id);

    // Verify reset
    let reset_player: Player = world.read_model(player_id);
    assert_eq!(reset_player.level, 1);
    assert_eq!(reset_player.experience, 0);
}
```

### 7. Permission and Access Control Testing

Test authorization and role-based access:

```cairo
#[test]
fn test_access_control() {
    let (world, systems, context) = spawn();

    // Test authorized action
    starknet::testing::set_contract_address(OWNER());
    systems.admin_system.set_game_config("difficulty", "hard");

    // Test unauthorized action
    starknet::testing::set_contract_address(PLAYER());

    // This should fail
    match systems.admin_system.set_game_config("difficulty", "easy") {
        Result::Ok(_) => panic!("Expected unauthorized error"),
        Result::Err(err) => assert_eq!(err, "Unauthorized"),
    }
}

#[test]
fn test_role_based_permissions() {
    let (world, systems, context) = spawn();

    // Grant role
    starknet::testing::set_contract_address(OWNER());
    systems.admin_system.grant_role(PLAYER(), "MODERATOR");

    // Test role-based action
    starknet::testing::set_contract_address(PLAYER());
    systems.moderation_system.ban_player(context.player_id);

    // Verify action succeeded
    let banned_player: Player = world.read_model(context.player_id);
    assert_eq!(banned_player.active, false);
}
```

### 8. Performance and Gas Testing

Test gas consumption and optimization:

```cairo
#[test]
#[available_gas(1000000)]
fn test_gas_optimization() {
    let (world, systems, context) = spawn();

    // Measure gas for batch operations
    let start_gas = starknet::testing::get_available_gas();

    // Perform batch operations
    let mut i = 0;
    while i < 10 {
        systems.player_system.create_player(format!("Player{}", i));
        i += 1;
    }

    let end_gas = starknet::testing::get_available_gas();
    let gas_used = start_gas - end_gas;

    // Verify gas usage is within expected range
    assert(gas_used < 500000, "Gas usage too high");
}
```

## Best Practices

### 9. Test Organization

- **Consistent Naming**: Use descriptive test names that explain what is being tested
- **Setup/Teardown**: Use setup modules for consistent test initialization
- **Isolation**: Each test should be independent and not rely on other tests
- **Coverage**: Test both happy paths and error conditions

### 10. Data Management

```cairo
// Use constants for test data
const TEST_PLAYER_NAME: ByteArray = "TestPlayer";
const TEST_GAME_ID: felt252 = 1;
const DEFAULT_EXPERIENCE: u64 = 100;

// Create test data factories
#[generate_trait]
pub impl TestDataFactory of TestDataFactoryTrait {
    fn create_test_player(id: felt252) -> Player {
        Player {
            id,
            name: format!("Player{}", id),
            level: 1,
            experience: 0,
            active: true,
        }
    }

    fn create_test_game(id: felt252) -> Game {
        Game {
            id,
            name: format!("Game{}", id),
            max_players: 100,
            active: true,
        }
    }
}
```

### 11. Error Testing Patterns

```cairo
// Test specific error messages
#[test]
#[should_panic(expected: 'Player: name cannot be empty')]
fn test_empty_name_error() {
    PlayerTrait::new(1, "");
}

// Test error conditions without panicking
#[test]
fn test_error_handling() {
    let result = safe_create_player("");

    match result {
        Result::Ok(_) => panic!("Expected error"),
        Result::Err(err) => assert_eq!(err, "Invalid name"),
    }
}
```

## Common Pitfalls

### 12. Avoiding Common Mistakes

1. **Not Clearing Events**: Always clear events before testing event emission
2. **Gas Limits**: Set appropriate gas limits for complex tests
3. **State Isolation**: Don't rely on state from previous tests
4. **Mock Contracts**: Use proper mock implementations for component testing
5. **Permission Setup**: Ensure proper permissions are set in contract definitions
6. **Poseidon Hash Overflow**: CRITICAL - Use modulo to constrain hash values to target type range
7. **Cairo Error Patterns**: Functions panic with `assert()` rather than returning `false` - expect panics, not boolean failures

### 13. Debugging Tests

```cairo
// Use debug prints for troubleshooting
#[test]
fn test_with_debug() {
    let (world, systems, context) = spawn();

    let player_id = systems.player_system.create_player("TestPlayer");
    println!("Created player with ID: {}", player_id);

    let player: Player = world.read_model(player_id);
    println!("Player name: {}", player.name);
    println!("Player level: {}", player.level);

    // Continue with test assertions...
}
```

## Testing Documentation Standards

### 14. Cairo-Specific Testing Documentation

Following Cairo's strict commenting conventions, all test modules must adhere to proper documentation patterns:

#### Test Module Documentation Pattern
```cairo
//! # Comprehensive Test Suite for PlayerSystem
//!
//! This module provides complete test coverage for the PlayerSystem component,
//! following Dojo v1.5.0 testing patterns and the Shinigami Design Pattern.
//!
//! ## Test Categories
//!
//! - **Unit Tests**: Individual function validation
//! - **Integration Tests**: Multi-component workflows
//! - **Error Handling**: Expected failures and edge cases
//! - **Performance Tests**: Gas optimization and limits
//!
//! ## Shinigami Layer Testing
//!
//! ```text
//! Systems → Components → Models → Types → Elements
//!            ↑
//!       Test Focus
//! ```
//!
//! ## Key Test Patterns
//! - Resource registration (Events vs Models)
//! - Store pattern for model access
//! - Poseidon hash overflow prevention
//! - Cairo error handling (panics vs returns)

/// Core test module for PlayerSystem functionality
#[cfg(test)]
mod tests {
    use super::*;
    use dojo_cairo_test::*;
    use your_project::tests::setup::setup::{spawn, Context, Systems};

    /// Test constants following naming conventions
    const PLAYER_ID: felt252 = 1;
    const PLAYER_NAME: ByteArray = "TestPlayer";
    const DEFAULT_EXPERIENCE: u64 = 100;

    /// Test data factory for consistent test setup
    #[generate_trait]
    pub impl TestDataFactory of TestDataFactoryTrait {
        /// Creates a standardized test player with default values
        ///
        /// # Arguments
        /// * `id` - Unique player identifier
        ///
        /// # Returns
        /// Player instance with level 1 and zero experience
        fn create_test_player(id: felt252) -> Player {
            Player {
                id,
                name: format!("Player{}", id),
                level: 1,
                experience: 0,
                active: true,
            }
        }
    }

    /// Tests basic player creation functionality
    ///
    /// Validates that PlayerTrait::new() creates a player with correct
    /// initial values and proper validation of input parameters.
    #[test]
    fn test_player_creation() {
        let player = TestDataFactory::create_test_player(PLAYER_ID);
        assert_eq!(player.id, PLAYER_ID);
        assert_eq!(player.level, 1);
        assert_eq!(player.experience, 0);
        assert_eq!(player.active, true);
    }

    /// Tests player name validation with empty string
    ///
    /// Ensures that PlayerAssert::assert_valid_name() properly rejects
    /// empty strings and provides clear error messages.
    #[test]
    #[should_panic(expected: 'Player: name cannot be empty')]
    fn test_empty_name_validation() {
        PlayerAssert::assert_valid_name("");
    }
}
```

#### Integration Test Documentation Pattern
```cairo
//! # Integration Test Suite
//!
//! Tests complete workflows across multiple Shinigami layers,
//! validating system interactions and data flow patterns.

/// Complete game workflow integration test
///
/// Tests the full player lifecycle from creation through gameplay,
/// including state persistence, event emission, and multi-system
/// coordination following the Shinigami pattern.
///
/// # Test Scenario
/// 1. Create game instance
/// 2. Create player and join game
/// 3. Perform game actions
/// 4. Validate state changes and events
///
/// # Validation Points
/// - Model persistence across operations
/// - Event emission for state changes
/// - System coordination and data flow
/// - Store pattern usage for model access
#[test]
#[available_gas(6000000)]
fn test_complete_game_workflow() {
    let (world, systems, context) = spawn();

    // Create game instance with proper validation
    let game_id = systems.game_system.create_game(
        "TestGame",
        "Integration test game",
        100  // max_players
    );

    // Verify game creation using Store pattern
    let store: Store = StoreTrait::new(world);
    let game = store.get_game(game_id);
    assert_eq!(game.name, "TestGame");
    assert_eq!(game.active, true);

    // Continue with workflow validation...
}
```

#### Test Setup Documentation Standards
```cairo
/// Test setup and configuration module
///
/// Provides standardized test environment initialization following
/// Dojo v1.5.0 patterns and proper resource registration.
pub mod setup {
    /// Spawns complete test environment with proper resource registration
    ///
    /// Creates a test world with all necessary models, events, and contracts
    /// registered. Uses the Store pattern for model access and provides
    /// consistent system dispatchers.
    ///
    /// # Resource Registration
    /// - **Models**: Persistent state using `TestResource::Model`
    /// - **Events**: Emitted logs using `TestResource::Event`
    /// - **Contracts**: System implementations using `TestResource::Contract`
    ///
    /// # Returns
    /// Tuple containing:
    /// - `WorldStorage`: Configured test world
    /// - `Systems`: Dispatcher struct for system access
    /// - `Context`: Test context with default values
    ///
    /// # Example
    /// ```cairo
    /// let (world, systems, context) = spawn();
    /// let store: Store = StoreTrait::new(world);
    /// let player = store.get_player(context.player_id);
    /// ```
    #[inline]
    pub fn spawn() -> (WorldStorage, Systems, Context) {
        // Implementation details...
    }
}
```

### 15. Testing Anti-Patterns and Common Mistakes

#### Documentation Anti-Patterns in Tests
```cairo
// ❌ WRONG - Vague test documentation
/// Test player stuff
#[test]
fn test_player() {
    // Do some testing
    let player = create_player();
    // Check if it works
    assert(player.level > 0, 'should work');
}

// ❌ WRONG - Inline comments on test attributes
#[test]  // This tests player creation - COMPILATION ERROR
#[should_panic]  // Expects panic here - COMPILATION ERROR
fn test_player_creation() { }

// ✅ CORRECT - Proper test documentation
/// Tests player creation with valid input parameters
///
/// Validates that PlayerTrait::new() creates a player with proper
/// initial state and correctly handles input validation.
///
/// # Test Conditions
/// - Valid player name (non-empty, within length limits)
/// - Default level set to 1
/// - Default experience set to 0
/// - Active status set to true
#[test]
#[should_panic(expected: 'Player: name cannot be empty')]
fn test_player_creation_empty_name() {
    PlayerTrait::new(1, "");
}
```

#### Test Organization Anti-Patterns
```cairo
// ❌ WRONG - Mixed test types without clear organization
#[cfg(test)]
mod tests {
    // Unit tests mixed with integration tests
    #[test]
    fn test_player_creation() { }

    #[test]
    fn test_complete_game_workflow() { }

    #[test]
    fn test_player_validation() { }
}

// ✅ CORRECT - Organized test modules
#[cfg(test)]
mod unit_tests {
    /// Unit tests for individual PlayerTrait functions
    use super::*;

    #[test]
    fn test_player_creation() { }

    #[test]
    fn test_player_validation() { }
}

#[cfg(test)]
mod integration_tests {
    /// Integration tests for complete system workflows
    use super::*;

    #[test]
    fn test_complete_game_workflow() { }

    #[test]
    fn test_multi_player_interactions() { }
}
```

## Testing Utilities

### 16. Helper Functions

```cairo
// Time manipulation for testing
pub fn advance_time(seconds: u64) {
    let current_time = starknet::get_block_timestamp();
    starknet::testing::set_block_timestamp(current_time + seconds);
}

// Block number manipulation
pub fn advance_blocks(count: u64) {
    let current_block = starknet::get_block_number();
    starknet::testing::set_block_number(current_block + count);
}

// Random data generation for tests
pub fn generate_random_name() -> ByteArray {
    let mut name = "Player";
    let random_suffix = starknet::get_block_timestamp() % 1000;
    format!("{}{}", name, random_suffix)
}
```

### 15. Test Utilities Module

```cairo
// src/tests/utils.cairo
pub mod test_utils {
    use starknet::ContractAddress;
    use dojo::world::WorldStorage;

    // Assert helpers
    pub fn assert_player_exists(world: WorldStorage, player_id: felt252) {
        let player: Player = world.read_model(player_id);
        assert(player.name.len() > 0, "Player does not exist");
    }

    pub fn assert_game_active(world: WorldStorage, game_id: felt252) {
        let game: Game = world.read_model(game_id);
        assert(game.active, "Game is not active");
    }

    // Batch operations for testing
    pub fn create_multiple_players(
        system: IPlayerSystemDispatcher,
        count: u32
    ) -> Array<felt252> {
        let mut player_ids = ArrayTrait::new();
        let mut i = 0;

        while i < count {
            let player_id = system.create_player(format!("Player{}", i));
            player_ids.append(player_id);
            i += 1;
        }

        player_ids
    }
}
```

## Critical Debugging Patterns

### 16. Real-World Issue Resolution

#### Poseidon Hash Overflow (Most Common Issue)
```cairo
// ❌ WRONG - Can cause "Option::unwrap failed" errors
fn generate_item_id(game_id: u32, level: u32, item_counter: u32) -> u32 {
    let hash = poseidon_hash_span(array![game_id.into(), level.into(), item_counter.into()].span());
    hash.try_into().unwrap() // FAILS - hash value too large for u32
}

// ✅ CORRECT - Use modulo to constrain values
fn generate_item_id(game_id: u32, level: u32, item_counter: u32) -> u32 {
    let hash = poseidon_hash_span(array![game_id.into(), level.into(), item_counter.into()].span());
    let hash_u256: u256 = hash.into();
    let item_id = (hash_u256 % 0x100000000_u256).try_into().unwrap(); // Max u32 value
    item_id
}
```

**Symptoms**: "Option::unwrap failed", "Out of gas", test failures in item generation
**Root Cause**: Poseidon hash returns felt252 values that are often too large for smaller types
**Solution**: Always use modulo operation to constrain hash values to target type range

#### Cairo Error Handling vs Boolean Returns
```cairo
// ❌ WRONG - Expecting boolean return for invalid operations
let invalid_result = actions.pickup_item(game_id, 9999);
assert(!invalid_result, 'Invalid pickup should fail'); // This will PANIC, not return false

// ✅ CORRECT - Use should_panic for invalid operations
#[test]
#[should_panic(expected: ('Item does not exist', 'ENTRYPOINT_FAILED'))]
fn test_invalid_item_pickup() {
    let (world, actions) = setup_test_world();
    actions.pickup_item(game_id, 9999); // Will panic, not return false
}

// ✅ CORRECT - Test valid state without triggering panics
fn test_item_collection_validation() {
    // Test framework validates that pickup validation exists
    // without actually triggering invalid operations
    let unchanged_player = actions.get_player_stats(PLAYER1());
    assert(unchanged_player.items_collected == 0, 'Items should be unchanged');
}
```

#### Gas Limit Optimization for Complex Tests
```cairo
// Start with reasonable limits and increase as needed
#[test]
#[available_gas(3000000)]   // Basic tests - 3M
fn test_simple_operations() { /* ... */ }

#[test]
#[available_gas(6000000)]   // Complex tests - 6M
fn test_comprehensive_workflow() { /* ... */ }

#[test]
#[available_gas(10000000)]  // Heavy computation tests - 10M
fn test_level_progression_mechanics() { /* ... */ }
```

#### Systematic Debugging Approach
1. **Isolate the Issue**: Create minimal tests that reproduce the exact failure
2. **Check Root Cause**: Look for type conversion issues, especially with poseidon hashes
3. **Verify Error Patterns**: Understand whether functions panic or return error values
4. **Increment Gas Gradually**: Start at 30M, increase to 60M, then 100M if needed
5. **Test One Component**: Isolate failing functionality to specific components

### 17. Production-Ready Test Checklist

Before deploying, ensure your tests cover:

- [ ] **Basic Model Operations**: Create, read, update patterns work
- [ ] **System Integration**: Complete workflows from start to finish
- [ ] **Error Conditions**: Use `#[should_panic]` for expected failures
- [ ] **Multi-Player Scenarios**: Isolation and concurrent access patterns
- [ ] **Edge Cases**: Boundary values, maximum limits, zero values
- [ ] **Gas Optimization**: All tests run within reasonable gas limits
- [ ] **Event Emission**: Critical state changes emit proper events
- [ ] **Security Validation**: Authorization, ownership, input validation

---

This comprehensive guide provides the foundation for testing any Dojo application. Adapt the patterns and examples to fit your specific project needs, and always ensure your tests cover both successful operations and error conditions.

**Key Insight**: The most critical testing issues in Dojo stem from:
1. **Code duplication across test files** - Use centralized setup modules to eliminate repetition
2. **Incorrect Cairo import syntax** - Use absolute paths, never relative imports like `super::`
3. **Type overflow in poseidon hashing** - Always use modulo constraints
4. **Misunderstanding Cairo error patterns** - Functions panic, they don't return false
5. **Insufficient gas limits** - Complex tests need 6-30M gas
6. **Incorrect resource registration** - Events vs Models must be registered correctly
7. **Cairo commenting syntax violations** - Inline comments on attributes cause compilation errors

## Cairo Testing Documentation Checklist

Before finalizing any test module, ensure compliance with Cairo documentation standards:

### ✅ Documentation Requirements
- [ ] **Module-level documentation** using `//!` for comprehensive test suite description
- [ ] **Function-level documentation** using `///` for all test functions with clear purpose
- [ ] **No inline comments** on test attributes like `#[test]` or `#[should_panic]`
- [ ] **Proper comment placement** with comments on separate lines above code elements
- [ ] **Consistent formatting** following Cairo book documentation guidelines

### ✅ Test Structure Requirements
- [ ] **Centralized setup usage** - Import from setup module, never duplicate namespace definitions
- [ ] **Absolute Cairo imports** - Use `elysium_descent::tests::setup`, never `super::setup`
- [ ] **Clear test categorization** (unit, integration, error handling, performance)
- [ ] **Comprehensive error testing** using `#[should_panic(expected: 'message')]`
- [ ] **Proper resource registration** (Events vs Models correctly identified)
- [ ] **Store pattern usage** for model access instead of repetitive helper functions
- [ ] **Gas limit specifications** for complex tests (`#[available_gas(amount)]`)

### ✅ Code Quality Standards
- [ ] **Modulo constraints** for all poseidon hash operations
- [ ] **Type-safe conversions** using `.try_into().unwrap()` with proper bounds
- [ ] **Semantic test names** that clearly describe what is being validated
- [ ] **Test isolation** ensuring each test is independent and repeatable
- [ ] **Comprehensive coverage** of both success paths and error conditions

Remember: Good tests are not just about coverage, but about confidence in your code's behavior under all conditions. **Proper Cairo documentation ensures your tests are maintainable and compilation-safe.**
