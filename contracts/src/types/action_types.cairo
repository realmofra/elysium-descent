use starknet::ContractAddress;
use super::item_types::{ItemType};

// Game Actions - following Shinigami's entry point pattern
#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub enum GameAction {
    // Inventory Actions
    PickupItem: PickupAction,
    DropItem: DropAction,
    UseItem: UseAction,
    TransferItem: TransferAction,
    
    // Game Management Actions
    CreateGame,
    StartLevel: LevelAction,
    PauseGame,
    ResumeGame,
    EndGame,
    
    // Player Actions
    Move: MoveAction,
    Interact: InteractAction,
    Rest,
}

// Specific action data structures
#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub struct PickupAction {
    pub game_id: u32,
    pub item_id: u32,
    pub world_x: u32,
    pub world_y: u32,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub struct DropAction {
    pub item_type: ItemType,
    pub quantity: u32,
    pub world_x: u32,
    pub world_y: u32,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub struct UseAction {
    pub item_type: ItemType,
    pub quantity: u32,
    pub target: Option<ContractAddress>, // For items that target other players
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub struct TransferAction {
    pub to_player: ContractAddress,
    pub item_type: ItemType,
    pub quantity: u32,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub struct LevelAction {
    pub game_id: u32,
    pub level: u32,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub struct MoveAction {
    pub from_x: u32,
    pub from_y: u32,
    pub to_x: u32,
    pub to_y: u32,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub struct InteractAction {
    pub target_type: InteractionTarget,
    pub target_id: u32,
    pub world_x: u32,
    pub world_y: u32,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub enum InteractionTarget {
    Item,
    NPC,
    Environment,
    Player,
}

// Action result types
#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub enum ActionResult {
    Success,
    Failed: ActionError,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub enum ActionError {
    InvalidGame,
    InvalidPlayer,
    InvalidItem,
    InventoryFull,
    InsufficientQuantity,
    ItemNotFound,
    PermissionDenied,
    GameNotActive,
    LevelNotActive,
    InvalidPosition,
    CooldownActive,
    InvalidTarget,
}

// Conversion traits
impl GameActionIntoFelt252 of Into<GameAction, felt252> {
    fn into(self: GameAction) -> felt252 {
        match self {
            GameAction::PickupItem(_) => 1,
            GameAction::DropItem(_) => 2,
            GameAction::UseItem(_) => 3,
            GameAction::TransferItem(_) => 4,
            GameAction::CreateGame => 10,
            GameAction::StartLevel(_) => 11,
            GameAction::PauseGame => 12,
            GameAction::ResumeGame => 13,
            GameAction::EndGame => 14,
            GameAction::Move(_) => 20,
            GameAction::Interact(_) => 21,
            GameAction::Rest => 22,
        }
    }
}

impl ActionResultIntoFelt252 of Into<ActionResult, felt252> {
    fn into(self: ActionResult) -> felt252 {
        match self {
            ActionResult::Success => 1,
            ActionResult::Failed(_) => 0,
        }
    }
}

impl ActionErrorIntoFelt252 of Into<ActionError, felt252> {
    fn into(self: ActionError) -> felt252 {
        match self {
            ActionError::InvalidGame => 1,
            ActionError::InvalidPlayer => 2,
            ActionError::InvalidItem => 3,
            ActionError::InventoryFull => 4,
            ActionError::InsufficientQuantity => 5,
            ActionError::ItemNotFound => 6,
            ActionError::PermissionDenied => 7,
            ActionError::GameNotActive => 8,
            ActionError::LevelNotActive => 9,
            ActionError::InvalidPosition => 10,
            ActionError::CooldownActive => 11,
            ActionError::InvalidTarget => 12,
        }
    }
}

// Action validation traits
#[generate_trait]
pub impl GameActionImpl of GameActionTrait {
    fn requires_active_game(self: @GameAction) -> bool {
        match self {
            GameAction::CreateGame => false,
            _ => true,
        }
    }
    
    fn requires_valid_position(self: @GameAction) -> bool {
        match self {
            GameAction::PickupItem(_) | GameAction::DropItem(_) | GameAction::Move(_) | GameAction::Interact(_) => true,
            _ => false,
        }
    }
    
    fn modifies_inventory(self: @GameAction) -> bool {
        match self {
            GameAction::PickupItem(_) | GameAction::DropItem(_) | GameAction::UseItem(_) | GameAction::TransferItem(_) => true,
            _ => false,
        }
    }
    
    fn get_cooldown_seconds(self: @GameAction) -> u64 {
        match self {
            GameAction::UseItem(_) => 2,
            GameAction::PickupItem(_) => 1,
            GameAction::Move(_) => 1,
            _ => 0,
        }
    }
}