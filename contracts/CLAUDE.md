# CLAUDE.md - Cairo/Dojo Development Guidance

This file provides Cairo and Dojo-specific guidance for contract development in Elysium Descent.

## Project Context

Elysium Descent follows the **Shinigami Design Pattern** with Cairo smart contracts on Starknet using Dojo v1.5.0. The namespace is `elysium_001`.

## Essential Cairo Language Constraints

### Memory & Ownership
- **Arrays are immutable** - use `.append()` to extend, cannot modify existing elements
- **Variables can be reassigned** but follow Rust-like ownership rules
- **Snapshots (@)** for immutable references, **desnap (*)** only works on snapshots
- **No traditional loops** - use recursion or array utilities from standard library

### Type System & Conversions
```cairo
// WRONG - will fail for large numbers
let id_u32: u32 = id_u64.into();

// CORRECT - safe conversion
let id_u32: u32 = id_u64.try_into().unwrap();

// ContractAddress conversions require intermediate felt252
let addr_felt: felt252 = contract_address.into();
let addr_u32: u32 = addr_felt.try_into().unwrap();
```

### Bit Operations (No Bit Shifting)
```cairo
// Use multiplication/division instead of bit shifts
let packed = packed | ((powerup_type * 0x1000_u256) & POWERUP_MASK);
let unpacked = (flipped_u256 & POWERUP_DATA_MASK) / 0x10;
```

## Dojo Framework Essentials

### Required Imports
```cairo
// For reading/writing models
use dojo::model::{ModelStorage};

// For emitting events
use dojo::event::EventStorage;

// For world access with DNS
use dojo::world::{WorldStorage, WorldStorageTrait};
```

### World Access Pattern
```cairo
// ALWAYS specify the correct namespace
let mut world = self.world(@"elysium_001");

// For reading - world can be immutable
let world = self.world(@"elysium_001");
```

## Shinigami Pattern Implementation

### Directory Structure & Placement Rules
```
contracts/src/
├── elements/     # Game entities (weapons, enemies, rooms) - MISSING - ADD THESE
├── types/        # Enums and entry points (ItemType, ActionType)
├── models/       # Persistent blockchain state
├── components/   # Multi-model business logic operations
├── systems/      # Game mode configurations
└── helpers/      # Reusable utility functions (top of hierarchy)
```

### Hierarchical Dependencies
- **Helpers** → **Systems** → **Components** → **Models** → **Types** → **Elements**
- Higher layers depend on lower layers, NEVER reverse
- When adding new functionality, place it in the appropriate layer

### Component vs System vs Model Decisions
- **Elements**: Specific game entities with traits (Weapon, Enemy, Room)
- **Types**: Entry points and enums that route to Elements
- **Models**: Data persistence with `#[dojo::model]` and `#[key]` attributes
- **Components**: Multi-model operations (CombatComponent, TradingComponent)
- **Systems**: Game modes that configure how Components interact
- **Helpers**: Pure utility functions without game-specific data

## Dojo Model Patterns

### Required Model Structure
```cairo
#[derive(Drop, Serde)]  // ALWAYS required - will not compile without
#[dojo::model]
pub struct GameModel {
    #[key]                // At least one key required
    pub player: ContractAddress,
    #[key]                // Multiple keys supported - ALL must come before non-key fields
    pub game_id: u64,
    pub data: u32,        // Non-key fields come after keys
}
```

### Trait Derivation Rules
```cairo
// SAFE - no Arrays or ByteArrays
#[derive(Copy, Drop, Serde, IntrospectPacked)]
struct SimpleData { x: u32, y: u32 }

// UNSAFE - Cannot use Copy with Array/ByteArray
#[derive(Drop, Serde)]  // NO Copy trait
struct ComplexData {
    items: Array<u32>,
    name: ByteArray,
}
```

### Custom Types in Models
```cairo
// Inner structs do NOT use #[dojo::model]
#[derive(Drop, Serde, Introspect)]
struct ItemData {
    pub damage: u32,
    pub durability: u32,
}

// Enums for game logic
#[derive(Serde, Drop, Introspect, PartialEq)]
pub enum ItemType {
    Weapon,
    Armor,
    Consumable,
}
```

## Dojo System Patterns

### Contract Structure Template
```cairo
use crate::models::{Player, Inventory};
use crate::types::{ItemType, ActionType};

#[starknet::interface]
pub trait IGameActions<T> {
    fn create_player(ref self: T);
    fn pickup_item(ref self: T, item_id: u32);
}

#[dojo::contract]
pub mod game_actions {
    use super::IGameActions;
    use starknet::{ContractAddress, get_caller_address};
    use dojo::model::{ModelStorage};
    use dojo::event::EventStorage;

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct ItemPickedUp {
        #[key]
        pub player: ContractAddress,
        pub item_id: u32,
    }

    #[abi(embed_v0)]
    impl GameActionsImpl of IGameActions<ContractState> {
        fn create_player(ref self: ContractState) {
            let mut world = self.world(@"elysium_001");
            let player = get_caller_address();

            // Read model (returns default if not exists)
            let mut player_data: Player = world.read_model(player);

            // Update and write back
            player_data.level = 1;
            world.write_model(@player_data);
        }

        fn pickup_item(ref self: ContractState, item_id: u32) {
            let mut world = self.world(@"elysium_001");
            let player = get_caller_address();

            // Validation
            assert(item_id > 0, 'Invalid item ID');

            // Multi-model operation
            let mut inventory: Inventory = world.read_model(player);
            inventory.items.append(item_id);
            world.write_model(@inventory);

            // Emit custom event
            world.emit_event(@ItemPickedUp { player, item_id });
        }
    }
}
```

### World API Operations
```cairo
// Reading models
let player_data: Player = world.read_model(player);
let resource: Resource = world.read_model((player, location)); // Multiple keys

// Writing models
world.write_model(@updated_model);

// Member access
let health: u32 = world.read_member(
    Model::<Player>::ptr_from_keys(player),
    selector!("health")
);

// Contract DNS lookup
if let Some((contract_address, class_hash)) = world.dns("other_system") {
    // Use contract_address for dispatcher
}
```

