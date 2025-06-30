# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Elysium Descent is a fully on-chain game (FOCG) combining a Bevy 0.16.0 game client with Cairo smart contracts on Starknet using the Dojo v1.5.1 framework. The project follows the **Shinigami Design Pattern** for hierarchical smart contract architecture.

## Build and Development Commands

### Smart Contracts (Cairo/Dojo)
```bash
cd contracts

# Build contracts
sozo build

# Run tests
sozo test

# Deploy to local Katana devnet
sozo migrate

# Start local development environment
katana --dev --dev.no-fee

# Start indexer (replace <WORLD_ADDRESS> with actual address)
torii --world <WORLD_ADDRESS> --http.cors_origins "*"
```

### Game Client (Rust/Bevy)
```bash
cd client

# Build client
cargo build

# Run client
cargo run

# Run tests
cargo test

# Format code
cargo fmt

# Check code quality
cargo clippy
```

### Development Environment Setup
```bash
# Option 1: Docker (Recommended)
cd contracts
docker compose up

# Option 2: Manual setup
# Terminal 1: Start blockchain
katana --dev --dev.no-fee

# Terminal 2: Deploy contracts
cd contracts && sozo build && sozo migrate

# Terminal 3: Start indexer
torii --world <WORLD_ADDRESS> --http.cors_origins "*"

# Terminal 4: Run client
cd client && cargo run
```

## Architecture Overview

### Smart Contract Architecture (Shinigami Pattern)
The contracts follow a strict hierarchical pattern:

```
📊 Systems     ← Game API endpoints and entry points
📦 Components  ← Business logic orchestration layer
📋 Models      ← Persistent blockchain state management
🏷️ Types       ← Enumerators and data structures
🛠️ Helpers     ← Utilities and data access abstractions
```

**Key Principles:**
- Higher layers depend on lower layers only (never reverse)
- Components are composable across different Systems
- Strong typing with comprehensive validation
- Event-driven communication between systems

### Project Structure
```
contracts/src/
├── systems/actions.cairo      # Main contract interface (IActions)
├── components/               # Business logic layer
│   ├── game.cairo           # Game lifecycle management
│   └── inventory.cairo      # Item and inventory operations
├── models/                  # Persistent state models
│   ├── player.cairo         # Player stats and progression
│   ├── game.cairo          # Game instances and levels
│   ├── inventory.cairo     # Player inventory management
│   └── world_state.cairo   # World items and positioning
├── types/                   # Type definitions and enums
├── helpers/store.cairo      # Unified data access layer
└── elements/               # Item definitions and factory patterns

client/src/
├── systems/                # Game systems
│   ├── dojo/              # Dojo integration
│   ├── character_controller.rs
│   └── collectibles.rs
├── screens/               # Game screens (menu, gameplay, etc.)
├── ui/                   # User interface components
└── resources/            # Assets and audio management
```

### Key Contracts and Interfaces

**Main Contract Interface (`systems/actions.cairo`):**
```cairo
trait IActions<T> {
    fn create_game(ref self: T) -> u32;
    fn start_level(ref self: T, game_id: u32, level: u32);
    fn pickup_item(ref self: T, game_id: u32, item_id: u32) -> bool;
    fn get_player_stats(self: @T, player: ContractAddress) -> Player;
    fn get_player_inventory(self: @T, player: ContractAddress) -> PlayerInventory;
    fn get_level_items(self: @T, game_id: u32, level: u32) -> LevelItems;
}
```

**Store Pattern:** 
All data access uses the Store abstraction in `helpers/store.cairo`:
```cairo
let store: Store = StoreTrait::new(world);
let player = store.get_player(player_address);
store.set_player(updated_player);
```

### Core Game Models

**Player:** Health, level, experience, and lifetime stats
**Game:** Game instances with status, level, and score tracking  
**PlayerInventory:** Item storage with capacity limits
**LevelItems:** Procedurally generated items per game level

### Client Architecture (Bevy)

**Key Systems:**
- `dojo/`: Blockchain integration systems
- `character_controller.rs`: Player movement and physics
- `collectibles.rs`: Item interaction and pickup logic
- `dialogue_view.rs`: Book reading and narrative systems

**Dependencies:**
- Bevy 0.16.0 with custom feature set
- `dojo_bevy_plugin` for blockchain integration
- `bevy_lunex` for UI system
- `avian3d` for 3D physics
- `bevy_yarnspinner` for dialogue system

## Testing Infrastructure

### Smart Contract Tests
- **13 comprehensive test cases** with 100% pass rate
- Multi-layered testing: unit, integration, and workflow
- Centralized setup in `tests/setup.cairo`
- Store pattern usage throughout tests
- Gas optimization with appropriate limits (3M-30M gas)

### Test Categories:
1. **Model Operations:** CRUD validation (`test_simple.cairo`)
2. **System Integration:** End-to-end workflows (`test_comprehensive.cairo`)
3. **Component Logic:** Business logic validation (`test_component_layer.cairo`)
4. **Error Handling:** Expected failure scenarios (`test_error_conditions.cairo`)
5. **Performance:** Gas usage optimization (`test_performance.cairo`)

### Running Specific Tests
```bash
cd contracts

# Run all tests
sozo test

# Run specific test file
sozo test --path src/tests/test_simple.cairo
```

## Game Mechanics

### Core Game Flow
1. **Game Creation:** `create_game()` returns unique game ID
2. **Level Start:** `start_level(game_id, level)` spawns procedural items
3. **Item Collection:** `pickup_item(game_id, item_id)` with capacity validation
4. **Player Progression:** Experience gain, leveling, health increases
5. **Level Completion:** Collect all items to advance

### Item Types
- **HealthPotion:** Restores player health
- **SurvivalKit:** Multi-use survival items
- **Book:** Knowledge items that trigger dialogue system

### Deterministic Systems
- Uses Poseidon hashing for reproducible item generation
- Multi-player support with isolated game instances
- Progressive difficulty scaling by level

## Development Guidelines

### Smart Contract Development
- Follow the Shinigami pattern hierarchy strictly
- Use the Store pattern for all data access
- Emit events for all significant state changes
- Validate ownership and parameters at System layer
- Test gas usage with performance tests

### Client Development
- Follow Bevy ECS patterns and conventions
- Use the plugin system for modular features
- Leverage the asset loader for resources
- Implement proper error handling for Dojo interactions
- Test client-contract integration thoroughly

### Code Quality
- Run `cargo fmt` and `cargo clippy` for Rust code
- Use semantic commit messages
- Add comprehensive tests for new features
- Document public APIs and complex logic
- Follow the project's naming conventions

## Configuration

### Dojo Configuration
- **Namespace:** `elysium_001` for consistent world access
- **Network:** Local Katana devnet for development
- **World Seed:** `elysium_001`

### Key Files
- `contracts/dojo_dev.toml` - Development configuration
- `contracts/Scarb.toml` - Cairo dependencies and build settings
- `client/Cargo.toml` - Rust dependencies and optimization settings

## Troubleshooting

### Common Issues
1. **Contract deployment fails:** Ensure Katana is running and has the correct account setup
2. **Tests fail:** Check that all dependencies are installed and Scarb version is correct (2.10.1)
3. **Client can't connect:** Verify Torii is running and world address is correct
4. **Performance issues:** Check gas limits and optimize query patterns

### Debug Commands
```bash
# Check Katana status
curl -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"starknet_chainId","params":[],"id":1}' http://localhost:5050

# Check deployed contracts
sozo model list

# Monitor events
torii --world <WORLD_ADDRESS> --events-to-stdout
```