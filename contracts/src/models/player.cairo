use starknet::ContractAddress;
use super::super::types::game_types::{PlayerClass, PlayerClassTrait};

// Simplified player stats model for current implementation
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

// Helper functions for Player - explicitly uses PlayerClass
#[generate_trait]
impl PlayerImpl of PlayerTrait {
    fn apply_class_bonuses(ref self: Player, player_class: PlayerClass) {
        // Apply class-specific bonuses to stats
        let health_bonus = player_class.get_health_bonus();
        self.max_health += health_bonus;
        self.health += health_bonus;
    }

    fn get_experience_gain_with_class(
        self: @Player, base_exp: u32, player_class: PlayerClass,
    ) -> u32 {
        let multiplier = player_class.get_experience_multiplier();
        base_exp * multiplier / 100
    }

    fn is_alive(self: @Player) -> bool {
        *self.health > 0
    }

    fn can_level_up(self: @Player) -> bool {
        // Simple level up formula: need level * 100 experience
        *self.experience >= *self.level * 100
    }
}

