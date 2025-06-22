# Advanced Cairo Programming Patterns for Shinigami Design System

This document outlines advanced Cairo programming patterns, architectural principles, and best practices specifically relevant to the Shinigami design system and blockchain game development on Starknet.

## 1. Trait-Based Design Patterns in Cairo

### Core Trait Philosophy
Cairo emphasizes **composition over inheritance**, using traits to define shared behavior across different types. Unlike Solidity's inheritance model, Cairo champions composability through trait-based design.

### Advanced Trait Patterns

#### Default Implementation Pattern
```cairo
trait Summary {
    fn summarize_author(self: @Self) -> ByteArray;
    
    // Default implementation that can be overridden
    fn summarize(self: @Self) -> ByteArray {
        format!("(Read more from {}...)", self.summarize_author())
    }
}
```

#### Trait Composition Pattern
```cairo
trait Movable {
    fn move_to(ref self: Self, position: Position);
}

trait Attackable {
    fn attack(ref self: Self, target: EntityId) -> AttackResult;
}

// Compose traits for complex behaviors
trait Combatant: Movable + Attackable {
    fn combat_action(ref self: Self, action: CombatAction);
}
```

#### Generic Trait Constraints
```cairo
trait GameComponent<T> {
    fn serialize(self: @Self) -> Span<felt252>;
    fn deserialize(data: Span<felt252>) -> T;
    fn component_id() -> ComponentId;
}
```

## 2. Component and Module Organization Best Practices

### Dojo ECS Architecture

#### Model Design Patterns
```cairo
// Small, focused models following ECS principles
#[derive(Drop, Serde)]
#[dojo::model]
struct Position {
    #[key]
    entity_id: u32,
    x: u32,
    y: u32,
    z: u32
}

#[derive(Drop, Serde)]
#[dojo::model] 
struct Health {
    #[key]
    entity_id: u32,
    current: u32,
    maximum: u32
}

#[derive(Drop, Serde)]
#[dojo::model]
struct Inventory {
    #[key]
    entity_id: u32,
    items: Array<ItemId>,
    capacity: u32
}
```

#### System Organization Pattern
```cairo
#[dojo::contract]
mod movement_system {
    use super::{Position, Velocity};
    
    #[external(v0)]
    fn move_entity(
        ref world: IWorldDispatcher,
        entity_id: u32,
        direction: Direction
    ) {
        // Validate movement
        let position = get!(world, entity_id, (Position));
        let new_position = calculate_new_position(position, direction);
        
        // Update state
        set!(world, (Position {
            entity_id,
            x: new_position.x,
            y: new_position.y,
            z: new_position.z
        }));
        
        // Emit event
        emit!(world, MovementEvent { entity_id, from: position, to: new_position });
    }
}
```

### Module Composition Patterns

#### Component-Based Architecture
```cairo
// Use components instead of inheritance
#[derive(Drop, Serde)]
#[dojo::model]
struct CharacterCore {
    #[key]
    entity_id: u32,
    name: ByteArray,
    level: u32
}

#[derive(Drop, Serde)] 
#[dojo::model]
struct PlayerData {
    #[key]
    entity_id: u32,
    experience: u64,
    skill_points: u32
}

// Compose functionality through multiple models
fn get_character_info(world: IWorldDispatcher, entity_id: u32) -> CharacterInfo {
    let core = get!(world, entity_id, (CharacterCore));
    let player_data = get!(world, entity_id, (PlayerData));
    let position = get!(world, entity_id, (Position));
    
    CharacterInfo { core, player_data, position }
}
```

## 3. State Management and Persistence Patterns

### Efficient Storage Patterns

#### Key-Value Store Pattern
```cairo
// Models act as key-value stores
#[derive(Drop, Serde)]
#[dojo::model]
struct GameState {
    #[key]
    game_id: u32,
    #[key] 
    state_type: StateType,
    data: Span<felt252>
}

// Nested storage for complex data
#[derive(Drop, Serde)]
#[dojo::model]
struct WorldMap {
    #[key]
    world_id: u32,
    #[key]
    chunk_x: u32,
    #[key]
    chunk_y: u32,
    terrain_data: TerrainChunk
}
```

