# Elysium Descent - Smart Contracts

A Fully On-Chain Game (FOCG) implementation using Cairo smart contracts on Starknet with Dojo v1.5.0 framework.

## 🏗️ Architecture Overview

Elysium Descent follows the **Shinigami Design Pattern**, a hierarchical architecture designed specifically for fully on-chain games:

```
📊 Systems     ← Game mode configurations and API endpoints
📦 Components  ← Multi-model business logic operations  
📋 Models     ← Persistent blockchain state management
🏷️ Types      ← Enumerators and entry points for workflow routing
🛠️ Helpers    ← Reusable utilities and data access abstractions
```

### Core Principles
- **Hierarchical Dependencies**: Higher layers depend on lower layers, never reverse
- **Composability**: Components can be mixed across different Systems
- **Type Safety**: Strong typing with comprehensive validation
- **Event-Driven**: Systems communicate through events, not direct calls

## 📁 Project Structure

```
contracts/src/
├── systems/           # Game API and entry points
│   └── actions.cairo      # Main contract interface (IActions)
├── components/        # Business logic orchestration
│   ├── game_component.cairo     # Game lifecycle management
│   └── inventory_component.cairo # Item and inventory operations
├── models/           # Persistent blockchain state
│   ├── player.cairo      # Player stats and progression
│   ├── game.cairo        # Game instances and level tracking
│   ├── inventory.cairo   # Player inventory management
│   ├── world_state.cairo # World items and positioning
│   └── index.cairo       # Model re-exports
├── types/            # Type definitions and enums
│   ├── game_types.cairo   # Game modes, status, difficulty
│   ├── action_types.cairo # Player actions and validation
│   └── item_types.cairo   # Item categories and properties
├── helpers/          # Utilities and abstractions
│   └── store.cairo       # Unified data access layer
├── tests/            # Comprehensive test suite
│   ├── setup.cairo       # Centralized test infrastructure
│   ├── test_simple.cairo # Basic model operations
│   ├── test_world.cairo  # Integration tests
│   └── test_comprehensive.cairo # Full workflow testing
└── lib.cairo         # Module exports
```

## 🎮 Core Game Mechanics

### Game Flow
1. **Game Creation**: Player creates a new game instance with unique ID
2. **Level Progression**: Start levels with procedurally generated items
3. **Item Collection**: Pickup items with capacity and validation constraints
4. **Player Advancement**: Gain experience, level up, increase health/capacity
5. **Game Completion**: Complete levels by collecting all required items

### Key Features
- **Deterministic Randomization**: Reproducible item generation using Poseidon hashing
- **Multi-Player Support**: Isolated game instances per player
- **Progressive Difficulty**: Scaling item counts and complexity by level
- **Inventory Management**: Capacity limits, item transfers, consumable usage
- **Event System**: Comprehensive event emission for external integrations

## 🛠️ Smart Contract Interface

### Main Contract: `actions.cairo`

```cairo
#[starknet::interface]
pub trait IActions<T> {
    // Game Management
    fn create_game(ref self: T) -> u32;
    fn start_level(ref self: T, game_id: u32, level: u32);
    
    // Player Actions
    fn pickup_item(ref self: T, game_id: u32, item_id: u32) -> bool;
    
    // Data Access
    fn get_player_stats(self: @T, player: ContractAddress) -> Player;
    fn get_player_inventory(self: @T, player: ContractAddress) -> PlayerInventory;
    fn get_level_items(self: @T, game_id: u32, level: u32) -> LevelItems;
}
```

### Events
- **GameCreated**: New game instance created
- **LevelStarted**: Level begun with item spawn count
- **ItemPickedUp**: Item collected with type and location data

## 🗃️ Data Models

### Core Models

**Player**
```cairo
struct Player {
    player: ContractAddress,    // Player address
    health: u32,               // Current health (0-max_health)
    max_health: u32,           // Maximum health capacity
    level: u32,                // Player level (affects bonuses)
    experience: u32,           // Experience points for progression
    items_collected: u32,      // Total items collected lifetime
}
```

**Game**
```cairo
struct Game {
    game_id: u32,             // Unique game identifier
    player: ContractAddress,   // Game owner
    status: GameStatus,        // Current game state
    current_level: u32,        // Active level number
    created_at: u64,          // Creation timestamp
    score: u32,               // Game score
}
```

**PlayerInventory**
```cairo
struct PlayerInventory {
    player: ContractAddress,   // Inventory owner
    health_potions: u32,       // Health restoration items
    survival_kits: u32,        // Multi-use survival items
    books: u32,               // Knowledge/experience items
    capacity: u32,            // Maximum inventory slots
}
```

### Comprehensive Type System

**Game Types**
- `GameStatus`: NotStarted, InProgress, Paused, Completed, Abandoned, Failed
- `GameMode`: Tutorial, Standard, Hardcore, Speedrun, Creative, Multiplayer
- `Difficulty`: Easy, Normal, Hard, Nightmare
- `PlayerClass`: Explorer, Survivor, Scholar, Collector, Speedrunner

**Item Types** 
- `ItemType`: HealthPotion, SurvivalKit, Book
- `ItemCategory`: Consumable, Equipment, Material, Quest, Special
- `ItemRarity`: Common, Uncommon, Rare, Epic, Legendary