## Common Development Commands

### Build & Test Workflow
```bash
# Build contracts
sozo build

# Run tests
sozo test

# Deploy to local Katana
sozo migrate

# Start indexer (replace with actual world address)
torii --world <WORLD_ADDRESS> --http.cors_origins "*"
```

### Local Development Setup
```bash
# Terminal 1: Local blockchain
katana --dev --dev.no-fee

# Terminal 2: Build & deploy
cd contracts && sozo build && sozo migrate

# Terminal 3: Start indexer
torii --world <WORLD_ADDRESS> --http.cors_origins "*"
```

## Critical Error Prevention

### Common Cairo Mistakes
1. **Missing traits**: Always derive `Drop, Serde` for models
2. **Immutable world**: Use `let mut world = self.world(@"namespace")` for writes
3. **Unsafe conversions**: Use `try_into().unwrap()` not `into()`
4. **Array mutations**: Cannot modify array elements after creation
5. **Copy with Arrays**: Never use `Copy` trait with `Array` or `ByteArray`
6. **Key ordering**: All `#[key]` fields must come before non-key fields
7. **Wrong namespace**: Verify namespace matches profile configuration

### Debug Checklist
- [ ] Correct imports for ModelStorage/EventStorage
- [ ] Mutable world reference for writes
- [ ] Proper trait derivations
- [ ] Safe type conversions
- [ ] Correct namespace string
- [ ] Model keys before non-key fields

## Performance & Gas Optimization

### Model Design
- Keep models small and focused (ECS best practice)
- Use `IntrospectPacked` for fixed-size data
- Prefer primitive types over complex nested structures
- Use composite keys efficiently

### System Design
- Batch operations when possible
- Validate inputs early with descriptive assertions
- Use member reads/writes for single field updates
- Emit events for state changes clients need to track

## Comprehensive Dojo Testing Guide

This section provides detailed guidance for writing reliable tests in Dojo, based on real-world debugging and issue resolution.

### CRITICAL: Events vs Models Resource Registration

**The #1 cause of Dojo testing failures** is incorrect resource registration. You must register the exact resources your test needs:

```cairo
// ❌ WRONG - Mixed up resource types
TestResource::Model(e_GameCreated::TEST_CLASS_HASH),  // Event registered as Model
TestResource::Event(m_Player::TEST_CLASS_HASH),       // Model registered as Event

// ✅ CORRECT - Proper resource registration
TestResource::Model(m_Player::TEST_CLASS_HASH),       // Models use m_ prefix
TestResource::Event(e_GameCreated::TEST_CLASS_HASH),  // Events use e_ prefix
```

**When to Register Events vs Models:**

- **Register Events** (`TestResource::Event`) when testing event emission, logging, achievements
- **Register Models** (`TestResource::Model`) when testing persistent state, data storage
- **Always register the CONTRACT** that emits events or manages models

### Critical Testing Concepts

#### 1. Dojo Auto-Generated Types
Dojo automatically generates test-specific types for models and events:
- **Models**: `m_ModelName::TEST_CLASS_HASH` (e.g., `m_Player::TEST_CLASS_HASH`)
- **Events**: `e_EventName::TEST_CLASS_HASH` (e.g., `e_GameCreated::TEST_CLASS_HASH`)
- **Contracts**: `ContractName::TEST_CLASS_HASH` (e.g., `actions::TEST_CLASS_HASH`)

#### 2. Resource Registration Types
```cairo
// CORRECT resource registrations
TestResource::Model(m_Player::TEST_CLASS_HASH),      // For models
TestResource::Event(e_GameCreated::TEST_CLASS_HASH), // For events
TestResource::Contract(actions::TEST_CLASS_HASH),    // For contracts
```

**❌ WRONG**: Never register events as models or vice versa - this causes "Resource is registered but not as event" errors.

### Test Organization Best Practices

#### Centralized Setup Pattern (Recommended)

**CRITICAL**: Never duplicate test setup code. Use a centralized setup module that other tests import from.

```cairo
// src/tests/setup.cairo - Centralized test infrastructure
pub fn spawn() -> (WorldStorage, Systems, Context) {
    // Complete namespace definition with all resources
    // Contract permissions setup
    // System dispatcher creation
    // Test context with addresses
}

// Other test files - Use centralized setup
#[cfg(test)]
mod tests {
    use starknet::testing::set_contract_address;
    use dojo::world::WorldStorage;
    use dojo::model::{ModelStorage, ModelStorageTest};
    use elysium_descent::systems::actions::IActionsDispatcherTrait;

    // CORRECT: Use absolute Cairo imports, not Rust-style relative imports
    use elysium_descent::tests::setup::{
        spawn,
        Player, Game, GameCounter, LevelItems, PlayerInventory, WorldItem,
        Store, StoreTrait
    };

    #[test]
    fn test_basic_operations() {
        // One line setup - no duplication!
        let (world, systems, context) = spawn();

        // Test logic using centralized infrastructure
        set_contract_address(context.player1);
        let game_id = systems.actions.create_game();
        // ...
    }
}
```

#### Import Syntax Rules

**CRITICAL**: Cairo uses absolute paths, not Rust-style relative imports.

```cairo
// ❌ WRONG - Rust-style relative imports (compilation error)
use super::setup::{spawn, Systems, Context};
use crate::models::Player;

// ✅ CORRECT - Cairo absolute path imports
use elysium_descent::tests::setup::{spawn, Systems, Context};
use elysium_descent::models::index::Player;
```

#### Benefits of Centralized Setup

1. **No Code Duplication**: Setup logic exists in one place only
2. **Easy Maintenance**: Changes to namespace or resources need only one update
3. **Consistent Testing**: All tests use identical, tested infrastructure
4. **Clean Test Files**: Focus on test logic, not boilerplate setup
5. **Import Reduction**: Fewer imports needed in each test file

