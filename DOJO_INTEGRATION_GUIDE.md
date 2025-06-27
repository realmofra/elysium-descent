# Dojo Integration Guide - Elysium Descent

## Overview

This guide provides comprehensive documentation for the Dojo blockchain integration in Elysium Descent, covering the recent updates to support the current contract interface and streamlined development workflow.

## Recent Updates (Latest)

### ✅ Contract Interface Alignment
- **Updated `pickup_item`**: Now requires `game_id` and `item_id` parameters
- **Enhanced `create_game`**: Improved game ID handling and data parsing
- **Blockchain Item Mapping**: Added `BlockchainItemId` component for proper item tracking
- **Error Handling**: Graceful fallbacks and comprehensive logging

### ✅ YarnSpinner Removal
- **Streamlined Dependencies**: Removed dialogue system for cleaner development
- **Direct Book Collection**: Books now collect immediately without dialogue interruption
- **Reduced Complexity**: Eliminated dialogue-related events and systems
- **Preserved Assets**: Dialogue assets kept for potential future re-integration

## Architecture Overview

### Client-Blockchain Communication Flow

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Bevy Client   │    │ Dojo Framework  │    │ Cairo Contracts │
│                 │    │                 │    │                 │
│  ┌───────────┐  │    │  ┌───────────┐  │    │  ┌───────────┐  │
│  │Collectible│  │───►│  │ DojoBevy  │  │───►│  │  Actions  │  │
│  │ Systems   │  │    │  │  Plugin   │  │    │  │  System   │  │
│  └───────────┘  │    │  └───────────┘  │    │  └───────────┘  │
│                 │    │       │         │    │       │         │
│  ┌───────────┐  │    │  ┌───────────┐  │    │  ┌───────────┐  │
│  │   Game    │  │◄───│  │   Torii   │  │◄───│  │  Events   │  │
│  │   State   │  │    │  │ Indexer   │  │    │  │& Models   │  │
│  └───────────┘  │    │  └───────────┘  │    │  └───────────┘  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Contract Interface Documentation

### Actions System Interface

The main contract interface provides these functions:

```cairo
#[starknet::interface]
pub trait IActions<T> {
    fn create_game(ref self: T) -> u32;
    fn start_level(ref self: T, game_id: u32, level: u32);
    fn pickup_item(ref self: T, game_id: u32, item_id: u32) -> bool;
    fn get_player_stats(self: @T, player: ContractAddress) -> Player;
    fn get_player_inventory(self: @T, player: ContractAddress) -> PlayerInventory;
    fn get_level_items(self: @T, game_id: u32, level: u32) -> LevelItems;
}
```

### Function Details

#### `create_game() -> u32`
**Purpose**: Creates a new game instance for the calling player
**Parameters**: None (uses caller address automatically)
**Returns**: Unique game ID

**Implementation Flow**:
1. Gets caller address via `get_caller_address()`
2. Generates unique game ID using counter
3. Initializes player stats (health: 100, level: 1)
4. Creates empty inventory (capacity: 50)
5. Emits `GameCreated` event

**Client Integration**:
```rust
// Trigger game creation
create_game_events.send(CreateGameEvent);

// System handles the blockchain call
let call = Call {
    to: action_address,
    selector: CREATE_GAME_SELECTOR,
    calldata: vec![], // No parameters needed
};
dojo.queue_tx(&tokio, vec![call]);
```

#### `pickup_item(game_id: u32, item_id: u32) -> bool`
**Purpose**: Collects an item for the specified game
**Parameters**: 
- `game_id`: The game instance ID
- `item_id`: The specific item to collect
**Returns**: Success status

**Implementation Flow**:
1. Validates caller owns the game
2. Verifies item exists and isn't collected
3. Checks inventory capacity
4. Updates inventory based on item type
5. Awards experience points (10 XP)
6. Handles level progression (100 XP per level)
7. Emits `ItemPickedUp` event

**Client Integration**:
```rust
// Trigger item pickup with proper parameters
pickup_events.send(PickupItemEvent {
    item_type: CollectibleType::FirstAidKit,
    item_entity: entity,
    item_id: blockchain_item_id, // NEW: Required parameter
});

// System calls blockchain with game_id and item_id
let call = Call {
    to: action_address,
    selector: PICKUP_ITEM_SELECTOR,
    calldata: vec![
        Felt::from(game_id),    // Game instance
        Felt::from(item_id),    // Specific item
    ],
};
```

## Client-Side Implementation

### Dojo System Architecture

#### System Organization
```
src/systems/dojo/
├── mod.rs                  # Main plugin and state management
├── create_game.rs         # Game creation and data parsing
└── pickup_item.rs         # Item collection with blockchain
```

