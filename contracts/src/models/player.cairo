use starknet::ContractAddress;
use elysium_descent::types::game::{PlayerClass, PlayerClassTrait};

/// Core player model containing health, level, and progression data
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Player {
    #[key]
    pub player: ContractAddress,
    pub health: u32,
    pub max_health: u32,
    pub level: u32,
    pub experience: u32,
    pub items_collected: u32,
}

/// Player utility functions for class bonuses and progression calculations
#[generate_trait]
impl PlayerImpl of PlayerTrait {
    /// Applies class-specific stat bonuses to the player
    ///
    /// # Arguments
    /// * `player_class` - The player's chosen class specialization
    fn apply_class_bonuses(ref self: Player, player_class: PlayerClass) {
        let health_bonus = player_class.get_health_bonus();
        self.max_health += health_bonus;
        self.health += health_bonus;
    }

    /// Calculates experience gain with class-specific multipliers
    ///
    /// # Arguments
    /// * `base_exp` - Base experience amount before class bonuses
    /// * `player_class` - Player's class affecting experience gain
    ///
    /// # Returns
    /// Modified experience amount after applying class multiplier
    fn get_experience_gain_with_class(
        self: @Player, base_exp: u32, player_class: PlayerClass,
    ) -> u32 {
        let multiplier = player_class.get_experience_multiplier();
        base_exp * multiplier / 100
    }

    /// Checks if the player is currently alive
    ///
    /// # Returns
    /// `true` if player has health remaining, `false` otherwise
    fn is_alive(self: @Player) -> bool {
        *self.health > 0
    }

    /// Determines if player has sufficient experience to level up
    ///
    /// # Returns
    /// `true` if player meets level up requirements
    fn can_level_up(self: @Player) -> bool {
        *self.experience >= *self.level * 100
    }
}