#### Test Organization Anti-Patterns

```cairo
// ❌ WRONG - Duplicating setup across test files
#[test]
fn test_something() {
    let namespace_def = NamespaceDef {
        namespace: "elysium_001",
        resources: [
            TestResource::Model(m_Player::TEST_CLASS_HASH),
            // 20+ lines of identical setup...
        ].span(),
    };
    let mut world = spawn_test_world([namespace_def].span());
    // More duplicated setup...
}

// ✅ CORRECT - Use centralized setup
#[test]
fn test_something() {
    let (world, systems, context) = spawn();
    // Focus on test logic
}
```

#### Import Pattern Rules
1. **Direct Model Imports**: Import the struct directly for usage (`Player`, `Game`, etc.)
2. **Test Hash Imports**: Import with prefixes for testing (`m_Player`, `e_GameCreated`, etc.)
3. **Separate Event Imports**: Events require separate import lines with `e_` prefix
4. **Contract Imports**: Import both the module and dispatcher trait
5. **Absolute Paths**: Always use full project paths, never relative imports

### Namespace Definition Template

#### Complete Namespace Setup
```cairo
fn setup_test_world() -> (WorldStorage, IActionsDispatcher) {
    let namespace_def = NamespaceDef {
        namespace: "elysium_001", // MUST match your profile namespace
        resources: [
            // Models - register all models your tests will use
            TestResource::Model(m_Player::TEST_CLASS_HASH),
            TestResource::Model(m_Game::TEST_CLASS_HASH),
            TestResource::Model(m_GameCounter::TEST_CLASS_HASH),
            TestResource::Model(m_LevelItems::TEST_CLASS_HASH),
            TestResource::Model(m_PlayerInventory::TEST_CLASS_HASH),
            TestResource::Model(m_WorldItem::TEST_CLASS_HASH),

            // Events - register all events your systems emit
            TestResource::Event(e_GameCreated::TEST_CLASS_HASH),
            TestResource::Event(e_LevelStarted::TEST_CLASS_HASH),
            TestResource::Event(e_ItemPickedUp::TEST_CLASS_HASH),

            // Contracts - register all contracts your tests call
            TestResource::Contract(actions::TEST_CLASS_HASH),
        ].span(),
    };

    let mut world = spawn_test_world([namespace_def].span());

    // Setup permissions for contract to write to namespace
    let contracts = [
        ContractDefTrait::new(@"elysium_001", @"actions")
            .with_writer_of([dojo::utils::bytearray_hash(@"elysium_001")].span())
    ].span();
    world.sync_perms_and_inits(contracts);

    // Get system dispatchers using DNS
    let (actions_address, _) = world.dns(@"actions").unwrap();
    let actions = IActionsDispatcher { contract_address: actions_address };

    (world, actions)
}
```

### Test Structure Patterns

#### 1. Basic Model Testing
```cairo
#[test]
fn test_basic_model_operations() {
    let namespace_def = NamespaceDef {
        namespace: "elysium_001",
        resources: [
            TestResource::Model(m_Player::TEST_CLASS_HASH),
            // Add other required models...
        ].span(),
    };

    let mut world = spawn_test_world([namespace_def].span());

    // Create test data
    let player_address = contract_address_const::<'PLAYER'>();
    let test_player = Player {
        player: player_address,
        health: 100,
        max_health: 100,
        level: 1,
        experience: 0,
        items_collected: 0,
    };

    // Test write and read operations
    world.write_model_test(@test_player);
    let read_player: Player = world.read_model(player_address);

    // Verify data integrity
    assert(read_player.player == player_address, 'Player address mismatch');
    assert(read_player.health == 100, 'Health mismatch');
    assert(read_player.level == 1, 'Level mismatch');
}
```

#### 2. System Integration Testing
```cairo
#[test]
fn test_system_interactions() {
    let (world, actions) = setup_test_world();

    // Set the calling contract address
    set_contract_address(contract_address_const::<'PLAYER'>());

    // Test system calls
    let game_id = actions.create_game();
    assert(game_id > 0, 'Game ID should be positive');

    // Verify state changes
    let game: Game = world.read_model(game_id);
    assert(game.player == contract_address_const::<'PLAYER'>(), 'Player mismatch');
}
```

### Common Testing Pitfalls and Solutions

#### 1. "Invalid path" Errors
**Problem**: `error: Invalid path. --> TestResource::Event(GameCreated::TEST_CLASS_HASH)`

**Cause**: Using direct event name instead of Dojo-generated `e_` prefix

**Solution**:
```cairo
// ❌ WRONG
TestResource::Event(GameCreated::TEST_CLASS_HASH)

// ✅ CORRECT
TestResource::Event(e_GameCreated::TEST_CLASS_HASH)
```

#### 2. "Resource registered but not as event" Errors
**Problem**: `Resource 'X' is registered but not as event`

**Cause**: Registering events as models in namespace definition

**Solution**:
```cairo
// ❌ WRONG
TestResource::Model(e_GameCreated::TEST_CLASS_HASH)

// ✅ CORRECT
TestResource::Event(e_GameCreated::TEST_CLASS_HASH)
```

#### 3. Import Structure Confusion
**Problem**: Cannot find `m_ModelName` or `e_EventName`

**Cause**: Incorrect import paths or missing auto-generated types

**Solution**:
```cairo
// ✅ CORRECT model imports
use elysium_descent::models::player::m_Player;        // For TEST_CLASS_HASH
use elysium_descent::models::player::Player;          // For actual usage

// ✅ CORRECT event imports
use elysium_descent::systems::actions::{e_GameCreated, e_LevelStarted};  // For TEST_CLASS_HASH
```

#### 4. Module Structure Issues
**Problem**: Using `mod.cairo` patterns from Rust

**Solution**: Use Cairo's `index.cairo` pattern:
```
models/
├── player.cairo
├── game.cairo
├── inventory.cairo
└── index.cairo    // Re-exports all models
```