#### Core Components

##### DojoSystemState Resource
```rust
#[derive(Resource, Debug, Default)]
pub struct DojoSystemState {
    pub torii_connected: bool,
    pub account_connected: bool,
    pub last_error: Option<String>,
    pub config: DojoConfig,
}
```

##### Game State Tracking
```rust
#[derive(Resource, Debug, Default)]
pub struct GameState {
    pub current_game_id: Option<u32>,  // Tracks active game
    pub is_creating_game: bool,
    pub player_address: Option<String>,
    pub subscribed_to_entities: bool,
}
```

##### Blockchain Item Mapping
```rust
#[derive(Component, Debug, Clone)]
pub struct BlockchainItemId {
    pub item_id: u32,    // Blockchain item identifier
    pub game_id: u32,    // Associated game instance
}
```

### Event System

#### Game Creation Events
```rust
#[derive(Event, Debug)]
pub struct CreateGameEvent;

#[derive(Event, Debug)]
pub struct GameCreatedEvent {
    pub game_id: u32,
    pub player_address: String,
}

#[derive(Event, Debug)]
pub struct GameCreationFailedEvent {
    pub error: String,
}
```

#### Item Collection Events
```rust
#[derive(Event, Debug)]
pub struct PickupItemEvent {
    pub item_type: CollectibleType,
    pub item_entity: Entity,        // Client entity
    pub item_id: u32,              // Blockchain item ID
}

#[derive(Event, Debug)]
pub struct ItemPickedUpEvent {
    pub item_type: CollectibleType,
    pub item_entity: Entity,
    pub item_id: u32,
    pub transaction_hash: String,
}
```

### Item ID Management System

#### Blockchain Item Generation
Items are generated on the blockchain when levels start:

```cairo
fn generate_item_id(game_id: u32, level: u32, item_counter: u32) -> u32 {
    let hash = poseidon_hash_span(
        array![game_id.into(), level.into(), item_counter.into()].span(),
    );
    let hash_u256: u256 = hash.into();
    (hash_u256 % 0x100000000_u256).try_into().unwrap()
}
```

#### Client-Side Mapping
```rust
// Configuration for spawning collectibles with blockchain IDs
#[derive(Clone)]
pub struct CollectibleConfig {
    pub position: Vec3,
    pub collectible_type: CollectibleType,
    pub scale: f32,
    pub rotation: Option<CollectibleRotation>,
    pub on_collect: Arc<dyn Fn(&mut Commands, Entity) + Send + Sync>,
    pub blockchain_item_id: Option<BlockchainItemId>, // Maps to blockchain
}

// Spawning collectibles with blockchain integration
commands.spawn((
    CollectibleType::FirstAidKit,
    BlockchainItemId {
        item_id: 12345,    // From blockchain query
        game_id: 1,        // Current game instance
    },
    // ... other components
));
```

## Development Workflow

### Local Development Setup

#### Prerequisites
- Rust 1.87.0+
- Cairo 2.x
- Dojo v1.5.0
- Docker (recommended)

#### Quick Setup with Docker
```bash
# Clone repository
git clone <repository-url>
cd elysium-descent

# Start blockchain services
cd contracts
docker compose up

# In separate terminal: Run client
cd client
cargo run
```

#### Manual Setup
```bash
# Terminal 1: Start Katana (local blockchain)
katana --dev --dev.no-fee

# Terminal 2: Deploy contracts
cd contracts
sozo build
sozo migrate
# Note the WORLD_ADDRESS from output

# Terminal 3: Start Torii indexer
torii --world <WORLD_ADDRESS> --http.cors_origins "*"

# Terminal 4: Run client
cd client
cargo run
```

### Configuration

#### Dojo Configuration
```rust
// src/constants/dojo.rs
#[derive(Debug, Clone)]
pub struct DojoConfig {
    pub torii_url: String,
    pub katana_url: String,
    pub world_address: Felt,
    pub action_address: Felt,
    pub use_dev_account: bool,
    pub dev_account_index: u32,
}

impl Default for DojoConfig {
    fn default() -> Self {
        Self {
            torii_url: "http://0.0.0.0:8080".to_string(),
            katana_url: "http://0.0.0.0:5050".to_string(),
            world_address: felt!("0x123..."), // Update with deployed address
            action_address: felt!("0x456..."), // Update with deployed address
            use_dev_account: true,
            dev_account_index: 0,
        }
    }
}
```

### Testing Strategy

