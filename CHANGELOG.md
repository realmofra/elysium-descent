# Changelog

All notable changes to Elysium Descent will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive architecture documentation
- Dojo integration guide with latest interface changes
- Enhanced README with project overview and quick start

### Changed
- Updated project documentation structure
- Improved development workflow guides

## [0.2.0] - 2024-01-XX (Current Development)

### Added
- **Enhanced Dojo Integration**: Updated systems to match current contract interface
- **Blockchain Item Mapping**: Added `BlockchainItemId` component for proper item tracking
- **Error Handling**: Comprehensive Bevy 0.16 Result-based error handling
- **Performance Optimization**: GPU-driven rendering improvements

### Changed
- **Contract Interface Alignment**: 
  - `pickup_item` now requires `game_id` and `item_id` parameters
  - Enhanced `create_game` with improved game ID handling
  - Updated all blockchain call systems for new interface
- **YarnSpinner Removal**: Streamlined development by removing dialogue system
  - Simplified book collection to direct interaction
  - Removed dialogue-related events and systems
  - Preserved dialogue assets for potential future re-integration
- **Item Collection Flow**: Enhanced item collection with blockchain integration
- **Data Parsing**: Improved blockchain model data extraction and validation

### Fixed
- Dojo system parameter passing for blockchain calls
- Game state synchronization between client and blockchain
- Error handling for missing blockchain item IDs
- Compilation issues after dependency updates

### Technical Details
- Updated `PickupItemEvent` to include `item_id` field
- Enhanced `CollectibleConfig` with optional blockchain ID mapping
- Improved `DojoSystemState` tracking and error reporting
- Added graceful fallbacks for blockchain integration failures

## [0.1.0] - 2024-01-XX (Initial Implementation)

### Added
- **Core Game Architecture**:
  - Bevy 0.16 ECS-based game client
  - Cairo smart contracts with Dojo v1.5.0
  - Shinigami design pattern implementation

- **Gameplay Features**:
  - 3D player character with smooth movement
  - Physics integration with Avian3D
  - Collectible items (books, health kits)
  - Basic inventory system
  - Audio system with background music

- **Blockchain Integration**:
  - Fully on-chain game logic
  - Player stats and inventory on Starknet
  - Game creation and management
  - Item collection with blockchain persistence
  - Dojo Bevy plugin for client-blockchain communication

- **Development Infrastructure**:
  - Comprehensive test suite (98 tests)
  - Docker development environment
  - Asset management system
  - Multi-screen state management

- **Technical Features**:
  - Bevy 0.16 Required Components system
  - Observer-based reactive programming
  - GPU-driven rendering optimizations
  - Result-based error handling

### Architecture Highlights
- **Client**: Rust + Bevy 0.16 with ECS architecture
- **Contracts**: Cairo with hierarchical Shinigami pattern
- **Integration**: Dojo framework for blockchain communication
- **Physics**: Avian3D for realistic movement and collision
- **UI**: Bevy Lunex for modern user interfaces

### Smart Contract Features
- Game instance management with unique IDs
- Player progression and statistics tracking
- Inventory management with item types
- Item spawning and collection mechanics
- Experience and leveling system
- Comprehensive event emission for indexing

### Development Features
- Local development with Katana blockchain
- Torii indexer for real-time state synchronization
- Hot reload for rapid development
- Comprehensive logging and debugging
- Asset pipeline for 3D models, audio, and textures

---

## Development Notes

### Versioning Strategy
- **Major versions** (x.0.0): Significant architectural changes or breaking API changes
- **Minor versions** (0.x.0): New features, enhancements, or notable improvements
- **Patch versions** (0.0.x): Bug fixes, documentation updates, or minor improvements

### Release Workflow
1. **Development**: Feature development on feature branches
2. **Testing**: Comprehensive testing of client and contracts
3. **Documentation**: Update relevant documentation
4. **Deployment**: Test on devnet before mainnet consideration
5. **Release**: Tag version and update changelog

### Contributing to Changelog
When contributing, please:
- Add entries to the "Unreleased" section
- Use the format: `- **Category**: Description`
- Include technical details for breaking changes
- Reference issue numbers where applicable
- Follow the established categorization (Added, Changed, Fixed, etc.)

---

*For detailed technical information, see [ARCHITECTURE.md](./ARCHITECTURE.md) and [DOJO_INTEGRATION_GUIDE.md](./DOJO_INTEGRATION_GUIDE.md)*