#### State Compression Pattern
```cairo
// Compress game state for efficient storage
#[derive(Drop, Serde)]
#[dojo::model]
struct CompressedPlayerState {
    #[key]
    player_id: u32,
    // Pack multiple values into single felt252
    packed_stats: felt252, // Contains level, hp, mp, etc.
    packed_position: felt252, // Contains x, y, z coordinates
    items_hash: felt252 // Hash of inventory contents
}

fn unpack_stats(packed: felt252) -> PlayerStats {
    // Bit manipulation to extract individual values
    let level = (packed / 0x1000000) % 0x100;
    let hp = (packed / 0x10000) % 0x100;
    let mp = (packed / 0x100) % 0x100;
    PlayerStats { level, hp, mp }
}
```

### Recursive Proof Patterns
```cairo
// Chain proofs together for complex game states
trait GameProof {
    fn generate_proof(self: @Self) -> GameStateProof;
    fn verify_transition(
        old_state: @Self, 
        new_state: @Self, 
        action: GameAction
    ) -> bool;
}

// Use recursion for turn-based games
fn process_game_turns(
    initial_state: GameState,
    turns: Array<GameTurn>
) -> GameState {
    if turns.is_empty() {
        return initial_state;
    }
    
    let current_turn = turns.pop_front().unwrap();
    let new_state = apply_turn(initial_state, current_turn);
    process_game_turns(new_state, turns)
}
```

## 4. Event-Driven Architecture in Cairo/Starknet

### Event Design Patterns

#### Structured Event System
```cairo
#[derive(Drop, starknet::Event)]
struct GameEvent {
    #[key]
    event_type: EventType,
    #[key]
    entity_id: u32,
    timestamp: u64,
    data: Span<felt252>
}

#[derive(Drop, starknet::Event)]
struct CombatEvent {
    #[key]
    attacker_id: u32,
    #[key]
    target_id: u32,
    damage: u32,
    combat_type: CombatType
}
```

#### Event Sourcing Pattern
```cairo
// Store all state changes as events
#[derive(Drop, Serde)]
#[dojo::model]
struct EventLog {
    #[key]
    sequence_id: u64,
    event_type: EventType,
    entity_id: u32,
    data: EventData,
    timestamp: u64
}

// Rebuild state from events
fn rebuild_entity_state(
    world: IWorldDispatcher,
    entity_id: u32,
    up_to_sequence: u64
) -> EntityState {
    let events = query_events(world, entity_id, up_to_sequence);
    let mut state = EntityState::default();
    
    for event in events {
        state = apply_event(state, event);
    }
    
    state
}
```

## 5. Validation and Error Handling Patterns

### Robust Error Handling

#### Assert and Panic Patterns
```cairo
// Validation using assert for conditions
fn validate_move(current_pos: Position, target_pos: Position) {
    assert(
        distance(current_pos, target_pos) <= MAX_MOVE_DISTANCE,
        'Move distance too far'
    );
    assert(
        is_valid_position(target_pos),
        'Invalid target position'
    );
}

// Formatted error messages
fn transfer_item(
    ref inventory: Inventory,
    item_id: ItemId,
    quantity: u32
) {
    assert!(
        inventory.contains(item_id),
        "Item {} not found in inventory",
        item_id
    );
    assert!(
        inventory.get_quantity(item_id) >= quantity,
        "Insufficient quantity: have {}, need {}",
        inventory.get_quantity(item_id),
        quantity
    );
}
```

