use elysium_descent::elements::base::{ItemElement, ElementEffect};
use elysium_descent::models::player::{Player};
use elysium_descent::helpers::store::{Store, StoreTrait};
use core::cmp;

#[derive(Drop, Serde)]
pub struct HealthPotion {
    pub base_heal: u32,
    pub quality_multiplier: u8,
}

pub impl HealthPotionDefault of Default<HealthPotion> {
    fn default() -> HealthPotion {
        HealthPotion {
            base_heal: 25,
            quality_multiplier: 1,
        }
    }
}

impl HealthPotionItemElement of ItemElement<HealthPotion> {
    fn get_name(self: @HealthPotion) -> ByteArray {
        "Health Potion"
    }

    fn get_description(self: @HealthPotion) -> ByteArray {
        let heal_amount = *self.base_heal * (*self.quality_multiplier).into();
        format!("Restores {} health points", heal_amount)
    }

    fn get_base_value(self: @HealthPotion) -> u32 {
        *self.base_heal * (*self.quality_multiplier).into()
    }

    fn can_use(self: @HealthPotion, player: @Player) -> bool {
        player.health < player.max_health
    }

    fn apply_effect(self: @HealthPotion, ref store: Store, ref player: Player, quantity: u32) -> ElementEffect {
        if !self.can_use(@player) {
            return ElementEffect {
                success: false,
                message: "Already at full health",
                value_changed: 0,
            };
        }

        let heal_amount = self.get_base_value() * quantity;
        let old_health = player.health;
        let new_health = cmp::min(
            player.health + heal_amount,
            player.max_health
        );
        
        player.health = new_health;
        let actual_healed = new_health - old_health;

        store.set_player(player);

        ElementEffect {
            success: true,
            message: format!("Healed for {} health", actual_healed),
            value_changed: actual_healed,
        }
    }

    fn get_cooldown_seconds(self: @HealthPotion) -> u64 {
        2
    }

    fn get_stack_limit(self: @HealthPotion) -> u32 {
        99
    }
}

#[cfg(test)]
mod tests {
    use super::{HealthPotion, HealthPotionDefault, ItemElement};
    use elysium_descent::models::player::{Player};
    use elysium_descent::helpers::store::{StoreTrait};
    use elysium_descent::tests::setup::{spawn};

    fn create_test_player() -> Player {
        Player {
            player: starknet::contract_address_const::<0x1>(),
            health: 50,
            max_health: 100,
            level: 1,
            experience: 0,
            items_collected: 0,
        }
    }

    #[test]
    fn test_health_potion_properties() {
        let potion = HealthPotionDefault::default();
        
        assert_eq!(potion.get_name(), "Health Potion");
        assert_eq!(potion.get_base_value(), 25);
        assert_eq!(potion.get_cooldown_seconds(), 2);
        assert_eq!(potion.get_stack_limit(), 99);
    }

    #[test]
    fn test_can_use_health_potion() {
        let potion = HealthPotionDefault::default();
        let mut player = create_test_player();
        
        assert!(potion.can_use(@player), "Should be able to use when damaged");
        
        player.health = player.max_health;
        assert!(!potion.can_use(@player), "Should not be able to use at full health");
    }

    #[test]
    fn test_apply_health_potion_effect() {
        let (world, _systems, _context) = spawn();
        let mut store = StoreTrait::new(world);
        
        let potion = HealthPotionDefault::default();
        let mut player = create_test_player();
        
        let initial_health = player.health;
        let effect = potion.apply_effect(ref store, ref player, 1);
        
        assert!(effect.success, "Effect should be successful");
        assert_eq!(effect.value_changed, 25, "Should heal for 25");
        assert_eq!(player.health, initial_health + 25, "Health should increase");
    }

    #[test]
    fn test_health_potion_overheal_prevention() {
        let (world, _systems, _context) = spawn();
        let mut store = StoreTrait::new(world);
        
        let potion = HealthPotionDefault::default();
        let mut player = create_test_player();
        player.health = 90;
        
        let effect = potion.apply_effect(ref store, ref player, 1);
        
        assert!(effect.success, "Effect should be successful");
        assert_eq!(effect.value_changed, 10, "Should only heal to max");
        assert_eq!(player.health, 100, "Health should be at max");
    }

    #[test]
    fn test_health_potion_multiple_quantity() {
        let (world, _systems, _context) = spawn();
        let mut store = StoreTrait::new(world);
        
        let potion = HealthPotionDefault::default();
        let mut player = create_test_player();
        player.health = 10;
        
        let effect = potion.apply_effect(ref store, ref player, 3);
        
        assert!(effect.success, "Effect should be successful");
        assert_eq!(effect.value_changed, 75, "Should heal for 75 (25 * 3)");
        assert_eq!(player.health, 85, "Health should be 85");
    }

    #[test]
    fn test_quality_multiplier() {
        let (world, _systems, _context) = spawn();
        let mut store = StoreTrait::new(world);
        
        let superior_potion = HealthPotion {
            base_heal: 25,
            quality_multiplier: 2,
        };
        
        let mut player = create_test_player();
        let effect = superior_potion.apply_effect(ref store, ref player, 1);
        
        assert_eq!(effect.value_changed, 50, "Should heal for 50 (25 * 2)");
    }
}