**index.cairo content**:
```cairo
pub use super::player::Player;
pub use super::game::{Game, GameCounter, LevelItems};
pub use super::inventory::PlayerInventory;
```

### Advanced Testing Patterns

#### Event Testing
```cairo
#[test]
fn test_event_emission() {
    let (world, actions) = setup_test_world();

    // Clear existing events
    starknet::testing::pop_log_raw(world.dispatcher.contract_address);

    // Trigger event-emitting action
    set_contract_address(contract_address_const::<'PLAYER'>());
    let game_id = actions.create_game();

    // Capture and validate event
    let event = starknet::testing::pop_log_raw(world.dispatcher.contract_address).unwrap();
    // Validate event contents...
}
```

#### Multi-Player Testing
```cairo
#[test]
fn test_player_isolation() {
    let (world, actions) = setup_test_world();

    // Test with multiple players
    let player1 = contract_address_const::<'PLAYER1'>();
    let player2 = contract_address_const::<'PLAYER2'>();

    // Player 1 actions
    set_contract_address(player1);
    let game1_id = actions.create_game();

    // Player 2 actions
    set_contract_address(player2);
    let game2_id = actions.create_game();

    // Verify isolation
    assert(game1_id != game2_id, 'Games should be separate');

    let game1: Game = world.read_model(game1_id);
    let game2: Game = world.read_model(game2_id);
    assert(game1.player == player1, 'Game1 player mismatch');
    assert(game2.player == player2, 'Game2 player mismatch');
}
```

### Testing Checklist

Before writing tests, verify:
- [ ] All required models imported with `m_` prefix for TEST_CLASS_HASH
- [ ] All required events imported with `e_` prefix for TEST_CLASS_HASH
- [ ] Events registered as `TestResource::Event`, not `TestResource::Model`
- [ ] Namespace matches your profile configuration (`"elysium_001"`)
- [ ] Contract permissions set up with `sync_perms_and_inits`
- [ ] System dispatchers obtained via `world.dns()`
- [ ] Proper `set_contract_address()` calls for caller simulation

### Debugging Failed Tests

#### Step 1: Check Import Errors
```bash
# Look for "Invalid path" errors in build output
sozo build

# Common fixes:
# - Add missing m_ or e_ prefixes
# - Check import paths match actual file structure
# - Verify auto-generated types exist
```

#### Step 2: Check Resource Registration Errors
```bash
# Look for "Resource registered but not as X" errors
sozo test

# Common fixes:
# - Use TestResource::Event for events
# - Use TestResource::Model for models
# - Use TestResource::Contract for contracts
```

#### Step 3: Verify Namespace Configuration
```bash
# Check that namespace in tests matches profile
grep -r "elysium_001" src/tests/
grep -r "elysium_001" Scarb.toml

# Ensure consistency across all files
```

### Advanced Setup Module Pattern

For complex projects, use a structured setup module:

```cairo
// src/tests/setup.cairo
#[derive(Copy, Drop)]
pub struct Systems {
    pub actions: IActionsDispatcher,
    pub player_system: IPlayerSystemDispatcher,
    pub game_system: IGameSystemDispatcher,
}

#[derive(Copy, Drop)]
pub struct Context {
    pub player1: ContractAddress,
    pub player2: ContractAddress,
    pub admin: ContractAddress,
    pub test_game_id: u32,
}

pub fn spawn() -> (WorldStorage, Systems, Context) {
    set_contract_address(OWNER());
    let namespace_def = setup_namespace();
    let world = spawn_test_world([namespace_def].span());
    world.sync_perms_and_inits(setup_contracts());

    // Get all system dispatchers
    let (actions_address, _) = world.dns(@"actions").unwrap();
    let (player_address, _) = world.dns(@"player_system").unwrap();
    let (game_address, _) = world.dns(@"game_system").unwrap();

    let systems = Systems {
        actions: IActionsDispatcher { contract_address: actions_address },
        player_system: IPlayerSystemDispatcher { contract_address: player_address },
        game_system: IGameSystemDispatcher { contract_address: game_address },
    };

    let context = Context {
        player1: PLAYER1(),
        player2: PLAYER2(),
        admin: ADMIN(),
        test_game_id: 1,
    };

    (world, systems, context)
}

// Utility to clear events for clean testing
pub fn clear_events(address: ContractAddress) {
    loop {
        match starknet::testing::pop_log_raw(address) {
            core::option::Option::Some(_) => {},
            core::option::Option::None => { break; },
        };
    }
}
```

### Performance Considerations

#### Gas Optimization Strategy
```cairo
// Progressive gas limits - start low and increase as needed
#[test]
#[available_gas(3000000)]    // Start with 3M for basic tests
fn test_simple_operations() { /* ... */ }

#[test]
#[available_gas(6000000)]    // 6M for complex operations
fn test_comprehensive_workflow() { /* ... */ }

#[test]
#[available_gas(10000000)]   // 10M for heavy computation
fn test_level_progression_mechanics() { /* ... */ }

#[test]
#[available_gas(30000000)]   // 30M for integration tests
fn test_full_game_workflow() { /* ... */ }
```

#### Batch Testing Strategy
```cairo
// Group related tests to reuse world setup
#[test]
fn test_complete_game_workflow() {
    let (world, actions) = setup_test_world();

    // Test 1: Game creation
    // Test 2: Player joining
    // Test 3: Game actions
    // Test 4: Game completion
    // All in one test to avoid repeated world setup
}
```

### Critical Production Issues to Avoid

