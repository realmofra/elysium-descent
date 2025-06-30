use starknet::ContractAddress;

// Game state enumeration covering all possible game lifecycle phases
#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub enum GameStatus {
    NotStarted,
    InProgress,
    Paused,
    Completed,
    Abandoned,
    Failed,
}

/// Gameplay mode variants offering different rule sets and objectives
#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub enum GameMode {
    /// Guided learning experience with enhanced rewards
    Tutorial,
    /// Balanced normal gameplay
    Standard,
    /// Permadeath mode with restricted resources
    Hardcore,
    /// Time-limited completion challenges
    Speedrun,
    /// Unlimited resources for experimentation
    Creative,
    /// Shared world state with multiple players
    Multiplayer,
}

// Challenge scaling levels affecting spawns and progression
#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub enum Difficulty {
    Easy,
    Normal,
    Hard,
    Nightmare,
}

/// Character specializations providing unique bonuses and playstyles
#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub enum PlayerClass {
    /// Balanced stats with bonus to item discovery
    Explorer,
    /// High health with resistance bonuses
    Survivor,
    /// Bonus experience and faster learning
    Scholar,
    /// Larger inventory with better loot chances
    Collector,
    /// Movement bonuses and time advantages
    Speedrunner,
}

/// Game configuration structure defining rules and parameters
#[derive(Clone, Drop, Serde, Introspect)]
pub struct GameConfig {
    pub mode: GameMode,
    pub difficulty: Difficulty,
    pub max_levels: u32,
    pub starting_health: u32,
    pub starting_inventory_slots: u32,
    pub permadeath_enabled: bool,
    pub time_limit_seconds: Option<u64>,
    /// Percentage multiplier where 100 = normal, 200 = double items
    pub item_spawn_multiplier: u32,
    pub experience_multiplier: u32,
    pub allow_trading: bool,
    pub max_players: u32,
}

// Player State Information
#[derive(Clone, Drop, Serde, Introspect)]
pub struct PlayerState {
    pub player: ContractAddress,
    pub class: PlayerClass,
    pub current_game_id: Option<u32>,
    pub is_alive: bool,
    pub last_action_timestamp: u64,
    pub total_games_played: u32,
    pub total_games_completed: u32,
    pub highest_level_reached: u32,
    pub total_items_collected: u32,
    pub total_playtime_seconds: u64,
}

// Level Progress Tracking
#[derive(Clone, Drop, Serde, Introspect)]
pub struct LevelProgress {
    pub game_id: u32,
    pub level: u32,
    pub started_at: u64,
    pub completed_at: Option<u64>,
    pub items_required: u32,
    pub items_collected: u32,
    pub bonus_objectives_completed: u32,
    pub total_bonus_objectives: u32,
    pub score: u32,
}

/// Type conversion implementations for storage and serialization
impl GameStatusIntoFelt252 of Into<GameStatus, felt252> {
    fn into(self: GameStatus) -> felt252 {
        match self {
            GameStatus::NotStarted => 0,
            GameStatus::InProgress => 1,
            GameStatus::Paused => 2,
            GameStatus::Completed => 3,
            GameStatus::Abandoned => 4,
            GameStatus::Failed => 5,
        }
    }
}

impl GameModeIntoFelt252 of Into<GameMode, felt252> {
    fn into(self: GameMode) -> felt252 {
        match self {
            GameMode::Tutorial => 1,
            GameMode::Standard => 2,
            GameMode::Hardcore => 3,
            GameMode::Speedrun => 4,
            GameMode::Creative => 5,
            GameMode::Multiplayer => 6,
        }
    }
}

impl DifficultyIntoFelt252 of Into<Difficulty, felt252> {
    fn into(self: Difficulty) -> felt252 {
        match self {
            Difficulty::Easy => 1,
            Difficulty::Normal => 2,
            Difficulty::Hard => 3,
            Difficulty::Nightmare => 4,
        }
    }
}

impl PlayerClassIntoFelt252 of Into<PlayerClass, felt252> {
    fn into(self: PlayerClass) -> felt252 {
        match self {
            PlayerClass::Explorer => 1,
            PlayerClass::Survivor => 2,
            PlayerClass::Scholar => 3,
            PlayerClass::Collector => 4,
            PlayerClass::Speedrunner => 5,
        }
    }
}

/// Game type utility traits for state validation and mode configuration
#[generate_trait]
pub impl GameStatusImpl of GameStatusTrait {
    fn is_active(self: @GameStatus) -> bool {
        match self {
            GameStatus::InProgress => true,
            _ => false,
        }
    }

    fn is_ended(self: @GameStatus) -> bool {
        match self {
            GameStatus::Completed | GameStatus::Abandoned | GameStatus::Failed => true,
            _ => false,
        }
    }

