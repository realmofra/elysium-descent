use elysium_descent::elements::base::{ItemElement, ElementEffect};
use elysium_descent::models::player::{Player};
use elysium_descent::helpers::store::{Store, StoreTrait};

#[derive(Drop, Serde)]
pub struct Book {
    pub teleport_range: u32,
    pub experience_cost: u32 // Cost in experience points instead of stamina
}

pub impl BookDefault of Default<Book> {
    fn default() -> Book {
        Book { teleport_range: 10, experience_cost: 10 // Small XP cost for teleportation
        }
    }
}

impl BookItemElement of ItemElement<Book> {
    fn get_name(self: @Book) -> ByteArray {
        "Teleport Scroll"
    }

    fn get_description(self: @Book) -> ByteArray {
        format!(
            "Teleports you up to {} tiles away. Costs {} experience",
            *self.teleport_range,
            *self.experience_cost,
        )
    }

    fn get_base_value(self: @Book) -> u32 {
        *self.teleport_range
    }

    fn can_use(self: @Book, player: @Player) -> bool {
        player.experience >= self.experience_cost
    }

    fn apply_effect(
        self: @Book, ref store: Store, ref player: Player, quantity: u32,
    ) -> ElementEffect {
        if !self.can_use(@player) {
            return ElementEffect {
                success: false,
                message: format!("Not enough experience. Need {} XP", *self.experience_cost),
                value_changed: 0,
            };
        }

        // For now, just consume experience. Actual teleportation would require position data
        // and would be handled by the game logic layer
        let total_exp_cost = *self.experience_cost * quantity;

        if player.experience < total_exp_cost {
            return ElementEffect {
                success: false,
                message: format!("Not enough experience for {} scrolls", quantity),
                value_changed: 0,
            };
        }

        player.experience -= total_exp_cost;
        store.set_player(player);

        ElementEffect {
            success: true,
            message: format!("Ready to teleport! Used {} experience", total_exp_cost),
            value_changed: total_exp_cost,
        }
    }

    fn get_cooldown_seconds(self: @Book) -> u64 {
        10
    }

    fn get_stack_limit(self: @Book) -> u32 {
        10
    }
}

#[cfg(test)]
mod tests {
    use super::{BookDefault, ItemElement};
    use elysium_descent::models::player::{Player};
    use elysium_descent::helpers::store::{StoreTrait};
    use elysium_descent::tests::setup::{spawn};

    fn create_test_player() -> Player {
        Player {
            player: starknet::contract_address_const::<0x1>(),
            health: 100,
            max_health: 100,
            level: 1,
            experience: 100,
            items_collected: 0,
        }
    }

    #[test]
    fn test_teleport_scroll_properties() {
        let scroll = BookDefault::default();

        assert_eq!(scroll.get_name(), "Teleport Scroll");
        assert_eq!(scroll.get_base_value(), 10); // teleport range
        assert_eq!(scroll.get_cooldown_seconds(), 10);
        assert_eq!(scroll.get_stack_limit(), 10);
    }

    #[test]
    fn test_can_use_teleport_scroll() {
        let scroll = BookDefault::default();
        let mut player = create_test_player();

        assert!(scroll.can_use(@player), "Should be able to use with enough experience");

        player.experience = 5;
        assert!(!scroll.can_use(@player), "Should not be able to use without enough experience");
    }

    #[test]
    fn test_teleport_scroll_effect() {
        let (world, _systems, _context) = spawn();
        let mut store = StoreTrait::new(world);

        let scroll = BookDefault::default();
        let mut player = create_test_player();

        let initial_exp = player.experience;
        let effect = scroll.apply_effect(ref store, ref player, 1);

        assert!(effect.success, "Effect should be successful");
        assert_eq!(effect.value_changed, 10, "Should use 10 experience");
        assert_eq!(player.experience, initial_exp - 10, "Experience should decrease");
    }

    #[test]
    fn test_teleport_scroll_insufficient_experience() {
        let (world, _systems, _context) = spawn();
        let mut store = StoreTrait::new(world);

        let scroll = BookDefault::default();
        let mut player = create_test_player();
        player.experience = 5;

        let effect = scroll.apply_effect(ref store, ref player, 1);

        assert!(!effect.success, "Effect should fail");
        assert_eq!(player.experience, 5, "Experience should not change");
    }

    #[test]
    fn test_teleport_scroll_multiple_uses() {
        let (world, _systems, _context) = spawn();
        let mut store = StoreTrait::new(world);

        let scroll = BookDefault::default();
        let mut player = create_test_player();

        let effect = scroll.apply_effect(ref store, ref player, 3);

        assert!(effect.success);
        assert_eq!(effect.value_changed, 30, "Should use 30 experience (10 * 3)");
        assert_eq!(player.experience, 70, "Should have 70 experience left");
    }
}