#### 1. Poseidon Hash Overflow (CRITICAL)
```cairo
// ❌ WRONG - Causes "Option::unwrap failed"
fn generate_id(game_id: u32, level: u32, counter: u32) -> u32 {
    let hash = poseidon_hash_span(array![game_id.into(), level.into(), counter.into()].span());
    hash.try_into().unwrap() // FAILS - hash too large for u32
}

// ✅ CORRECT - Always use modulo constraint
fn generate_id(game_id: u32, level: u32, counter: u32) -> u32 {
    let hash = poseidon_hash_span(array![game_id.into(), level.into(), counter.into()].span());
    let hash_u256: u256 = hash.into();
    (hash_u256 % 0x100000000_u256).try_into().unwrap() // Constrain to u32 range
}
```

**CRITICAL**: This is the #1 cause of mysterious test failures. Poseidon returns felt252 values that are often too large for u32/u64. Always constrain with modulo.

#### 2. Cairo Error Handling Patterns
```cairo
// ❌ WRONG - Cairo functions panic, don't return false
fn test_invalid_pickup() {
    let result = actions.pickup_item(game_id, invalid_id);
    assert(!result, 'Should return false'); // This will PANIC instead
}

// ✅ CORRECT - Use should_panic for expected failures
#[test]
#[should_panic(expected: ('Item does not exist', 'ENTRYPOINT_FAILED'))]
fn test_invalid_pickup() {
    actions.pickup_item(game_id, invalid_id); // Will panic as expected
}
```

**Key Pattern**: Cairo uses panic-based error handling with `assert()` - functions either succeed or panic, they rarely return boolean failure states.

### Critical Lessons Learned

#### Test Organization
- **NEVER duplicate setup code** across test files - use centralized `setup.cairo` module
- **Use absolute imports**: `use elysium_descent::tests::setup::{spawn}` not `use super::setup::{spawn}`
- **One line setup**: `let (world, systems, context) = spawn();` eliminates 40+ lines of boilerplate

#### Cairo vs Rust Syntax
- **Imports**: Cairo uses absolute paths only, never `super::`, `crate::`, or `self::`
- **Module system**: Different from Rust - use project name as root, not `crate`

#### 3. Type Conversion Safety
```cairo
// ❌ WRONG - Unsafe conversions can fail
let small_val: u32 = large_val.into();

// ✅ CORRECT - Always use try_into with proper constraints
let small_val: u32 = (large_val % MAX_U32).try_into().unwrap();
```

### Production-Ready Test Checklist

Before deploying, ensure your tests cover:

- [ ] **Basic Model Operations**: Create, read, update patterns work
- [ ] **System Integration**: Complete workflows from start to finish
- [ ] **Error Conditions**: Use `#[should_panic]` for expected failures
- [ ] **Multi-Player Scenarios**: Isolation and concurrent access patterns
- [ ] **Edge Cases**: Boundary values, maximum limits, zero values
- [ ] **Gas Optimization**: All tests run within reasonable gas limits
- [ ] **Event Emission**: Critical state changes emit proper events
- [ ] **Security Validation**: Authorization, ownership, input validation

### Systematic Debugging Approach

When tests fail, follow this approach:

1. **Isolate the Issue**: Create minimal tests that reproduce the exact failure
2. **Check Type Conversions**: Look for poseidon hash overflow issues (most common)
3. **Verify Error Patterns**: Understand whether functions panic or return error values
4. **Increment Gas Gradually**: Start at 3M, increase to 6M, 10M, 30M as needed
5. **Test One Component**: Isolate failing functionality to specific components

**Key Insight**: The most critical testing issues in Dojo stem from:
1. **Type overflow in poseidon hashing** - Always use modulo constraints
2. **Misunderstanding Cairo error patterns** - Functions panic, they don't return false
3. **Insufficient gas limits** - Complex tests need 6-30M gas
4. **Incorrect resource registration** - Events vs Models must be registered correctly

## Common Compilation Issues and Resolutions

This section covers systematic approaches to resolving compilation errors encountered during test development and maintenance.

### Felt252 Overflow Errors

**Problem**: Error messages that are too long for felt252 capacity cause compilation failures.

```cairo
// ❌ WRONG - Message too long, causes felt252 overflow
assert(result == false, 'Should return false for non-existent item');

// ✅ CORRECT - Shortened message within felt252 limits
assert(result == false, 'Should return false');
```

**Resolution Strategy**:
1. **Keep messages under 31 characters** for single felt252
2. **Use abbreviations**: `'expected'` instead of `'should be emitted'`
3. **Remove articles**: `'event expected'` instead of `'event should be emitted'`
4. **Use consistent terminology**: `'wrong'` instead of descriptive phrases

### Private Member Access Errors

**Problem**: Attempting to access private fields of structs in tests.

```cairo
// ❌ WRONG - Cannot access private world field
assert(store.world.dispatcher.contract_address != contract_address_const::<0>(), 'Store should have valid world');

// ✅ CORRECT - Use public methods or test functionality directly
let test_counter = store.get_game_counter();
assert(test_counter.counter_id == 999999999, 'Store should work');
```

**Resolution Principles**:
1. **Use public APIs**: Test through public methods, not internal implementation
2. **Test behavior, not structure**: Verify functionality rather than internal state
3. **Create functional tests**: Test that operations work correctly

### Unused Import Warnings

**Problem**: Imports that aren't directly used in test code generate warnings.

```cairo
// ❌ PROBLEMATIC - Unused imports cause warnings
use dojo::world::WorldStorage;               // Used only in type annotations
use elysium_descent::systems::actions::{GameCreated, LevelStarted, ItemPickedUp}; // Events not directly used

// ✅ CORRECT - Minimal, necessary imports
use dojo::model::ModelStorageTest;           // Actually used for write_model_test
use elysium_descent::tests::setup::{         // Only import what's used
    spawn, Player, Game, LevelItems, PlayerInventory, WorldItem,
    clear_events, get_test_timestamp,
};
```

**Resolution Strategy**:
1. **Import only what's used**: Remove imports that don't have explicit usage
2. **Use type annotations**: `let store: Store = StoreTrait::new(world);` to make usage explicit
3. **Consolidate imports**: Group related imports and remove unused ones
4. **Prefer functional testing**: Test through public APIs rather than importing internal types

### Test Module Organization

