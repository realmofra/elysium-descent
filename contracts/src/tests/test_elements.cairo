use elysium_descent::elements::factory::{DefaultElementFactory};
use elysium_descent::elements::base::{ItemElement};
use elysium_descent::types::item::ItemType;
use elysium_descent::models::player::Player;
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

fn create_full_health_player() -> Player {
    Player {
        player: starknet::contract_address_const::<0x1>(),
        health: 100,
        max_health: 100,
        level: 1,
        experience: 100,
        items_collected: 0,
    }
}

fn create_low_exp_player() -> Player {
    Player {
        player: starknet::contract_address_const::<0x1>(),
        health: 50,
        max_health: 100,
        level: 1,
        experience: 5,
        items_collected: 0,
    }
}

#[test]
fn test_element_factory_creates_health_potion() {
    let element = DefaultElementFactory::create_element(ItemType::HealthPotion);
    assert_eq!(element.get_name(), "Health Potion");
    assert_eq!(element.get_base_value(), 25);
}

#[test] 
fn test_element_factory_creates_survival_kit() {
    let element = DefaultElementFactory::create_element(ItemType::SurvivalKit);
    assert_eq!(element.get_name(), "Survival Kit");
    assert_eq!(element.get_base_value(), 50); // experience bonus
}

#[test]
fn test_element_factory_creates_book() {
    let element = DefaultElementFactory::create_element(ItemType::Book);
    assert_eq!(element.get_name(), "Teleport Scroll");
    assert_eq!(element.get_base_value(), 10); // teleport range
}

#[test]
fn test_health_potion_can_use_logic() {
    let (_world, _systems, _context) = spawn();
    let element = DefaultElementFactory::create_element(ItemType::HealthPotion);
    
    let damaged_player = create_test_player();
    assert!(element.can_use(@damaged_player), "Should be usable when damaged");
    
    let full_health_player = create_full_health_player();
    assert!(!element.can_use(@full_health_player), "Should not be usable at full health");
}

#[test]
fn test_health_potion_effect_application() {
    let (world, _systems, _context) = spawn();
    let mut store = StoreTrait::new(world);
    
    let element = DefaultElementFactory::create_element(ItemType::HealthPotion);
    let mut player = create_test_player();
    let initial_health = player.health;
    
    let effect = element.apply_effect(ref store, ref player, 2);
    
    assert!(effect.success, "Effect should succeed");
    assert_eq!(effect.value_changed, 50, "Should heal for 50 (25 * 2)");
    assert_eq!(player.health, initial_health + 50, "Player health should increase");
}

#[test]
fn test_survival_kit_effect_application() {
    let (world, _systems, _context) = spawn();
    let mut store = StoreTrait::new(world);
    
    let element = DefaultElementFactory::create_element(ItemType::SurvivalKit);
    let mut player = create_test_player();
    let initial_exp = player.experience;
    let initial_health = player.health;
    
    let effect = element.apply_effect(ref store, ref player, 1);
    
    assert!(effect.success, "Effect should succeed");
    assert_eq!(player.experience, initial_exp + 50, "Should gain 50 XP");
    assert_eq!(player.health, initial_health + 20, "Should heal 20");
}

#[test]
fn test_book_effect_application() {
    let (world, _systems, _context) = spawn();
    let mut store = StoreTrait::new(world);
    
    let element = DefaultElementFactory::create_element(ItemType::Book);
    let mut player = create_test_player();
    let initial_exp = player.experience;
    
    let effect = element.apply_effect(ref store, ref player, 1);
    
    assert!(effect.success, "Effect should succeed");
    assert_eq!(effect.value_changed, 10, "Should cost 10 experience");
    assert_eq!(player.experience, initial_exp - 10, "Experience should decrease");
}

