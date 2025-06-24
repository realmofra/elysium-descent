# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Elysium Descent is a Fully On-Chain Game (FOCG) combining a Rust/Bevy 0.16.0 client with Cairo smart contracts on Starknet using Dojo v1.5.0 framework. The game is a roguelike where core game logic runs on the blockchain.

## Common Development Commands

### Docker Setup (Recommended)
```bash
cd contracts
docker compose up  # Starts Katana, Sozo, and Torii services
```

### Manual Development Setup
```bash
# Terminal 1: Start local blockchain
katana --dev --dev.no-fee

# Terminal 2: Build and deploy contracts
cd contracts
sozo build
sozo migrate

# Terminal 3: Start indexer (replace with actual world address)
torii --world <WORLD_ADDRESS> --http.cors_origins "*"

# Terminal 4: Run game client
cd client
cargo run
```

### Testing
```bash
# Test client
cd client && cargo test

# Test contracts (98 comprehensive tests)
cd contracts && sozo test
```

### Building
```bash
# Build client
cd client && cargo build

# Build contracts
cd contracts && sozo build
```

## Architecture Overview

### Client (Rust/Bevy 0.16.0)
- **ECS Architecture**: Uses Bevy's Entity Component System
- **Systems**: Located in `client/src/systems/` - handle game logic, Dojo integration, input
- **Screens**: State management in `client/src/screens/` - menu, gameplay, settings
- **Resources**: Asset and configuration management
- **Dojo Integration**: Custom plugin connecting Bevy to Starknet contracts

### Smart Contracts (Cairo/Dojo)
- **Models**: Game state data structures in `contracts/src/models/`
- **Systems**: Game logic and player actions in `contracts/src/systems/`
- **World**: Central registry managing all models and systems
- **Events**: State change notifications for indexing
- **Tests**: Comprehensive 98-test suite covering game features, inventory, components, error conditions, performance, helpers, and events

### Shinigami Design Pattern
This project follows the **Shinigami Design Pattern** - a hierarchical architecture for fully on-chain games:

1. **Elements** (Bottom): Game entities (weapons, enemies, rooms) with specific traits and behaviors
2. **Types**: Enumerators and entry points (ItemType, ActionType) that direct workflows to Elements
3. **Models**: Persistent onchain entities (Player, GameState, Inventory) with data integrity
4. **Components**: Multi-model operations (CombatSystem, TradingSystem) that orchestrate complex workflows
5. **Systems**: Game modes (StandardMode, TutorialMode) with specific component configurations
6. **Helpers**: Reusable utilities (damage calculators, random generators) without game data

**Key Principles**:
- **Hierarchical Dependencies**: Higher layers depend on lower layers, never reverse
- **Composability**: Components can be mixed across different Systems
- **Type Safety**: Strong typing with comprehensive validation
- **Event-Driven**: Systems communicate through events, not direct calls

**Implementation Structure**:
```
contracts/src/
├── elements/     # Game entities with specific behaviors
├── types/        # Enums and entry points for routing
├── models/       # Persistent blockchain state
├── components/   # Multi-model business logic
├── systems/      # Game mode configurations
└── helpers/      # Reusable utility functions
```

### Key Components
- **Character Controller**: Player movement and input handling

## Critical Technical Notes

### Bevy 0.16.0 Breaking Changes
- `Query::single()` returns `Result` - always handle with `expect()` or proper error handling
- Required Components replace Bundles - components automatically inject dependencies
- Built-in entity relationships - use parent-child system for hierarchies
- Observer system for reactive programming - prefer over direct system dependencies

### Dojo Integration
- Game state synchronization between client and blockchain
- Use `dojo_bevy_plugin` for Starknet connectivity
- World address configuration required for Torii indexer
- Contract deployment needed before client connection

### Performance Considerations
- GPU instancing for similar objects
- Texture atlasing for UI elements
- Spatial indexing for efficient collision detection
- LOD system for 3D models at distance

## Development Guidelines

### Code Organization
- Client logic in `client/src/` with clear separation of systems, screens, and resources
- Contract logic in `contracts/src/` following Dojo model/system patterns
- Assets organized by type in `client/assets/`

### Blockchain Development
- Always test contracts with `sozo test` before deployment
- Use Katana devnet for local development
- Torii indexer required for client-blockchain communication
- World address changes require client configuration updates

#### Shinigami Pattern Guidelines
- **Elements**: Create focused, single-responsibility game entities with trait-based interfaces
- **Types**: Use enums for finite state spaces with comprehensive validation and error handling
- **Models**: Design for gas efficiency with atomic operations and event emission
- **Components**: Validate all inputs, maintain transaction atomicity, handle edge cases gracefully
- **Systems**: Design for multiple gameplay modes with configurable rule sets
- **Helpers**: Keep functions pure when possible, optimize for performance, provide test coverage

#### Code Organization Best Practices
- Use trait-based design for uniform interfaces across Elements
- Implement validation at the Type level with custom assertion traits
- Design Models for concurrent access and storage optimization
- Create Components that orchestrate multiple Models with proper error handling
- Build Systems that are configurable and support dynamic rule changes
- Develop Helpers that are reusable across the entire application

### Asset Management
- 3D models in glTF format
- Audio files in OGG format for cross-platform compatibility
- Texture atlasing for optimized rendering
- Font consistency using Rajdhani family

## Project Structure Context

- `client/AI_DOCS/`: Contains detailed technical documentation
  - `Bevy.md`: Bevy 0.16 migration guide and ECS patterns
  - `Shinigami.md`: **Comprehensive Shinigami Design Pattern documentation with implementation examples**
- `docs/src/gdd/`: Game Design Document
- Individual CLAUDE.md files exist in `client/` and `contracts/` subdirectories for specific guidance

## Essential References

- **📖 [Shinigami Design Pattern Guide](./contracts/AI_DOCS/Shinigami.md)**: Complete architectural framework for building FOCGs
- **🎮 [Bevy 0.16 Migration Guide](./client/AI_DOCS/Bevy.md)**: Breaking changes and modern patterns
- **🏗️ [Game Design Document](./docs/src/gdd/)**: Core game mechanics and design philosophy