**Problem**: Inconsistent test module structure and import patterns.

```cairo
// ❌ PROBLEMATIC - Inconsistent module pattern
#[cfg(test)]
mod events_tests {
    use starknet::testing::{set_contract_address, pop_log_raw};
    use dojo::world::WorldStorage;  // Unused
    use dojo::model::{ModelStorage, ModelStorageTest};  // ModelStorage unused

    use elysium_descent::systems::actions::{GameCreated, LevelStarted, ItemPickedUp}; // Unused events
    use elysium_descent::tests::setup::{
        spawn, Player, Game, GameCounter, LevelItems, PlayerInventory, WorldItem, PLAYER1, PLAYER2, // Unused PLAYER1, PLAYER2
        clear_events, get_test_timestamp,
    };
}

// ✅ CORRECT - Clean, focused imports
#[cfg(test)]
mod events_tests {
    use starknet::testing::{set_contract_address, pop_log_raw};
    use dojo::model::ModelStorageTest;
    use elysium_descent::systems::actions::IActionsDispatcherTrait;

    use elysium_descent::tests::setup::{
        spawn, Player, Game, LevelItems, PlayerInventory, WorldItem,
        clear_events, get_test_timestamp,
    };
    use elysium_descent::helpers::store::{Store, StoreTrait};
    use elysium_descent::types::item::ItemType;
}
```

**Best Practices**:
1. **Feature-based organization**: Group tests by functionality (events, inventory, errors)
2. **Consistent import patterns**: Use same import structure across test files
3. **Centralized setup**: Always use `spawn()` from centralized setup module
4. **Minimal imports**: Only import what's actually used in the test file

### #[should_panic] Test Patterns

**Problem**: Incorrect usage of panic expectation in tests.

```cairo
// ❌ WRONG - Expecting specific panic messages with wrong syntax
#[should_panic(expected: ('Inventory full'))]  // Wrong syntax

// ❌ WRONG - Expecting panics when functions return gracefully
#[test]
#[should_panic]
fn test_pickup_nonexistent_item() {
    let result = actions.pickup_item(game_id, 999);  // Actually returns false
}

// ✅ CORRECT - Proper panic syntax
#[test]
#[should_panic(expected: "Inventory full")]     // String literal
fn test_inventory_full() { /* ... */ }

// ✅ CORRECT - Test graceful behavior instead of expecting panics
#[test]
fn test_pickup_nonexistent_item_graceful() {
    let result = actions.pickup_item(game_id, 999);
    assert(result == false, 'Should return false');
}
```

**Resolution Guidelines**:
1. **Use string literals**: `"message"` not `('message')`
2. **Test actual behavior**: If functions return gracefully, test the return values
3. **Simplify expectations**: Use `#[should_panic]` without specific messages if message format is inconsistent
4. **Understand system design**: Some systems handle errors gracefully rather than panicking

### Compilation Error Debugging Workflow

When encountering compilation errors:

1. **Identify Error Category**:
   - Felt252 overflow → Shorten error messages
   - Private member access → Use public APIs
   - Unused imports → Remove or use explicitly
   - Wrong panic syntax → Fix #[should_panic] format

2. **Apply Systematic Fixes**:
   - Fix import structure first
   - Then resolve syntax errors
   - Finally adjust test expectations

3. **Verify Fixes**:
   - Run `sozo test` after each category of fixes
   - Ensure all compilation errors are resolved before addressing test failures

4. **Document Patterns**:
   - Update team practices based on common issues
   - Add examples to prevent future occurrences

## Import Hygiene and Type Usage Best Practices

This section covers practical patterns for avoiding unused import warnings and properly using imported types in Cairo/Dojo projects.

### Unused Import Prevention Strategies

**Problem**: Cairo compiler warns about unused imports, but removing them breaks type safety and explicit usage.

**Solution**: Create helper functions and comprehensive tests that explicitly use all imported types.

#### 1. Modern Store Pattern (Recommended)

```cairo
// Use the existing Store pattern instead of repetitive helper functions
use elysium_descent::helpers::store::{Store, StoreTrait};

// In tests - use Store for clean, organized model access
#[test]
fn test_with_modern_store_pattern() {
    let (world, actions) = setup_test_world();
    let store: Store = StoreTrait::new(world);  // Explicit type annotation uses Store import

    // Clean, semantic model operations - Store uses ModelStorage internally
    let player = store.get_player(PLAYER());
    let game = store.get_game(game_id);
    let inventory = store.get_player_inventory(PLAYER());

    // Store methods are cleaner than repetitive helpers
    assert(player.health > 0, 'Player should be alive');
    assert(game.status == GameStatus::InProgress, 'Game should be active');
}
```

#### 2. Direct ModelStorage Usage (For Edge Cases)

```cairo
// Only for models/operations not covered by Store
use dojo::model::ModelStorage;

// Direct usage when Store doesn't have specific methods
fn direct_model_access(world: WorldStorage, player: ContractAddress) -> Player {
    world.read_model(player)  // Explicit ModelStorage usage
}
```

#### 3. WorldStorage Usage Patterns

```cairo
// Helper that explicitly uses WorldStorage type
fn verify_world_storage_works(world: WorldStorage) {
    assert(world.dispatcher.contract_address != contract_address_const::<0>(), 'World should have address');
}

// Use in tests
#[test]
fn test_basic_system_dispatch() {
    let (world, actions) = setup_test_world();
    // ... test logic ...
    verify_world_storage_works(world); // Explicitly use WorldStorage
}
```

#### 4. ContractAddress Safe Usage Patterns

```cairo
use starknet::{ContractAddress, contract_address_const};

// ✅ CORRECT - Safe comparison pattern
fn is_valid_address(addr: ContractAddress) -> bool {
    addr != contract_address_const::<0>()
}

// ❌ WRONG - Method doesn't exist in Cairo
// addr.is_non_zero()  // Compilation error

// Helper functions using ContractAddress explicitly
impl WorldItemImpl of WorldItemTrait {
    fn can_be_collected_by(self: @WorldItem, player: ContractAddress) -> bool {
        !*self.is_collected && player != contract_address_const::<0>()
    }
}
```

