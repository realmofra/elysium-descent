use elysium_descent::types::item::{ItemType};
use elysium_descent::elements::base::{ItemElement, ElementEffect};
use elysium_descent::elements::items::health_potion::{HealthPotion, HealthPotionDefault};
use elysium_descent::elements::items::survival_kit::{SurvivalKit, SurvivalKitDefault};
use elysium_descent::elements::items::teleport_scroll::{Book, BookDefault};
use elysium_descent::models::player::{Player};
use elysium_descent::helpers::store::{Store};

pub trait ElementFactory {
    fn create_element(item_type: ItemType) -> ElementWrapper;
}

#[derive(Drop, Serde)]
pub enum ElementWrapper {
    HealthPotion: HealthPotion,
    SurvivalKit: SurvivalKit,
    Book: Book,
    Unknown,
}

pub impl ElementWrapperImpl of ItemElement<ElementWrapper> {
    fn get_name(self: @ElementWrapper) -> ByteArray {
        match self {
            ElementWrapper::HealthPotion(potion) => potion.get_name(),
            ElementWrapper::SurvivalKit(kit) => kit.get_name(),
            ElementWrapper::Book(scroll) => scroll.get_name(),
            ElementWrapper::Unknown => "Unknown Item",
        }
    }

    fn get_description(self: @ElementWrapper) -> ByteArray {
        match self {
            ElementWrapper::HealthPotion(potion) => potion.get_description(),
            ElementWrapper::SurvivalKit(kit) => kit.get_description(),
            ElementWrapper::Book(scroll) => scroll.get_description(),
            ElementWrapper::Unknown => "Unknown item with no effect",
        }
    }

    fn get_base_value(self: @ElementWrapper) -> u32 {
        match self {
            ElementWrapper::HealthPotion(potion) => potion.get_base_value(),
            ElementWrapper::SurvivalKit(kit) => kit.get_base_value(),
            ElementWrapper::Book(scroll) => scroll.get_base_value(),
            ElementWrapper::Unknown => 0,
        }
    }

    fn can_use(self: @ElementWrapper, player: @Player) -> bool {
        match self {
            ElementWrapper::HealthPotion(potion) => potion.can_use(player),
            ElementWrapper::SurvivalKit(kit) => kit.can_use(player),
            ElementWrapper::Book(scroll) => scroll.can_use(player),
            ElementWrapper::Unknown => false,
        }
    }

    fn apply_effect(
        self: @ElementWrapper, ref store: Store, ref player: Player, quantity: u32,
    ) -> ElementEffect {
        match self {
            ElementWrapper::HealthPotion(potion) => potion
                .apply_effect(ref store, ref player, quantity),
            ElementWrapper::SurvivalKit(kit) => kit.apply_effect(ref store, ref player, quantity),
            ElementWrapper::Book(scroll) => scroll.apply_effect(ref store, ref player, quantity),
            ElementWrapper::Unknown => ElementEffect {
                success: false, message: "Unknown item cannot be used", value_changed: 0,
            },
        }
    }

    fn get_cooldown_seconds(self: @ElementWrapper) -> u64 {
        match self {
            ElementWrapper::HealthPotion(potion) => potion.get_cooldown_seconds(),
            ElementWrapper::SurvivalKit(kit) => kit.get_cooldown_seconds(),
            ElementWrapper::Book(scroll) => scroll.get_cooldown_seconds(),
            ElementWrapper::Unknown => 0,
        }
    }

    fn get_stack_limit(self: @ElementWrapper) -> u32 {
        match self {
            ElementWrapper::HealthPotion(potion) => potion.get_stack_limit(),
            ElementWrapper::SurvivalKit(kit) => kit.get_stack_limit(),
            ElementWrapper::Book(scroll) => scroll.get_stack_limit(),
            ElementWrapper::Unknown => 1,
        }
    }
}

pub impl DefaultElementFactory of ElementFactory {
    fn create_element(item_type: ItemType) -> ElementWrapper {
        match item_type {
            ItemType::HealthPotion => ElementWrapper::HealthPotion(HealthPotionDefault::default()),
            ItemType::SurvivalKit => ElementWrapper::SurvivalKit(SurvivalKitDefault::default()),
            ItemType::Book => ElementWrapper::Book(BookDefault::default()),
            _ => ElementWrapper::Unknown,
        }
    }
}
