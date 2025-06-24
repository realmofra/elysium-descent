#[cfg(test)]
mod tests {
    use super::super::setup::{spawn, create_test_game, start_test_level, Context, Systems};
    use dojo::world::{WorldStorage, WorldStorageTrait};
    use dojo::model::{ModelStorage};
    use starknet::{ContractAddress};
    
    use elysium_descent::models::player::Player;
    use elysium_descent::models::inventory::PlayerInventory;
    use elysium_descent::models::game::{Game, LevelItems};
    use elysium_descent::models::world_state::WorldItem;
    use elysium_descent::types::item_types::ItemType;

    // Helper function to create a world item for testing
    fn create_test_world_item(world: WorldStorage, game_id: u32, item_id: u32, item_type: ItemType) {
        let world_item = WorldItem {
            game_id,
            item_id,
            item_type,
            x_position: 50,
            y_position: 50,
            is_collected: false,
            level: 1,
        };
        world.write_model(@world_item);
    }

    #[test]
    fn test_pickup_health_potion_updates_inventory_and_experience() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Create game and start level 1
        starknet::testing::set_contract_address(context.player);
        let game_id = systems.actions.create_game();
        systems.actions.start_level(game_id, 1);
        
        // Create a test world item (health potion)
        let item_id = 12345_u32;
        create_test_world_item(world, game_id, item_id, ItemType::HealthPotion);
        
        // Get initial player stats and inventory
        let initial_player: Player = world.read_model(context.player);
        let initial_inventory: PlayerInventory = world.read_model(context.player);
        
        // Pickup the item
        let pickup_success = systems.actions.pickup_item(game_id, item_id);
        assert(pickup_success, 'Pickup should succeed');
        
        // Verify inventory was updated
        let updated_inventory: PlayerInventory = world.read_model(context.player);
        assert(updated_inventory.health_potions == initial_inventory.health_potions + 1, 'Health potions should increase by 1');
        assert(updated_inventory.survival_kits == initial_inventory.survival_kits, 'Survival kits should not change');
        assert(updated_inventory.books == initial_inventory.books, 'Books should not change');
        
        // Verify player experience increased
        let updated_player: Player = world.read_model(context.player);
        assert(updated_player.experience > initial_player.experience, 'Experience should increase');
        assert(updated_player.items_collected == initial_player.items_collected + 1, 'Items collected should increase by 1');
        