#### 5. Comprehensive Model Testing Pattern

```cairo
#[test]
fn test_all_imported_model_types() {
    let mut world = spawn_test_world([namespace_def].span());
    let player_address = PLAYER();

    // Test Player model (uses imported Player type)
    let test_player = Player {
        player: player_address,
        health: 100,
        max_health: 100,
        level: 1,
        experience: 0,
        items_collected: 0,
    };
    world.write_model_test(@test_player);
    let read_player: Player = world.read_model(player_address);
    assert(read_player.health == 100, 'Player health mismatch');

    // Test GameCounter model (uses imported GameCounter type)
    let test_counter = GameCounter {
        counter_id: 999999999,
        next_game_id: 1,
    };
    world.write_model_test(@test_counter);
    let read_counter: GameCounter = world.read_model(test_counter.counter_id);
    assert(read_counter.next_game_id == 1, 'Counter mismatch');

    // Test LevelItems model (uses imported LevelItems type)
    let test_level_items = LevelItems {
        game_id: 1,
        level: 1,
        total_health_potions: 10,
        total_survival_kits: 5,
        total_books: 3,
        collected_health_potions: 0,
        collected_survival_kits: 0,
        collected_books: 0,
    };
    world.write_model_test(@test_level_items);
    let read_level_items: LevelItems = world.read_model((1_u32, 1_u32));
    assert(read_level_items.total_health_potions == 10, 'Level items mismatch');

    // Continue for all imported model types...
}
```

#### 6. Type-Safe Import Organization

```cairo
// Organize imports by usage category
#[cfg(test)]
mod tests {
    // Core Dojo testing framework
    use dojo::world::{WorldStorage, WorldStorageTrait};          // Used in helper functions
    use dojo::model::{ModelStorage, ModelStorageTest};           // Used for read/write operations

    // Direct model imports for struct creation
    use elysium_descent::models::index::{
        Player, Game, GameCounter, LevelItems, PlayerInventory, WorldItem  // ALL used in tests
    };

    // Test class hash imports for resource registration
    use elysium_descent::models::player::m_Player;               // Used in TestResource::Model
    use elysium_descent::models::game::{m_Game, m_LevelItems};   // Used in TestResource::Model
    // ... etc for all model types

    // Type imports for explicit usage
    use elysium_descent::types::item_types::ItemType;           // Used in WorldItem creation
}
```

#### 7. ContractDef Usage Pattern

```cairo
use dojo_cairo_test::ContractDef;

// Helper function that explicitly uses ContractDef type
fn setup_contract_definitions() -> Span<ContractDef> {
    [
        ContractDefTrait::new(@"elysium_001", @"actions")
            .with_writer_of([dojo::utils::bytearray_hash(@"elysium_001")].span())
    ].span()
}

// Use in test setup
let contracts = setup_contract_definitions();
world.sync_perms_and_inits(contracts);
```

### Import Hygiene Checklist

Before finalizing tests, verify:

- [ ] **All model imports are used** in struct creation or helper functions
- [ ] **All type imports are used** in function parameters or struct fields
- [ ] **ModelStorage is used** in explicit helper functions
- [ ] **WorldStorage is used** in type annotations or helper functions
- [ ] **ContractDef is used** in helper functions for setup
- [ ] **ContractAddress patterns** use safe comparison methods
- [ ] **Test class hashes** match their resource registration types

### Benefits of Proper Import Usage

1. **Type Safety**: Explicit usage ensures types are actually needed
2. **Code Documentation**: Helper functions document intended usage patterns
3. **Test Coverage**: Comprehensive model testing improves validation
4. **Maintenance**: Clear type usage makes refactoring safer
5. **Compiler Happiness**: No unused import warnings

---

**Remember**: When in doubt, check both the existing working tests in `src/tests/test_simple.cairo` and the comprehensive testing guide in `AI_DOCS/comprehensive-testing-in-dojo.md` for reference patterns!

## Current Test Suite Organization

The project now follows a feature-based test organization with 98 comprehensive tests across multiple modules:

### Test Module Structure

```
contracts/src/tests/
├── setup.cairo              # Centralized test infrastructure (spawn, context, helpers)
├── simple.cairo             # Basic model and system operation tests
├── world.cairo              # World setup and integration tests
├── comprehensive.cairo      # Legacy comprehensive test suite
├── test_game_features.cairo # Game lifecycle and level progression (12 tests)
├── test_inventory_features.cairo # Item management and player inventory (10 tests)
├── test_component_layer.cairo     # Direct component testing (7 tests)
├── test_error_conditions.cairo   # Error handling and edge cases (20 tests)
├── test_performance.cairo         # Gas optimization and performance (15 tests)
├── test_helpers.cairo            # Store pattern and utility testing (13 tests)
└── test_events.cairo            # Event emission verification (11 tests)
```

### Test Coverage Areas

**Core Game Systems (98 tests total)**:
- **Game Features** (12 tests): Creation, level progression, ownership, multi-player isolation
- **Inventory Management** (10 tests): Item pickup, capacity limits, type differentiation, experience tracking
- **Component Layer** (7 tests): Direct business logic testing, integration workflows
- **Error Conditions** (20 tests): Validation rules, security, graceful error handling
- **Performance** (15 tests): Gas usage patterns, optimization, stress testing
- **Helper Functions** (13 tests): Store pattern validation, data consistency, edge cases
- **Event System** (11 tests): Event emission, isolation, workflow sequences
- **Legacy Tests** (10 tests): World setup, basic operations, comprehensive workflows

### Key Testing Patterns

**1. Centralized Setup**:
```cairo
// Every test file uses the same pattern
use elysium_descent::tests::setup::{spawn, Player, Game, LevelItems, /*...*/};

#[test]
fn test_feature() {
    let (world, systems, context) = spawn(); // One-line setup
    // Test logic here
}
```

