# Elysium Descent

**A Fully On-Chain Roguelike Game combining Rust/Bevy with Cairo/Starknet**

Elysium Descent is an innovative blockchain-integrated roguelike game that combines real-time 3D gameplay with fully on-chain game logic. Built with Bevy 0.16 and powered by Dojo on Starknet, it represents the cutting edge of Fully On-Chain Game (FOCG) development.

## 🎮 Game Overview

Explore the depths of Elysium in this roguelike adventure where your progress, items, and achievements are permanently stored on the blockchain. Battle through procedurally generated dungeons, collect mystical artifacts, and build your character's legacy on Starknet.

### Key Features
- **🔗 Fully On-Chain Logic**: Core game mechanics run on Starknet via Dojo framework
- **🎯 Real-time 3D Gameplay**: Smooth character movement and physics with Bevy engine
- **📦 Blockchain Items**: Collectibles and inventory permanently stored on-chain
- **⚔️ Roguelike Mechanics**: Procedural generation with persistent character progression
- **🎨 Modern Graphics**: GPU-driven rendering with Bevy 0.16's latest features

## 🚀 Quick Start

### Prerequisites
- Rust 1.87.0+
- Cairo 2.x
- Dojo v1.5.0
- Docker (recommended for development)

### Docker Setup (Recommended)
```bash
# Clone the repository
git clone https://github.com/realmofra/elysium_descent.git
cd elysium-descent

# Start blockchain services
cd contracts
docker compose up

# In a new terminal, run the client
cd client
cargo run
```

### Manual Setup
```bash
# Terminal 1: Start local blockchain
katana --dev --dev.no-fee

# Terminal 2: Deploy contracts
cd contracts
sozo build && sozo migrate

# Terminal 3: Start indexer (use WORLD_ADDRESS from step 2)
torii --world <WORLD_ADDRESS> --http.cors_origins "*"

# Terminal 4: Run game
cd client
cargo run
```

## 🏗️ Architecture

### Technology Stack
- **Client**: Rust + Bevy 0.16 (ECS, Physics, Rendering)
- **Blockchain**: Cairo + Dojo v1.5.0 on Starknet
- **Physics**: Avian3D for realistic movement
- **Audio**: Bevy Kira Audio
- **UI**: Bevy Lunex framework

### Project Structure
```
elysium-descent/
├── client/           # Bevy game client
│   ├── src/
│   │   ├── systems/  # Game logic systems
│   │   │   └── dojo/ # Blockchain integration
│   │   ├── screens/  # Game states
│   │   └── resources/# Asset management
│   └── assets/       # Game assets
├── contracts/        # Cairo smart contracts
│   ├── src/
│   │   ├── systems/  # Contract entry points
│   │   ├── models/   # Data models
│   │   └── components/# Business logic
│   └── tests/        # 98 comprehensive tests
└── docs/            # Documentation
```

## 🎯 Current Features

### ✅ Implemented
- **Player Movement**: Smooth 3D character controller
- **Item Collection**: Books and health kits with blockchain integration
- **Game Creation**: On-chain game instance management
- **Inventory System**: Real-time inventory with blockchain persistence
- **Physics Integration**: Collision detection and realistic movement
- **Audio System**: Music and sound effects

### 🚧 In Development
- Combat system with monsters
- Dungeon generation
- Level progression
- Enhanced UI/UX

## 🔧 Development

### Building
```bash
# Client
cd client
cargo build --release

# Contracts  
cd contracts
sozo build
```

### Testing
```bash
# Client tests
cd client
cargo test

# Contract tests (98 comprehensive tests)
cd contracts
sozo test
```

### Code Quality
```bash
# Formatting and linting
cargo fmt
cargo clippy
```

## 📚 Documentation

- **[Architecture Guide](./ARCHITECTURE.md)** - Complete system architecture
- **[Dojo Integration](./DOJO_INTEGRATION_GUIDE.md)** - Blockchain integration details
- **[Development Roadmap](./client/ROADMAP.md)** - Feature roadmap and priorities
- **[Contributing Guide](./CONTRIBUTING.md)** - How to contribute

### Technical Guides
- **[Bevy 0.16 Migration](./client/AI_DOCS/Bevy.md)** - Breaking changes and patterns
- **[Shinigami Pattern](./contracts/AI_DOCS/Shinigami.md)** - Contract architecture framework
- **[Game Design Document](./docs/src/gdd/)** - Core game design

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

### Development Setup
1. Fork the repository
2. Follow the quick start guide above
3. Make your changes
4. Run tests: `cargo test` (client) and `sozo test` (contracts)
5. Submit a pull request

### Areas for Contribution
- 🎮 Game features and mechanics
- 🔧 Performance optimizations
- 🎨 Asset creation and UI improvements
- 📚 Documentation enhancements
- 🧪 Test coverage expansion

## 🎮 Game Controls

- **WASD**: Move character
- **E**: Interact with items
- **Mouse**: Look around
- **Shift**: Run
- **Space**: Jump (when implemented)

## 🌟 Recent Updates

### Latest (Current)
- ✅ **Contract Interface Alignment**: Updated Dojo systems to match current contract interface
- ✅ **Enhanced Item System**: Proper blockchain item ID mapping and collection
- ✅ **YarnSpinner Removal**: Streamlined development by removing dialogue system
- ✅ **Error Handling**: Bevy 0.16 Result-based error handling throughout
- ✅ **Performance**: GPU-driven rendering and optimization improvements

### Previous Updates
- Bevy 0.16 migration with Required Components
- Comprehensive test suite (98 tests)
- Shinigami design pattern implementation
- Dojo v1.5.0 integration

## 📄 License

This project is dual-licensed under:
- Apache License 2.0 ([LICENSE-APACHE](./LICENSE-APACHE))
- MIT License ([LICENSE-MIT](./LICENSE-MIT))

## 🔗 Links

- **Website**: [realmofra.com](https://realmofra.com)
- **Repository**: [GitHub](https://github.com/realmofra/elysium_descent)
- **Dojo Framework**: [Dojo Book](https://book.dojoengine.org/)
- **Bevy Engine**: [Bevy Website](https://bevyengine.org/)
- **Starknet**: [Starknet Docs](https://docs.starknet.io/)

---

**Built with ❤️ using Rust, Bevy, and Cairo on Starknet**
