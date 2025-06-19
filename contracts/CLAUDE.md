# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Structure

This is a Dojo game engine project written in Cairo for StarkNet. The project follows the standard Dojo structure:

- `src/lib.cairo` - Main module declarations
- `src/models.cairo` - Game state models and data structures 
- `src/systems/actions.cairo` - Game logic and player actions
- `src/tests/` - Test files
- `Scarb.toml` - Cairo package configuration
- `dojo_dev.toml` / `dojo_release.toml` - Dojo configuration files
- `manifest_dev.json` - Generated deployment manifest

## Development Commands

### Local Development
```bash
# Start Katana (StarkNet devnet) - must be running first
katana --dev --dev.no-fee

# Build the contracts
sozo build

# Inspect the world state
sozo inspect

# Deploy/migrate contracts
sozo migrate

# Start Torii indexer (replace <WORLD_ADDRESS> with deployed world address)
torii --world <WORLD_ADDRESS> --http.cors_origins "*"
```

### Docker Development
```bash
# Start the full stack
docker compose up
```

### Testing
```bash
# Run tests
sozo test
```

## Architecture

### Dojo Framework
This project uses Dojo v1.5.0, a provable game engine for StarkNet. Key concepts:

- **Models**: Define game state data structures (Position, Moves, Direction, etc.)
- **Systems**: Contain game logic and state transitions (actions.cairo)
- **World**: Central registry that manages all models and systems
- **Events**: Emit game state changes for indexing

### Game Models
- `Position`: Player position with Vec2 coordinates
- `Moves`: Player movement state (remaining moves, last direction, can_move flag)
- `Direction`: Enum for movement directions (Left, Right, Up, Down)
- `Vec2`: 2D vector with x,y coordinates

### Game Systems
- `spawn()`: Initialize a new player at position (10,10) with 100 moves
- `move(direction)`: Move player in specified direction, consuming one move

### Key Files
- `src/models.cairo:38-44` - Direction enum definition
- `src/systems/actions.cairo:30-56` - Player spawn logic
- `src/systems/actions.cairo:58-95` - Player movement logic
- `src/systems/actions.cairo:108-119` - Position calculation helper

## Configuration
- Cairo version: 2.10.1
- Dojo version: v1.5.0
- Project name: elysium_descent
- World namespace: "dojo_starter"