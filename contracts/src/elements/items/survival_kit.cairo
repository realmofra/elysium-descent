use elysium_descent::elements::base::{ItemElement, ElementEffect};
use elysium_descent::models::player::{Player};
use elysium_descent::helpers::store::{Store, StoreTrait};
use core::cmp;

#[derive(Drop, Serde)]
pub struct SurvivalKit {
    pub experience_bonus: u32,
    pub heal_amount: u32,
}

pub impl SurvivalKitDefault of Default<SurvivalKit> {
    fn default() -> SurvivalKit {
        SurvivalKit {
            experience_bonus: 50,
            heal_amount: 20,
        }
    }
}

impl SurvivalKitItemElement of ItemElement<SurvivalKit> {
    fn get_name(self: @SurvivalKit) -> ByteArray {
        "Survival Kit"
    }

    fn get_description(self: @SurvivalKit) -> ByteArray {
        format!("Grants {} XP and restores {} health", *self.experience_bonus, *self.heal_amount)
    }

    fn get_base_value(self: @SurvivalKit) -> u32 {
        *self.experience_bonus
    }

    fn can_use(self: @SurvivalKit, player: @Player) -> bool {
        player.health < player.max_health
    }

    fn apply_effect(self: @SurvivalKit, ref store: Store, ref player: Player, quantity: u32) -> ElementEffect {
        let mut total_restored = 0;
        
        // Apply experience bonus
        let exp_gained = *self.experience_bonus * quantity;
        player.experience += exp_gained;
        
        // Restore health
        let old_health = player.health;
        let heal_total = *self.heal_amount * quantity;
        player.health = cmp::min(
            player.health + heal_total,
            player.max_health
        );
        let health_restored = player.health - old_health;
        total_restored += health_restored;

        store.set_player(player);

        ElementEffect {
            success: true,
            message: format!("Gained {} XP and restored {} health", exp_gained, health_restored),
            value_changed: total_restored + exp_gained,
        }
    }

    fn get_cooldown_seconds(self: @SurvivalKit) -> u64 {
        5
    }

    fn get_stack_limit(self: @SurvivalKit) -> u32 {
        20
    }
}

#[cfg(test)]
mod tests {
    use super::{SurvivalKitDefault, ItemElement};
    use elysium_descent::models::player::{Player};
    use elysium_descent::helpers::store::{StoreTrait};
    use elysium_descent::tests::setup::{spawn};

    fn create_test_player() -> Player {
        Player {
            player: starknet::contract_address_const::<0x1>(),
            health: 50,
            max_health: 100,
            level: 1,
            experience: 100,
            items_collected: 0,
        }
    }

    #[test]
    fn test_survival_kit_properties() {
        let kit = SurvivalKitDefault::default();
        
        assert_eq!(kit.get_name(), "Survival Kit");
        assert_eq!(kit.get_base_value(), 50); // experience bonus
        assert_eq!(kit.get_cooldown_seconds(), 5);
        assert_eq!(kit.get_stack_limit(), 20);
    }

    #[test]
    fn test_survival_kit_effect() {
        let (world, _systems, _context) = spawn();
        let mut store = StoreTrait::new(world);
        
        let kit = SurvivalKitDefault::default();
        let mut player = create_test_player();
        
        let initial_exp = player.experience;
        let initial_health = player.health;
        
        let effect = kit.apply_effect(ref store, ref player, 1);
        
        assert!(effect.success, "Effect should be successful");
        assert_eq!(player.experience, initial_exp + 50, "Should gain 50 XP");
        assert_eq!(player.health, initial_health + 20, "Should heal 20");
    }

    #[test]
    fn test_survival_kit_multiple_quantity() {
        let (world, _systems, _context) = spawn();
        let mut store = StoreTrait::new(world);
        
        let kit = SurvivalKitDefault::default();
        let mut player = create_test_player();
        player.experience = 0;
        player.health = 10;
        
        let effect = kit.apply_effect(ref store, ref player, 2);
        
        assert!(effect.success);
        assert_eq!(player.experience, 100, "Should gain 100 XP (50 * 2)");
        assert_eq!(player.health, 50, "Should heal 40 (20 * 2)");
    }

    #[test]
    fn test_survival_kit_capped_restore() {
        let (world, _systems, _context) = spawn();
        let mut store = StoreTrait::new(world);
        
        let kit = SurvivalKitDefault::default();
        let mut player = create_test_player();
        player.health = 90;
        
        let effect = kit.apply_effect(ref store, ref player, 1);
        
        assert!(effect.success);
        assert_eq!(player.health, 100, "Should cap at max health");
    }
}