#### Result-Based Error Handling  
```cairo
// Use Result for recoverable errors
enum GameError {
    InvalidMove,
    InsufficientResources,
    InvalidTarget,
    CooldownActive
}

fn attempt_action(
    world: IWorldDispatcher,
    player_id: u32,
    action: GameAction
) -> Result<ActionResult, GameError> {
    // Validate preconditions
    let player_state = get!(world, player_id, (PlayerState));
    
    if !can_perform_action(player_state, action) {
        return Result::Err(GameError::CooldownActive);
    }
    
    // Execute action
    match action {
        GameAction::Move(direction) => execute_move(world, player_id, direction),
        GameAction::Attack(target) => execute_attack(world, player_id, target),
        _ => Result::Err(GameError::InvalidMove)
    }
}
```

#### Circuit Breaker Pattern
```cairo
#[derive(Drop, Serde)]
#[dojo::model]
struct SystemHealth {
    #[key]
    system_id: SystemId,
    failure_count: u32,
    last_failure: u64,
    is_circuit_open: bool
}

fn execute_with_circuit_breaker<T>(
    world: IWorldDispatcher,
    system_id: SystemId,
    operation: fn() -> Result<T, GameError>
) -> Result<T, GameError> {
    let health = get!(world, system_id, (SystemHealth));
    
    if health.is_circuit_open {
        return Result::Err(GameError::SystemUnavailable);
    }
    
    match operation() {
        Result::Ok(result) => {
            reset_circuit_breaker(world, system_id);
            Result::Ok(result)
        },
        Result::Err(error) => {
            increment_failure_count(world, system_id);
            Result::Err(error)
        }
    }
}
```

## 6. Interface Design and Contract Composability

### Dispatcher Pattern
```cairo
// Define interfaces for cross-contract calls
#[starknet::interface]
trait IGameSystem<TContractState> {
    fn process_action(
        ref self: TContractState,
        player_id: u32,
        action: GameAction
    ) -> ActionResult;
    
    fn get_game_state(
        self: @TContractState,
        game_id: u32
    ) -> GameState;
}

// Implement composable contracts
#[starknet::contract]
mod game_controller {
    use super::IGameSystemDispatcher;
    
    #[storage]
    struct Storage {
        movement_system: ContractAddress,
        combat_system: ContractAddress,
        inventory_system: ContractAddress
    }
    
    #[external(v0)]
    fn delegate_action(
        ref self: ContractState,
        action: GameAction
    ) -> ActionResult {
        match action {
            GameAction::Move(_) => {
                let system = IGameSystemDispatcher { 
                    contract_address: self.movement_system.read() 
                };
                system.process_action(action)
            },
            GameAction::Attack(_) => {
                let system = IGameSystemDispatcher {
                    contract_address: self.combat_system.read()
                };
                system.process_action(action)
            }
        }
    }
}
```

### Component Composition Pattern
```cairo
// Use #[compose] for component composition
#[starknet::contract]
mod game_entity {
    #[storage]
    struct Storage {
        #[compose]
        position: position_component::Storage,
        #[compose] 
        health: health_component::Storage,
        #[compose]
        inventory: inventory_component::Storage
    }
    
    // Automatic composition of component interfaces
    #[external(v0)]
    impl PositionImpl = position_component::PositionImpl<ContractState>;
    #[external(v0)]
    impl HealthImpl = health_component::HealthImpl<ContractState>;
    #[external(v0)]
    impl InventoryImpl = inventory_component::InventoryImpl<ContractState>;
}
```

## 7. Cairo-Specific Game Development Patterns

### Gas-Optimized Data Structures
```cairo
// Pack data efficiently for gas optimization
#[derive(Drop, Serde)]
struct PackedEntity {
    // Use felt252 to pack multiple small values
    packed_data: felt252, // level (8 bits) + hp (16 bits) + mp (16 bits) + flags (8 bits)
    position: felt252,    // x (16 bits) + y (16 bits) + z (16 bits)
    inventory_hash: felt252 // Hash of inventory contents
}

// Bit manipulation helpers
mod bit_utils {
    fn pack_stats(level: u8, hp: u16, mp: u16, flags: u8) -> felt252 {
        level.into() * 0x1000000 + hp.into() * 0x10000 + mp.into() * 0x100 + flags.into()
    }
    
    fn unpack_level(packed: felt252) -> u8 {
        ((packed / 0x1000000) % 0x100).try_into().unwrap()
    }
}
```