#### Client Testing
```bash
cd client

# Run all tests
cargo test

# Test specific module
cargo test dojo

# Test with output
cargo test -- --nocapture

# Linting and formatting
cargo clippy
cargo fmt
```

#### Contract Testing
```bash
cd contracts

# Run comprehensive test suite (98 tests)
sozo test

# Test specific modules
sozo test --package elysium_descent --test comprehensive

# Test categories covered:
# - Game creation and management
# - Item pickup and inventory
# - Component interactions
# - Error conditions and edge cases
# - Performance benchmarks
# - Event emission verification
```

### Building and Deployment

#### Development Build
```bash
# Client
cd client
cargo build

# Contracts
cd contracts
sozo build
```

#### Production Build
```bash
# Client release build
cd client
cargo build --release

# Contract deployment to testnet/mainnet
cd contracts
sozo migrate --rpc-url <STARKNET_RPC_URL>
```

## Data Models and Storage

### Blockchain Models

#### Player Model
```cairo
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Player {
    #[key]
    pub player: ContractAddress,     // Wallet address
    pub health: u32,                 // Current health (0-max_health)
    pub max_health: u32,            // Maximum health capacity
    pub level: u32,                 // Player level (starts at 1)
    pub experience: u32,            // Experience points
    pub items_collected: u32,       // Total items collected
}
```

#### Game Model
```cairo
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Game {
    #[key]
    pub game_id: u32,               // Unique game identifier
    pub player: ContractAddress,    // Game owner
    pub status: GameStatus,         // NotStarted, InProgress, Completed
    pub current_level: u32,         // Current level (0 = not started)
    pub created_at: u64,           // Creation timestamp
}
```

#### World Item Model
```cairo
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct WorldItem {
    #[key]
    pub game_id: u32,              // Associated game
    #[key]
    pub item_id: u32,              // Unique item identifier
    pub item_type: ItemType,       // HealthPotion, SurvivalKit, Book
    pub x_position: u32,           // World X coordinate
    pub y_position: u32,           // World Y coordinate
    pub is_collected: bool,        // Collection status
    pub level: u32,                // Level where item spawns
}
```

#### Player Inventory Model
```cairo
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct PlayerInventory {
    #[key]
    pub player: ContractAddress,    // Inventory owner
    pub health_potions: u32,        // Health potion count
    pub survival_kits: u32,         // Survival kit count
    pub books: u32,                 // Book count
    pub capacity: u32,              // Maximum items (default: 50)
}
```

### Client State Management

#### Resource Architecture
```rust
// Game state tracking
#[derive(Resource)]
pub struct GameState {
    pub current_game_id: Option<u32>,
    pub is_creating_game: bool,
    pub player_address: Option<String>,
    pub subscribed_to_entities: bool,
}

// Connection state
#[derive(Resource)]
pub struct DojoSystemState {
    pub torii_connected: bool,
    pub account_connected: bool,
    pub last_error: Option<String>,
    pub config: DojoConfig,
}

// Transaction tracking
#[derive(Resource)]
pub struct PickupTransactionState {
    pub pending_pickups: Vec<(Entity, CollectibleType, u32)>,
}
```

## Error Handling and Recovery

### Client Error Handling

#### Bevy 0.16 Result-Based Systems
```rust
fn safe_dojo_system(
    mut query: Query<&Transform, With<Player>>,
    game_state: Res<GameState>,
) -> bevy::ecs::error::Result {
    // Safe query handling
    let Ok(transform) = query.single() else {
        warn!("No player found");
        return Ok(());
    };
    
    // Game state validation
    let Some(game_id) = game_state.current_game_id else {
        error!("No active game");
        return Err(bevy::ecs::error::QuerySingleError::NoEntities("No active game".into()).into());
    };
    
    // Continue with logic...
    Ok(())
}
```

#### Graceful Degradation
```rust
fn collectible_interaction_system(
    collectible_query: Query<(&CollectibleType, Option<&BlockchainItemId>)>,
    mut pickup_events: EventWriter<PickupItemEvent>,
    mut commands: Commands,
) {
    for (collectible_type, blockchain_id) in collectible_query.iter() {
        match collectible_type {
            CollectibleType::FirstAidKit => {
                if let Some(blockchain_id) = blockchain_id {
                    // Blockchain-integrated collection
                    pickup_events.send(PickupItemEvent {
                        item_type: *collectible_type,
                        item_entity: entity,
                        item_id: blockchain_id.item_id,
                    });
                } else {
                    // Fallback: local collection
                    warn!("No blockchain ID found - collecting locally");
                    commands.entity(entity).despawn();
                }
            }
            _ => {
                // Local collection for other items
                commands.entity(entity).despawn();
            }
        }
    }
}
```

