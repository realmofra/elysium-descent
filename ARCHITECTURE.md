# Elysium Descent - Architecture Documentation

## Overview

Elysium Descent is a Fully On-Chain Game (FOCG) that combines a Rust/Bevy client with Cairo smart contracts on Starknet using the Dojo framework. The game follows a roguelike design where core game logic runs on the blockchain while the client provides real-time interaction and visualization.

## System Architecture

### High-Level Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Bevy Client   │◄──►│ Dojo Framework  │◄──►│ Starknet Cairo  │
│   (Rust)        │    │   (Bridge)      │    │   Contracts     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
    ┌────▼────┐              ┌───▼───┐              ┌────▼────┐
    │  Game   │              │ Torii │              │  Game   │
    │Rendering│              │Index- │              │ State   │
    │& Input  │              │ ing   │              │Storage  │
    └─────────┘              └───────┘              └─────────┘
```

### Technology Stack

#### Client (Bevy 0.16.0)
- **Engine**: Bevy 0.16 with ECS architecture
- **Physics**: Avian3D for 3D physics simulation
- **Audio**: Bevy Kira Audio for sound management
- **UI**: Bevy Lunex for UI framework
- **Blockchain**: Dojo Bevy Plugin for Starknet integration

#### Smart Contracts (Cairo/Dojo)
- **Language**: Cairo 2.x
- **Framework**: Dojo v1.5.0
- **Network**: Starknet
- **Architecture**: Shinigami Design Pattern

## Client Architecture

### Component Systems

#### Core Systems
- **Character Controller**: Player movement and input handling
- **Collectibles System**: Item collection with blockchain integration
- **Inventory System**: Local and blockchain inventory management
- **Dojo Integration**: Blockchain communication systems

#### Directory Structure
```
client/src/
├── constants/          # Configuration constants
│   ├── dojo.rs        # Blockchain connection config
│   ├── movement.rs    # Physics and movement settings
│   └── mod.rs
├── systems/
│   ├── character_controller.rs  # Player movement
│   ├── collectibles.rs         # Item collection logic
│   ├── dojo/                   # Blockchain integration
│   │   ├── create_game.rs      # Game creation system
│   │   ├── pickup_item.rs      # Item pickup transactions
│   │   └── mod.rs
│   └── inventory/              # Inventory management
├── screens/                    # Game state management
│   ├── gameplay.rs
│   ├── main_menu.rs
│   └── settings.rs
├── resources/                  # Asset and resource management
└── ui/                        # User interface
```

### Bevy 0.16 Integration

#### Required Components System
The project leverages Bevy 0.16's Required Components feature for automatic dependency injection:

```rust
#[derive(Component)]
#[require(Transform, Visibility)]
struct Renderable;

// Automatically adds Transform and Visibility when spawning Renderable
commands.spawn(Renderable);
```

#### Error Handling Revolution
All systems use Bevy 0.16's Result-based error handling:

```rust
fn safe_player_system(mut query: Query<&mut Transform, With<Player>>) -> bevy::ecs::error::Result {
    let mut transform = query.single_mut()?;
    transform.translation.x += 1.0;
    Ok(())
}
```

#### Observer System
Reactive programming using the new Observer system:

```rust
app.observe(|trigger: Trigger<OnInsert, Health>, mut commands: Commands| {
    let entity = trigger.entity();
    commands.entity(entity).insert(HealthBar::new());
});
```

## Smart Contract Architecture

### Shinigami Design Pattern

The contracts follow the Shinigami Design Pattern - a hierarchical architecture for fully on-chain games:

```
Systems     ┌─ Game modes with specific component configurations
    ▲       │
Components  ┌─ Multi-model operations that orchestrate workflows  
    ▲       │
Models      ┌─ Persistent onchain entities with data integrity
    ▲       │
Types       ┌─ Enumerators and entry points for routing
    ▲       │
