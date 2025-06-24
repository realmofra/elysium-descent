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

### Essential Test Imports

#### Required Core Imports
```cairo
#[cfg(test)]
mod tests {
    // Starknet testing utilities
    use starknet::{ContractAddress, contract_address_const, testing::set_contract_address};
    
    // Dojo core testing framework
    use dojo::world::{WorldStorage, WorldStorageTrait};
    use dojo::model::{ModelStorage, ModelStorageTest};
    use dojo_cairo_test::{
        spawn_test_world, NamespaceDef, TestResource, ContractDefTrait, WorldStorageTestTrait
    };
    
    // Your project imports - Models (direct)
    use elysium_descent::models::index::{Player, Game, GameCounter, LevelItems, PlayerInventory, WorldItem};
    
    // Your project imports - Model TEST_CLASS_HASH (with m_ prefix)
    use elysium_descent::models::player::m_Player;
    use elysium_descent::models::game::{m_Game, m_GameCounter, m_LevelItems};
    use elysium_descent::models::inventory::m_PlayerInventory;
    use elysium_descent::models::world_state::m_WorldItem;
    
    // Your project imports - Systems
    use elysium_descent::systems::actions::{actions, IActionsDispatcher, IActionsDispatcherTrait};
    
    // Your project imports - Events (with e_ prefix)
    use elysium_descent::systems::actions::{e_GameCreated, e_LevelStarted, e_ItemPickedUp};
}
```

#### Import Pattern Rules
1. **Direct Model Imports**: Import the struct directly for usage (`Player`, `Game`, etc.)
2. **Test Hash Imports**: Import with prefixes for testing (`m_Player`, `e_GameCreated`, etc.)
3. **Separate Event Imports**: Events require separate import lines with `e_` prefix
4. **Contract Imports**: Import both the module and dispatcher trait

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

### Performance Considerations

#### Gas Optimization for Tests
```cairo
// Gas limits based on test complexity
#[test]
#[available_gas(30000000)]   // Basic tests - 30M
fn test_simple_operations() { /* ... */ }

#[test]
#[available_gas(60000000)]   // Complex tests - 60M  
fn test_comprehensive_workflow() { /* ... */ }

#[test]
#[available_gas(100000000)]  // Heavy computation - 100M
fn test_level_progression_mechanics() { /* ... */ }
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

#### 3. Type Conversion Safety
```cairo
// ❌ WRONG - Unsafe conversions can fail
let small_val: u32 = large_val.into();

// ✅ CORRECT - Always use try_into with proper constraints
let small_val: u32 = (large_val % MAX_U32).try_into().unwrap();
```

---

**Remember**: When in doubt, check the existing working tests in `src/tests/test_simple.cairo` for reference patterns!

## Essential Documentation References

- [Dojo Models](https://www.dojoengine.org/framework/models) - Model structure and best practices
- [Dojo Systems](https://www.dojoengine.org/framework/world/systems) - System implementation patterns  
- [World API](https://www.dojoengine.org/framework/world/api) - Complete API reference
- [Testing](https://www.dojoengine.org/framework/testing) - Testing framework and patterns
- [Cairo Language](https://book.cairo-lang.org/) - Core language reference

---

**Remember**: Always verify your namespace in profile configs matches `self.world(@"elysium_001")` calls!