#[test]
fn test_book_insufficient_experience() {
    let (world, _systems, _context) = spawn();
    let mut store = StoreTrait::new(world);
    
    let element = DefaultElementFactory::create_element(ItemType::Book);
    let mut player = create_low_exp_player();
    
    let effect = element.apply_effect(ref store, ref player, 1);
    
    assert!(!effect.success, "Effect should fail");
    assert_eq!(player.experience, 5, "Experience should not change");
}

#[test]
fn test_element_cooldowns() {
    let health_potion = DefaultElementFactory::create_element(ItemType::HealthPotion);
    let survival_kit = DefaultElementFactory::create_element(ItemType::SurvivalKit);
    let book = DefaultElementFactory::create_element(ItemType::Book);
    
    assert_eq!(health_potion.get_cooldown_seconds(), 2);
    assert_eq!(survival_kit.get_cooldown_seconds(), 5);
    assert_eq!(book.get_cooldown_seconds(), 10);
}

#[test]
fn test_element_stack_limits() {
    let health_potion = DefaultElementFactory::create_element(ItemType::HealthPotion);
    let survival_kit = DefaultElementFactory::create_element(ItemType::SurvivalKit);
    let book = DefaultElementFactory::create_element(ItemType::Book);
    
    assert_eq!(health_potion.get_stack_limit(), 99);
    assert_eq!(survival_kit.get_stack_limit(), 20);
    assert_eq!(book.get_stack_limit(), 10);
}

#[test]
fn test_element_descriptions() {
    let health_potion = DefaultElementFactory::create_element(ItemType::HealthPotion);
    let survival_kit = DefaultElementFactory::create_element(ItemType::SurvivalKit);
    let book = DefaultElementFactory::create_element(ItemType::Book);
    
    assert!(health_potion.get_description().len() > 0, "Health potion should have description");
    assert!(survival_kit.get_description().len() > 0, "Survival kit should have description");
    assert!(book.get_description().len() > 0, "Book should have description");
}

#[test]
fn test_health_potion_overheal_prevention() {
    let (world, _systems, _context) = spawn();
    let mut store = StoreTrait::new(world);
    
    let element = DefaultElementFactory::create_element(ItemType::HealthPotion);
    let mut player = create_test_player();
    player.health = 90; // Close to max
    
    let effect = element.apply_effect(ref store, ref player, 2); // Would heal 50
    
    assert!(effect.success, "Effect should succeed");
    assert_eq!(effect.value_changed, 10, "Should only heal to max (10)");
    assert_eq!(player.health, 100, "Should be at max health");
}

#[test]
fn test_multiple_element_effects() {
    let (world, _systems, _context) = spawn();
    let mut store = StoreTrait::new(world);
    
    let health_potion = DefaultElementFactory::create_element(ItemType::HealthPotion);
    let survival_kit = DefaultElementFactory::create_element(ItemType::SurvivalKit);
    
    let mut player = create_test_player();
    player.health = 30;
    player.experience = 50;
    
    // Use health potion first
    let effect1 = health_potion.apply_effect(ref store, ref player, 1);
    assert!(effect1.success);
    assert_eq!(player.health, 55, "Should heal 25");
    
    // Then use survival kit
    let effect2 = survival_kit.apply_effect(ref store, ref player, 1);
    assert!(effect2.success);
    assert_eq!(player.health, 75, "Should heal additional 20");
    assert_eq!(player.experience, 100, "Should gain 50 XP");
}

#[test]
fn test_element_wrapper_functionality() {
    let health_element = DefaultElementFactory::create_element(ItemType::HealthPotion);
    let survival_element = DefaultElementFactory::create_element(ItemType::SurvivalKit);
    let book_element = DefaultElementFactory::create_element(ItemType::Book);
    
    assert_eq!(health_element.get_name(), "Health Potion");
    assert_eq!(survival_element.get_name(), "Survival Kit");
    assert_eq!(book_element.get_name(), "Teleport Scroll");
    
    assert_eq!(health_element.get_base_value(), 25);
    assert_eq!(survival_element.get_base_value(), 50);
    assert_eq!(book_element.get_base_value(), 10);
}