### Merkle Tree Verification Pattern
```cairo
// Verify game state using merkle proofs
fn verify_inventory_state(
    claimed_items: Array<Item>,
    merkle_root: felt252,
    proof: Array<felt252>
) -> bool {
    let computed_hash = compute_merkle_leaf(claimed_items);
    verify_merkle_proof(computed_hash, merkle_root, proof)
}

// Batch operations for efficiency
fn batch_update_entities(
    world: IWorldDispatcher,
    updates: Array<EntityUpdate>
) {
    let mut position_updates = ArrayTrait::new();
    let mut health_updates = ArrayTrait::new();
    
    // Group updates by type
    for update in updates {
        match update {
            EntityUpdate::Position(pos_update) => position_updates.append(pos_update),
            EntityUpdate::Health(health_update) => health_updates.append(health_update)
        }
    }
    
    // Apply batched updates
    batch_set_positions(world, position_updates);
    batch_set_health(world, health_updates);
}
```

## 8. Model, Component, and System Structure in Cairo

### Hierarchical Model Organization
```cairo
// Base model traits
trait BaseModel {
    fn get_id(self: @Self) -> u32;
    fn serialize(self: @Self) -> Span<felt252>;
}

// Specialized models
#[derive(Drop, Serde)]
#[dojo::model]
struct BaseEntity {
    #[key]
    id: u32,
    entity_type: EntityType,
    created_at: u64
}

#[derive(Drop, Serde)]
#[dojo::model]
struct Character {
    #[key]
    id: u32,
    name: ByteArray,
    class: CharacterClass
}

#[derive(Drop, Serde)]
#[dojo::model]
struct NPC {
    #[key]
    id: u32,
    dialogue_tree: DialogueTreeId,
    ai_behavior: AIBehaviorType
}
```

### System Dependencies and Injection
```cairo
// Define system interfaces
#[starknet::interface]
trait IMovementSystem<T> {
    fn move_entity(ref self: T, entity_id: u32, direction: Direction);
}

#[starknet::interface]
trait ICombatSystem<T> {
    fn attack_entity(ref self: T, attacker: u32, target: u32);
}

// Game manager that coordinates systems
#[dojo::contract]
mod game_manager {
    #[storage]
    struct Storage {
        movement_system: ContractAddress,
        combat_system: ContractAddress
    }
    
    #[external(v0)]
    fn process_turn(
        ref self: ContractState,
        player_id: u32,
        actions: Array<GameAction>
    ) {
        for action in actions {
            match action {
                GameAction::Move(direction) => {
                    let movement = IMovementSystemDispatcher {
                        contract_address: self.movement_system.read()
                    };
                    movement.move_entity(player_id, direction);
                },
                GameAction::Attack(target) => {
                    let combat = ICombatSystemDispatcher {
                        contract_address: self.combat_system.read()
                    };
                    combat.attack_entity(player_id, target);
                }
            }
        }
    }
}
```

## Key Architectural Principles

1. **Composability Over Inheritance**: Use traits and components instead of class hierarchies
2. **Small, Focused Models**: Keep models minimal and single-purpose following ECS principles  
3. **Event-Driven Communication**: Use events for loose coupling between systems
4. **Gas-Optimized Storage**: Pack data efficiently and use batch operations
5. **Robust Error Handling**: Combine assertions for invariants with Result types for recoverable errors
6. **Provable State Transitions**: Design systems to generate and verify cryptographic proofs
7. **Modular System Architecture**: Build systems that can be composed and upgraded independently

This pattern collection provides a foundation for building sophisticated, gas-efficient, and maintainable Cairo applications following the Shinigami design methodology.