Elements    └─ Game entities with specific traits and behaviors
```

#### Layer Responsibilities

1. **Elements** (Bottom): Game entities with specific behaviors
   - `HealthPotion`, `SurvivalKit`, `Book` items
   - Trait-based interfaces for uniform interaction

2. **Types**: Enums and entry points
   - `ItemType`, `ActionType` enumerations
   - Input validation and workflow routing

3. **Models**: Persistent blockchain state
   - `Player`, `Game`, `PlayerInventory`, `WorldItem`
   - Data integrity and storage optimization

4. **Components**: Multi-model business logic
   - `GameComponent`, `InventoryComponent`
   - Complex workflow orchestration

5. **Systems**: Game mode configurations
   - `Actions` system with public interface
   - Configurable rule sets and validation

### Contract Interface

#### Main Actions Interface
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

#### Data Models
```cairo
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Player {
    #[key]
    pub player: ContractAddress,
    pub health: u32,
    pub max_health: u32,
    pub level: u32,
    pub experience: u32,
    pub items_collected: u32,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct WorldItem {
    #[key]
    pub game_id: u32,
    #[key]
    pub item_id: u32,
    pub item_type: ItemType,
    pub x_position: u32,
    pub y_position: u32,
    pub is_collected: bool,
    pub level: u32,
}
```

## Blockchain Integration

### Dojo Integration Flow

1. **Connection Setup**
   - Client connects to Torii indexer
   - Starknet account authentication
   - World contract address configuration

2. **Game Creation**
   ```rust
   // Client triggers game creation
   create_game_events.send(CreateGameEvent);
   
   // System calls blockchain
   let call = Call {
       to: action_address,
       selector: CREATE_GAME_SELECTOR,
       calldata: vec![], // No parameters needed
   };
   dojo.queue_tx(&tokio, vec![call]);
   ```

3. **Item Collection**
   ```rust
   // Client detects item pickup
   pickup_events.send(PickupItemEvent {
       item_type: CollectibleType::FirstAidKit,
       item_entity: entity,
       item_id: blockchain_item_id,
   });
   
   // System calls blockchain with parameters
   let call = Call {
       to: action_address,
       selector: PICKUP_ITEM_SELECTOR,
       calldata: vec![
           Felt::from(game_id),
           Felt::from(item_id),
       ],
   };
   ```

4. **State Synchronization**
   - Torii indexes blockchain events
   - Client subscribes to entity updates
   - Real-time state synchronization via events

### Item ID Management

Items are uniquely identified using deterministic generation:

```cairo
fn generate_item_id(game_id: u32, level: u32, item_counter: u32) -> u32 {
    let hash = poseidon_hash_span(
        array![game_id.into(), level.into(), item_counter.into()].span(),
    );
    let hash_u256: u256 = hash.into();
    (hash_u256 % 0x100000000_u256).try_into().unwrap()
}
```

## Development Workflow

### Local Development Setup

#### Docker Setup (Recommended)
```bash
cd contracts
docker compose up  # Starts Katana, Sozo, and Torii services
```

#### Manual Setup
```bash
# Terminal 1: Start local blockchain
katana --dev --dev.no-fee

# Terminal 2: Build and deploy contracts
cd contracts
sozo build && sozo migrate

# Terminal 3: Start indexer
torii --world <WORLD_ADDRESS> --http.cors_origins "*"

# Terminal 4: Run game client
cd client
cargo run
```

### Testing Strategy

#### Client Testing
```bash
cd client
cargo test        # Unit tests
cargo clippy      # Linting
cargo fmt         # Code formatting
```

#### Contract Testing
```bash
cd contracts
sozo test         # 98 comprehensive tests covering:
                  # - Game features and mechanics
                  # - Inventory operations
                  # - Component interactions
                  # - Error conditions
                  # - Performance benchmarks
                  # - Event emission
```

### Build Process

#### Client Build
```bash
cd client
cargo build --release  # Production build
```

#### Contract Deployment
```bash
cd contracts
sozo build             # Compile contracts
sozo migrate           # Deploy to network
```

## Performance Considerations

### Client Optimization

#### Bevy 0.16 Performance Features
- **GPU-Driven Rendering**: Bindless materials for massive performance gains
- **GPU Occlusion Culling**: Automatic frustum and occlusion culling
- **Required Components**: Zero-cost component dependency injection
- **Error Handling**: Result-based systems prevent panics

#### Optimization Strategies
- Component storage optimization (Table vs SparseSet)
- Query filtering for selective system execution
- Change detection for minimal processing
- Resource pooling for frequently created/destroyed objects

### Contract Optimization

#### Gas Efficiency
- Poseidon hash for deterministic ID generation
- Atomic operations for state changes
- Efficient storage patterns using Dojo models
- Minimal external calls and loops

#### Storage Optimization
- Composite keys for efficient querying
- Packed data structures where appropriate
- Event emission for off-chain indexing
- Strategic use of storage vs computation

## Security Architecture

### Client Security
- Input validation before blockchain calls
- State validation after blockchain responses
- Error handling for network failures
- Asset verification and validation

### Contract Security
- Authentication via caller address
- Game ownership validation
- Input sanitization and bounds checking
- Reentrancy protection through atomic operations
- Comprehensive test coverage (98 tests)

## Event System

### Client Events
```rust
// Game creation events
#[derive(Event, Debug)]
pub struct CreateGameEvent;

#[derive(Event, Debug)]
pub struct GameCreatedEvent {
    pub game_id: u32,
    pub player_address: String,
}

// Item collection events
#[derive(Event, Debug)]
pub struct PickupItemEvent {
    pub item_type: CollectibleType,
    pub item_entity: Entity,
    pub item_id: u32,
}
```

### Contract Events
```cairo
#[derive(Drop, starknet::Event)]
pub struct GameCreated {
    pub player: ContractAddress,
    pub game_id: u32,
    pub timestamp: u64,
}

#[derive(Drop, starknet::Event)]
pub struct ItemPickedUp {
    pub player: ContractAddress,
    pub game_id: u32,
    pub item_id: u32,
    pub item_type: ItemType,
    pub new_health: u32,
    pub new_level: u32,
}
```

## Asset Management

### Asset Types
- **3D Models**: glTF format for characters, items, and environment
- **Audio**: OGG format for cross-platform compatibility
- **Textures**: PNG/JPG with texture atlasing for optimization
- **Fonts**: Rajdhani family for consistent typography
- **UI**: Lunex-compatible components and layouts

### Asset Loading Strategy
- Typed asset collections for organization
- Loading states for progress tracking
- Hot reload support for development
- Asset validation and error handling

## Future Architecture Considerations

### Scalability
- Multiple world contracts for game sharding
- Cross-contract communication protocols
- Client-side prediction with server reconciliation
- Progressive asset loading for large worlds

### Extensibility
- Plugin architecture for game features
- Modular contract deployment
- Asset pipeline for user-generated content
- API versioning for backward compatibility

### Performance Evolution
- WASM compilation for cross-platform deployment
- GPU compute shaders for complex game logic
- Advanced culling and LOD systems
- Predictive asset loading

---

*This architecture documentation reflects the current state as of the recent updates including Dojo system interface improvements and YarnSpinner removal for streamlined development.*