### Contract Error Handling

#### Input Validation
```cairo
fn pickup_item(ref self: ContractState, game_id: u32, item_id: u32) -> bool {
    let caller = get_caller_address();
    
    // Validate game ownership
    let game = get!(self.world, game_id, Game);
    assert(game.player == caller, 'Not your game');
    
    // Validate item exists
    let item = get!(self.world, (game_id, item_id), WorldItem);
    assert(item.item_id != 0, 'Item does not exist');
    assert(!item.is_collected, 'Item already collected');
    
    // Continue with pickup logic...
    true
}
```

## Performance Optimization

### Client Optimization

#### Query Optimization
```rust
// Efficient query filtering
fn optimized_collectible_system(
    // Only query entities that can actually be collected
    collectible_query: Query<
        (Entity, &Transform, &CollectibleType, &Collectible, Option<&BlockchainItemId>),
        (With<Sensor>, Without<Interactable>, Without<Collected>)
    >,
    player_query: Query<&Transform, With<CharacterController>>,
) {
    let Ok(player_transform) = player_query.single() else { return; };
    
    // Early exit if no input
    if !input.any_pressed([KeyCode::ArrowUp, KeyCode::KeyE]) {
        return;
    }
    
    // Process only nearby items
    for (entity, transform, item_type, collectible, blockchain_id) in collectible_query.iter() {
        let distance = player_transform.translation.distance(transform.translation);
        if distance < 5.0 {
            // Process collection
        }
    }
}
```

#### Change Detection
```rust
// Only process when state actually changes
fn reactive_game_state_system(
    changed_game_state: Query<&GameState, Changed<GameState>>,
    mut ui_state: ResMut<UIState>,
) {
    for game_state in changed_game_state.iter() {
        ui_state.update_game_id_display(game_state.current_game_id);
    }
}
```

### Contract Optimization

#### Gas Efficiency
```cairo
// Efficient storage operations
fn optimized_pickup(ref self: ContractState, game_id: u32, item_id: u32) -> bool {
    let caller = get_caller_address();
    
    // Single storage read for validation
    let (mut game, mut player, mut inventory, mut item) = (
        get!(self.world, game_id, Game),
        get!(self.world, caller, Player),
        get!(self.world, caller, PlayerInventory),
        get!(self.world, (game_id, item_id), WorldItem)
    );
    
    // Batch validation
    assert(game.player == caller && !item.is_collected, 'Invalid pickup');
    
    // Atomic updates
    item.is_collected = true;
    player.experience += 10;
    
    // Single batch write
    set!(self.world, (game, player, inventory, item));
    
    true
}
```

## Security Considerations

### Client Security
- Input validation before blockchain calls
- State validation after blockchain responses
- Rate limiting for transaction submissions
- Secure storage of sensitive configuration

### Contract Security
- Caller address validation for all state changes
- Game ownership verification
- Input bounds checking and sanitization
- Reentrancy protection through atomic operations
- Comprehensive test coverage (98 tests covering edge cases)

## Monitoring and Debugging

### Client Debugging
```rust
// Comprehensive logging system
fn debug_dojo_system(
    dojo_state: Res<DojoSystemState>,
    game_state: Res<GameState>,
) {
    if log_enabled!(Level::Debug) {
        debug!("Dojo State: connected={}, game_id={:?}", 
               dojo_state.torii_connected, 
               game_state.current_game_id);
    }
}
```

### Contract Events
```cairo
// Detailed event emission for monitoring
#[derive(Drop, starknet::Event)]
pub struct ItemPickedUp {
    pub player: ContractAddress,
    pub game_id: u32,
    pub item_id: u32,
    pub item_type: ItemType,
    pub new_health: u32,
    pub new_experience: u32,
    pub new_level: u32,
    pub timestamp: u64,
}
```

## Troubleshooting Guide

### Common Issues

#### Connection Problems
```
Issue: "Torii connection failed"
Solution: 
1. Verify Torii is running on correct port
2. Check world address configuration
3. Ensure CORS settings allow client origin
```

#### Transaction Failures
```
Issue: "Transaction rejected"
Solutions:
1. Check account has sufficient funds
2. Verify contract addresses are correct
3. Validate function parameters
4. Check if game state allows the operation
```

#### State Synchronization
```
Issue: "Client state out of sync"
Solutions:
1. Re-subscribe to entity updates
2. Query latest state from blockchain
3. Restart Torii indexer if needed
4. Clear local state and re-initialize
```

---

*This integration guide reflects the current implementation as of the latest updates, including the enhanced contract interface alignment and YarnSpinner removal for streamlined development.*