    fn can_pause(self: @GameStatus) -> bool {
        match self {
            GameStatus::InProgress => true,
            _ => false,
        }
    }

    fn can_resume(self: @GameStatus) -> bool {
        match self {
            GameStatus::Paused => true,
            _ => false,
        }
    }
}

#[generate_trait]
pub impl GameModeImpl of GameModeTrait {
    fn allows_death(self: @GameMode) -> bool {
        match self {
            GameMode::Hardcore => true,
            GameMode::Tutorial => false,
            _ => true,
        }
    }

    fn has_time_limit(self: @GameMode) -> bool {
        match self {
            GameMode::Speedrun => true,
            _ => false,
        }
    }

    fn allows_multiplayer(self: @GameMode) -> bool {
        match self {
            GameMode::Multiplayer => true,
            _ => false,
        }
    }

    fn get_default_config(self: @GameMode) -> GameConfig {
        match self {
            GameMode::Tutorial => GameConfig {
                mode: GameMode::Tutorial,
                difficulty: Difficulty::Easy,
                max_levels: 5,
                starting_health: 150,
                starting_inventory_slots: 20,
                permadeath_enabled: false,
                time_limit_seconds: Option::None,
                item_spawn_multiplier: 200,
                experience_multiplier: 300,
                allow_trading: false,
                max_players: 1,
            },
            GameMode::Standard => GameConfig {
                mode: GameMode::Standard,
                difficulty: Difficulty::Normal,
                max_levels: 50,
                starting_health: 100,
                starting_inventory_slots: 10,
                permadeath_enabled: false,
                time_limit_seconds: Option::None,
                item_spawn_multiplier: 100,
                experience_multiplier: 100,
                allow_trading: true,
                max_players: 1,
            },
            GameMode::Hardcore => GameConfig {
                mode: GameMode::Hardcore,
                difficulty: Difficulty::Hard,
                max_levels: 100,
                starting_health: 75,
                starting_inventory_slots: 8,
                permadeath_enabled: true,
                time_limit_seconds: Option::None,
                item_spawn_multiplier: 80,
                experience_multiplier: 150,
                allow_trading: false,
                max_players: 1,
            },
            GameMode::Speedrun => GameConfig {
                mode: GameMode::Speedrun,
                difficulty: Difficulty::Normal,
                max_levels: 20,
                starting_health: 100,
                starting_inventory_slots: 12,
                permadeath_enabled: false,
                time_limit_seconds: Option::Some(3600), // 1 hour
                item_spawn_multiplier: 150,
                experience_multiplier: 200,
                allow_trading: false,
                max_players: 1,
            },
            GameMode::Creative => GameConfig {
                mode: GameMode::Creative,
                difficulty: Difficulty::Easy,
                max_levels: 999,
                starting_health: 999,
                starting_inventory_slots: 100,
                permadeath_enabled: false,
                time_limit_seconds: Option::None,
                item_spawn_multiplier: 500,
                experience_multiplier: 1000,
                allow_trading: true,
                max_players: 1,
            },
            GameMode::Multiplayer => GameConfig {
                mode: GameMode::Multiplayer,
                difficulty: Difficulty::Normal,
                max_levels: 50,
                starting_health: 100,
                starting_inventory_slots: 15,
                permadeath_enabled: false,
                time_limit_seconds: Option::None,
                item_spawn_multiplier: 120,
                experience_multiplier: 100,
                allow_trading: true,
                max_players: 10,
            },
        }
    }
}

#[generate_trait]
pub impl PlayerClassImpl of PlayerClassTrait {
    fn get_health_bonus(self: @PlayerClass) -> u32 {
        match self {
            PlayerClass::Survivor => 25,
            PlayerClass::Explorer => 10,
            _ => 0,
        }
    }

    fn get_inventory_bonus(self: @PlayerClass) -> u32 {
        match self {
            PlayerClass::Collector => 10,
            PlayerClass::Explorer => 5,
            _ => 0,
        }
    }

    fn get_experience_multiplier(self: @PlayerClass) -> u32 {
        match self {
            PlayerClass::Scholar => 150,
            PlayerClass::Explorer => 110,
            _ => 100,
        }
    }

    fn get_item_find_bonus(self: @PlayerClass) -> u32 {
        match self {
            PlayerClass::Collector => 25,
            PlayerClass::Explorer => 15,
            _ => 0,
        }
    }

    fn get_movement_speed_bonus(self: @PlayerClass) -> u32 {
        match self {
            PlayerClass::Speedrunner => 50,
            PlayerClass::Explorer => 20,
            _ => 0,
        }
    }
}