**2. Feature-Based Organization**:
- Tests grouped by functionality, not by system layer
- Clear separation between happy path, error conditions, and performance
- Consistent naming conventions: `test_[feature]_[behavior]`

**3. Progressive Gas Limits**:
- Basic operations: 3-6M gas
- Complex workflows: 10-30M gas
- Integration tests: 30-60M gas
- Performance stress tests: 100M+ gas

**4. Error Testing Strategy**:
- Use `#[should_panic]` for expected failures
- Test graceful handling for edge cases
- Verify default return values for non-existent data

**5. Import Hygiene**:
- Minimal, focused imports per test module
- Consistent import structure across files
- Use of Store pattern for clean model access

### Test Maintenance Guidelines

**Adding New Tests**:
1. **Choose appropriate module** based on functionality being tested
2. **Use centralized setup**: Always call `spawn()` for world initialization
3. **Follow gas limit patterns**: Start with 30M gas, adjust as needed
4. **Import minimally**: Only import types actually used in tests
5. **Use consistent patterns**: Follow existing test structure and naming

**Fixing Test Issues**:
1. **Check compilation first**: Resolve import and syntax errors before logic
2. **Verify gas limits**: Increase if tests are running out of gas
3. **Check error expectations**: Ensure `#[should_panic]` matches actual behavior
4. **Test actual behavior**: Don't assume functions panic; they might return gracefully

**Performance Considerations**:
- Group related tests to reuse world setup
- Use appropriate gas limits (avoid over-allocation)
- Test edge cases and boundary conditions
- Validate both success and failure paths

## Cairo Documentation and Commenting Best Practices

### Proper Comment Syntax

**CRITICAL**: Cairo has strict commenting syntax that affects compilation. Follow these patterns exactly:

#### Documentation Comments
```cairo
/// Item-level documentation for structs, enums, functions, and traits
/// Use triple slashes for comprehensive descriptions
#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub enum GameMode {
    /// Individual variant documentation
    Tutorial,
    /// Each variant on its own line
    Standard,
    /// Never use inline comments on enum variants
    Hardcore,
}

/// Function documentation with structured sections
///
/// # Arguments
/// * `base_exp` - Base experience amount before bonuses
/// * `player_class` - Player's class affecting experience gain
///
/// # Returns
/// Modified experience amount after applying class multiplier
fn calculate_experience(base_exp: u32, player_class: PlayerClass) -> u32 {
    // Regular inline comments within function bodies
    let multiplier = player_class.get_experience_multiplier();
    base_exp * multiplier / 100
}
```

#### Module Documentation
```cairo
//! Module-level documentation using `//!`
//! Describes the entire module's purpose and usage
```

### Common Syntax Errors to Avoid

#### ❌ WRONG - Inline Comments on Enum Variants
```cairo
#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub enum GameMode {
    Tutorial, // This will cause compilation errors
    Standard, // Never use inline comments here
    Hardcore  // Even without trailing comma
}
```

#### ❌ WRONG - Inline Comments on Struct Fields
```cairo
pub struct GameConfig {
    pub mode: GameMode, // Compilation error
    pub difficulty: Difficulty, // Don't do this
}
```

#### ✅ CORRECT - Separate Line Documentation
```cairo
/// Game configuration with mode-specific parameters
#[derive(Clone, Drop, Serde, Introspect)]
pub struct GameConfig {
    pub mode: GameMode,
    pub difficulty: Difficulty,
    /// Percentage multiplier where 100 = normal, 200 = double items
    pub item_spawn_multiplier: u32,
}
```

### Comment Quality Guidelines

#### Replace Vague Comments
```cairo
// ❌ WRONG - Vague and unhelpful
// Use store method
// Get the item
// Check if completed

// ✅ CORRECT - Specific and actionable
// Delegate game creation to the Store layer following Shinigami pattern
// Retrieve the world item to be collected
// Verify all level items have been successfully collected
```

#### Function Documentation Template
```cairo
/// Brief function description
///
/// Longer description if needed explaining complex behavior,
/// algorithm details, or important constraints.
///
/// # Arguments
/// * `param1` - Description of first parameter
/// * `param2` - Description of second parameter
///
/// # Returns
/// Description of return value and its meaning
///
/// # Panics
/// Conditions that will cause the function to panic
///
/// # Examples
/// ```
/// let result = my_function(value1, value2);
/// assert(result > 0, 'Should be positive');
/// ```
fn my_function(param1: u32, param2: ContractAddress) -> u32 {
    // Implementation with inline comments for complex logic
    assert(param1 > 0, 'Parameter must be positive');
    param1 * 2
}
```

### Documentation Maintenance Checklist

When writing or updating comments:

- [ ] Use `///` for item-level documentation (structs, enums, functions)
- [ ] Use `//` for inline comments within function bodies
- [ ] Never put inline comments on enum variants or struct fields
- [ ] Place comments on separate lines above the code they describe
- [ ] Write specific, actionable descriptions instead of vague statements
- [ ] Include parameter and return value documentation for public functions
- [ ] Document panic conditions with `# Panics` sections
- [ ] Provide examples for complex functions
- [ ] Use consistent terminology throughout the codebase

## Essential Documentation References

- [Cairo Comments Guide](https://book.cairo-lang.org/ch02-04-comments.html) - Official Cairo commenting syntax
- [Dojo Models](https://www.dojoengine.org/framework/models) - Model structure and best practices
- [Dojo Systems](https://www.dojoengine.org/framework/world/systems) - System implementation patterns
- [World API](https://www.dojoengine.org/framework/world/api) - Complete API reference
- [Testing](https://www.dojoengine.org/framework/testing) - Testing framework and patterns
- [Cairo Language](https://book.cairo-lang.org/) - Core language reference

---

**Remember**: Always verify your namespace in profile configs matches `self.world(@"elysium_001")` calls!