        // Verify world item is marked as collected
        let world_item: WorldItem = world.read_model((game_id, item_id));
        assert(world_item.is_collected, 'World item should be marked as collected');
    }

    #[test]
    fn test_pickup_survival_kit_updates_inventory_correctly() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Create game and start level 1
        starknet::testing::set_contract_address(context.player);
        let game_id = systems.actions.create_game();
        systems.actions.start_level(game_id, 1);
        
        // Create a test world item (survival kit)
        let item_id = 54321_u32;
        create_test_world_item(world, game_id, item_id, ItemType::SurvivalKit);
        
        // Get initial inventory
        let initial_inventory: PlayerInventory = world.read_model(context.player);
        
        // Pickup the item
        let pickup_success = systems.actions.pickup_item(game_id, item_id);
        assert(pickup_success, 'Pickup should succeed');
        
        // Verify inventory was updated
        let updated_inventory: PlayerInventory = world.read_model(context.player);
        assert(updated_inventory.survival_kits == initial_inventory.survival_kits + 1, 'Survival kits should increase by 1');
        assert(updated_inventory.health_potions == initial_inventory.health_potions, 'Health potions should not change');
        assert(updated_inventory.books == initial_inventory.books, 'Books should not change');
    }

    #[test]
    fn test_pickup_book_updates_inventory_correctly() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Create game and start level 1
        starknet::testing::set_contract_address(context.player);
        let game_id = systems.actions.create_game();
        systems.actions.start_level(game_id, 1);
        
        // Create a test world item (book)
        let item_id = 98765_u32;
        create_test_world_item(world, game_id, item_id, ItemType::Book);
        
        // Get initial inventory
        let initial_inventory: PlayerInventory = world.read_model(context.player);
        
        // Pickup the item
        let pickup_success = systems.actions.pickup_item(game_id, item_id);
        assert(pickup_success, 'Pickup should succeed');
        
        // Verify inventory was updated
        let updated_inventory: PlayerInventory = world.read_model(context.player);
        assert(updated_inventory.books == initial_inventory.books + 1, 'Books should increase by 1');
        assert(updated_inventory.health_potions == initial_inventory.health_potions, 'Health potions should not change');
        assert(updated_inventory.survival_kits == initial_inventory.survival_kits, 'Survival kits should not change');
    }

    #[test]
    fn test_pickup_multiple_items_accumulates_correctly() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Create game and start level 1
        starknet::testing::set_contract_address(context.player);
        let game_id = systems.actions.create_game();
        systems.actions.start_level(game_id, 1);
        
        // Create multiple test world items
        create_test_world_item(world, game_id, 1001, ItemType::HealthPotion);
        create_test_world_item(world, game_id, 1002, ItemType::HealthPotion);
        create_test_world_item(world, game_id, 1003, ItemType::SurvivalKit);
        create_test_world_item(world, game_id, 1004, ItemType::Book);
        
        // Get initial state
        let initial_inventory: PlayerInventory = world.read_model(context.player);
        let initial_player: Player = world.read_model(context.player);
        
        // Pickup all items
        systems.actions.pickup_item(game_id, 1001);
        systems.actions.pickup_item(game_id, 1002);
        systems.actions.pickup_item(game_id, 1003);
        systems.actions.pickup_item(game_id, 1004);
        
        // Verify final inventory state
        let final_inventory: PlayerInventory = world.read_model(context.player);
        assert(final_inventory.health_potions == initial_inventory.health_potions + 2, 'Should have 2 more health potions');
        assert(final_inventory.survival_kits == initial_inventory.survival_kits + 1, 'Should have 1 more survival kit');
        assert(final_inventory.books == initial_inventory.books + 1, 'Should have 1 more book');
        
        // Verify player stats updated
        let final_player: Player = world.read_model(context.player);
        assert(final_player.items_collected == initial_player.items_collected + 4, 'Should have collected 4 items');
        assert(final_player.experience > initial_player.experience, 'Experience should have increased');
    }

    #[test]
    #[should_panic(expected: ('Item already collected', 'ENTRYPOINT_FAILED'))]
    fn test_cannot_pickup_already_collected_item() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Create game and start level 1
        starknet::testing::set_contract_address(context.player);
        let game_id = systems.actions.create_game();
        systems.actions.start_level(game_id, 1);
        
        // Create a test world item
        let item_id = 11111_u32;
        create_test_world_item(world, game_id, item_id, ItemType::HealthPotion);
        
        // Pickup the item once - should succeed
        let pickup_success = systems.actions.pickup_item(game_id, item_id);
        assert(pickup_success, 'First pickup should succeed');
        
        // Try to pickup the same item again - should fail
        systems.actions.pickup_item(game_id, item_id);
    }

    #[test]
    #[should_panic(expected: ('Item does not exist', 'ENTRYPOINT_FAILED'))]
    fn test_cannot_pickup_nonexistent_item() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Create game and start level 1
        starknet::testing::set_contract_address(context.player);
        let game_id = systems.actions.create_game();
        systems.actions.start_level(game_id, 1);
        
        // Try to pickup an item that doesn't exist
        let nonexistent_item_id = 99999_u32;
        systems.actions.pickup_item(game_id, nonexistent_item_id);
    }

    #[test]
    fn test_level_items_collection_counter_updates() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Create game and start level 1
        starknet::testing::set_contract_address(context.player);
        let game_id = systems.actions.create_game();
        systems.actions.start_level(game_id, 1);
        
        // Create test world items of different types
        create_test_world_item(world, game_id, 2001, ItemType::HealthPotion);
        create_test_world_item(world, game_id, 2002, ItemType::SurvivalKit);
        
        // Get initial level items state
        let initial_level_items: LevelItems = world.read_model((game_id, 1));
        
        // Pickup items
        systems.actions.pickup_item(game_id, 2001);
        systems.actions.pickup_item(game_id, 2002);
        
        // Verify level items collection counters updated
        let updated_level_items: LevelItems = world.read_model((game_id, 1));
        assert(updated_level_items.collected_health_potions == initial_level_items.collected_health_potions + 1, 'Collected health potions should increase');
        assert(updated_level_items.collected_survival_kits == initial_level_items.collected_survival_kits + 1, 'Collected survival kits should increase');
        assert(updated_level_items.collected_books == initial_level_items.collected_books, 'Collected books should not change');
    }
}