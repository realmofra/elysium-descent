# Elysium Descent - Smart Contracts

![Elysium Descent](./assets/cover.png)

A Fully On-Chain Game (FOCG) built with Dojo v1.5.0 on Starknet, implementing the **Shinigami Design Pattern** for hierarchical game architecture.

## Overview

Elysium Descent is a roguelike game where core game logic runs entirely on the blockchain. The smart contracts handle inventory management, player progression, level generation, and game state persistence using Dojo's ECS (Entity Component System) framework.

## Architecture

This project follows the **Shinigami Design Pattern** - a hierarchical architecture for fully on-chain games:

```
📁 src/
├── 📁 types/           # Layer 2: Entry Points & Enums
│   ├── game_types.cairo     # Game states, modes, difficulty
│   ├── item_types.cairo     # Item definitions and properties
│   └── action_types.cairo   # Player action types
├── 📁 models/          # Layer 3: Persistent On-chain State
│   ├── game.cairo          # Game instances and metadata
│   ├── player.cairo        # Player stats and progression
│   ├── inventory.cairo     # Player inventory management
│   └── world_state.cairo   # World items and positions
├── 📁 components/      # Layer 4: Business Logic Orchestration
│   ├── game_component.cairo     # Game lifecycle management
│   └── inventory_component.cairo # Inventory operations
├── 📁 systems/         # Layer 5: Public Interface
│   └── actions.cairo        # External contract interface
└── 📁 helpers/         # Layer 6: Utilities
    └── store.cairo          # Domain-specific storage wrapper
```

### Key Design Principles

- **Hierarchical Dependencies**: Higher layers depend on lower layers, never reverse
- **Composability**: Components can be mixed across different game modes
- **Type Safety**: Strong typing with comprehensive validation
- **Event-Driven**: Systems communicate through events for indexing
- **Store Pattern**: Domain-specific wrapper around WorldStorage inspired by Arcade

## Smart Contract Features

### 🎮 Game Management
- **Game Creation**: Initialize new game instances with unique IDs
- **Level Progression**: Manage level transitions and content generation
- **Game State**: Handle pause/resume/completion states
- **Score Tracking**: Persistent scoring and achievements

### 👤 Player System
- **Character Stats**: Health, experience, level progression
- **Progression**: Experience-based leveling with stat bonuses
- **Session Tracking**: Player state persistence across sessions

### 🎒 Inventory System
- **Item Management**: Pickup, use, and transfer items
- **Capacity Limits**: Inventory space management
- **Item Types**: Health potions, survival kits, and collectible books
- **Real-time Updates**: Immediate state synchronization

### 🌍 World State
- **Item Spawning**: Procedural item generation per level
- **Position Tracking**: 2D coordinate system for item placement
- **Collection State**: Track which items have been collected
- **Level Generation**: Dynamic content based on algorithms

## Development Setup

### Prerequisites
- [Dojo v1.5.0](https://dojoengine.org/getting-started.html)
- [Starknet Foundry](https://foundry-rs.github.io/starknet-foundry/)

### Quick Start with Docker (Recommended)
```bash
cd contracts
docker compose up  # Starts Katana, Sozo, and Torii services
```

### Manual Development Setup

#### Terminal 1: Start Local Blockchain
```bash
katana --dev --dev.no-fee
```

#### Terminal 2: Build and Deploy Contracts
```bash
cd contracts

# Build contracts
sozo build

# Deploy to local network
sozo migrate

# Inspect the deployed world
sozo inspect
```

#### Terminal 3: Start Indexer
```bash
# Replace <WORLD_ADDRESS> with the actual deployed world address
torii --world <WORLD_ADDRESS> --http.cors_origins "*"
```

## Testing

```bash
# Run contract tests
sozo test

# Run specific test
sozo test test_world

# Run with verbose output
sozo test -v
```

## Contract Interface

### Core Actions

```cairo
// Create a new game instance
fn create_game() -> u32

// Start a new level with procedural content
fn start_level(game_id: u32, level: u32)

// Pick up an item from the world
fn pickup_item(game_id: u32, item_id: u32) -> bool

// Get player statistics
fn get_player_stats(player: ContractAddress) -> Player

// Get player inventory
fn get_player_inventory(player: ContractAddress) -> PlayerInventory
```

### Events

```cairo
// Emitted when a new game is created
struct GameCreated {
    player: ContractAddress,
    game_id: u32,
    created_at: u64,
}

// Emitted when a level starts
struct LevelStarted {
    player: ContractAddress,
    game_id: u32,
    level: u32,
    items_spawned: u32,
}

// Emitted when an item is picked up
struct ItemPickedUp {
    player: ContractAddress,
    game_id: u32,
    item_id: u32,
    item_type: ItemType,
    level: u32,
}
```

## Game Mechanics

### Item System
- **Health Potions**: Restore player health (stackable up to 99)
- **Survival Kits**: Emergency health restoration (stackable up to 10)  
- **Books**: Provide experience points for progression (non-stackable)

### Level Progression
- **Dynamic Item Spawning**: Items generated based on level algorithms
- **Difficulty Scaling**: More items and complexity at higher levels
- **Procedural Generation**: Deterministic but varied content using seeds

### Player Progression
- **Experience System**: Gain XP from collecting items and completing levels
- **Level Rewards**: Increased health and stats per level up
- **Inventory Management**: Limited capacity encourages strategic decisions

## Configuration

### Environment Files
- `dojo_dev.toml` - Development network configuration
- `dojo_release.toml` - Production network configuration  
- `katana.toml` - Local blockchain settings
- `torii_dev.toml` - Indexer configuration

### Build Configuration
See `Scarb.toml` for dependencies and build settings.

## Architecture Documentation

For detailed architectural documentation, see:
- [`AI_DOCS/Shinigami.md`](./AI_DOCS/Shinigami.md) - Complete Shinigami pattern guide
- [`AI_DOCS/DOJO_ARCHITECTURE_RESEARCH.md`](./AI_DOCS/DOJO_ARCHITECTURE_RESEARCH.md) - Dojo ECS patterns
- [`ARCHITECTURE_NOTES.md`](./ARCHITECTURE_NOTES.md) - Implementation notes

## Integration with Client

The contracts are designed to integrate with a Bevy-based game client:
- **On-Chain**: Inventory, progression, game state, persistence
- **Client-Side**: 3D rendering, movement, input handling, networking
- **Synchronization**: Via Torii indexer and event subscriptions

## Contributing

1. **Architecture**: Follow the Shinigami design pattern
2. **Testing**: Add tests for all new functionality  
3. **Documentation**: Update this README for significant changes
4. **Code Style**: Follow Cairo and Dojo best practices

## License

This project is part of the Elysium Descent game. See the main project license for details.

---

Built with ❤️ using [Dojo Engine](https://dojoengine.org) and the Shinigami Design Pattern.