**Action Types**
- 11 different game actions with validation and cooldown logic
- Comprehensive error handling with 12 error conditions
- Action result types for success/failure scenarios

## 🔧 Development Tools

### Store Pattern
Unified data access layer abstracting Dojo's WorldStorage:

```cairo
let store: Store = StoreTrait::new(world);
let player = store.get_player(player_address);
let game = store.get_game(game_id);
store.set_player(updated_player);
```

**Benefits:**
- Semantic method names (`get_player` vs `world.read_model`)
- Type-safe operations with validation
- Event emission standardization
- Reduced boilerplate code

### Component Architecture

**GameComponent**: Game lifecycle management
- Game creation with unique ID generation
- Level progression and item spawning
- Game state management (pause/resume/end)
- Level completion validation

**InventoryComponent**: Item and player management
- Item pickup with capacity validation
- Consumable item effects
- Player progression (experience, leveling, health)
- Inter-player item transfers

## 🧪 Testing Infrastructure

### Comprehensive Test Suite
- **13 test cases** with 100% pass rate
- **Multi-layered testing**: Unit, integration, and workflow tests
- **Store pattern usage** throughout tests
- **Gas optimization** with appropriate limits (3M-30M gas)

### Test Categories
1. **Model Operations**: CRUD validation for all models
2. **System Integration**: End-to-end workflow testing
3. **Multi-player Scenarios**: Player isolation verification
4. **Component Logic**: Business logic validation
5. **Error Handling**: Expected failure scenarios
6. **Performance**: Gas usage optimization

### Centralized Setup
Single `setup.cairo` module providing:
- Complete test world initialization
- Contract deployment and permissions
- System dispatcher creation
- Standardized test context

## 🚀 Deployment & Development

### Build Commands
```bash
# Build contracts
sozo build

# Run tests
sozo test

# Deploy to local Katana
sozo migrate
```

### Local Development Setup
```bash
# Terminal 1: Start local blockchain
katana --dev --dev.no-fee

# Terminal 2: Build and deploy
cd contracts
sozo build && sozo migrate

# Terminal 3: Start indexer
torii --world <WORLD_ADDRESS> --http.cors_origins "*"
```

### Docker Setup (Recommended)
```bash
cd contracts
docker compose up  # Starts Katana, Sozo, and Torii services
```

## 📊 Technical Specifications

### Performance Characteristics
- **Gas Optimized**: Efficient loop structures and storage operations
- **Scalable**: Singleton patterns and composite key structures
- **Type Safe**: Comprehensive validation at compile time
- **Event Driven**: Standardized event emission for external systems

### Security Features
- **Access Control**: Game ownership validation
- **Input Validation**: Comprehensive parameter checking
- **State Consistency**: Atomic operations with proper error handling
- **Deterministic**: Reproducible outcomes using cryptographic hashing

### Key Implementation Details
- **Namespace**: `elysium_001` for consistent world access
- **Hash Algorithm**: Poseidon for deterministic randomization
- **ID Generation**: Singleton counter with overflow protection
- **Error Handling**: Panic-based Cairo error patterns

## 📚 Documentation

### Architecture Documentation
- **[Shinigami Design Pattern](./AI_DOCS/Shinigami.md)**: Complete architectural framework
- **[Comprehensive Testing Guide](./AI_DOCS/comprehensive-testing-in-dojo.md)**: Testing patterns and best practices
- **[Cairo Advanced Patterns](./AI_DOCS/CAIRO_ADVANCED_PATTERNS.md)**: Language-specific patterns
- **[Dojo Advanced Patterns](./AI_DOCS/DOJO_ADVANCED_PATTERNS.md)**: Framework-specific patterns

### Development Guides
- **[CLAUDE.md](./CLAUDE.md)**: Development guidance and common commands
- **AI_DOCS/**: Comprehensive technical documentation

## 🎯 Production Ready Features

### ✅ Architecture
- [x] **Shinigami Design Pattern** implementation
- [x] **Component-based architecture** with clear separation
- [x] **Store pattern** for unified data access
- [x] **Event-driven communication** between systems

### ✅ Testing
- [x] **Comprehensive test coverage** (13 test cases)
- [x] **Multiple test types** (unit, integration, workflow)
- [x] **Centralized test setup** eliminating code duplication
- [x] **Performance testing** with gas optimization

### ✅ Code Quality
- [x] **Type safety** with comprehensive validation
- [x] **Error handling** following Cairo patterns
- [x] **Documentation** with clear commenting standards
- [x] **Gas optimization** for blockchain constraints

### ✅ Deployment
- [x] **Docker support** for consistent development
- [x] **Build automation** with Sozo integration
- [x] **Local development** setup with Katana/Torii
- [x] **Namespace management** with proper permissions

## 🔗 Related Projects

- **Client**: Rust/Bevy 0.16.0 game client (`../client/`)
- **Documentation**: Game design and architecture docs (`../docs/`)
- **Root Configuration**: Project-wide setup and configurations

---

**Built with [Dojo](https://dojoengine.org) v1.5.0 • [Cairo](https://book.cairo-lang.org/) • [Starknet](https://starknet.io/)**