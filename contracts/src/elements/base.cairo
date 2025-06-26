use elysium_descent::models::player::{Player};
use elysium_descent::helpers::store::{Store};

#[derive(Drop, Serde)]
pub struct ElementEffect {
    pub success: bool,
    pub message: ByteArray,
    pub value_changed: u32,
}

pub trait ItemElement<T> {
    fn get_name(self: @T) -> ByteArray;
    fn get_description(self: @T) -> ByteArray;
    fn get_base_value(self: @T) -> u32;
    fn can_use(self: @T, player: @Player) -> bool;
    fn apply_effect(self: @T, ref store: Store, ref player: Player, quantity: u32) -> ElementEffect;
    fn get_cooldown_seconds(self: @T) -> u64;
    fn get_stack_limit(self: @T) -> u32;
}

pub trait CombatElement<T> {
    fn get_damage(self: @T) -> u32;
    fn get_defense(self: @T) -> u32;
    fn get_durability(self: @T) -> u32;
    fn apply_combat_effect(self: @T, ref attacker: Player, ref defender: Player) -> ElementEffect;
}

pub trait ConsumableElement<T> {
    fn get_charges(self: @T) -> u32;
    fn consume_charge(ref self: T) -> bool;
    fn is_consumed(self: @T) -> bool;
}