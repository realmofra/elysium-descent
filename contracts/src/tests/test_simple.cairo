#[cfg(test)]
mod tests {
    use starknet::testing::set_contract_address;
    use dojo::world::WorldStorage;
    use dojo::model::{ModelStorage, ModelStorageTest};
    use elysium_descent::systems::actions::IActionsDispatcherTrait;

    use elysium_descent::tests::setup::{
        spawn, 
        Player, Game, GameCounter, LevelItems, PlayerInventory, WorldItem
    };
    use elysium_descent::helpers::store::{Store, StoreTrait};
    use elysium_descent::types::item_types::ItemType;

    #[test]
    fn test_basic_model_operations() {
        let (mut world, _systems, context) = spawn();
        let player_address = context.player1;

        // Create a test player model
        let test_player = Player {
            player: player_address,
            health: 100,
            max_health: 100,
            level: 1,
            experience: 0,
            items_collected: 0,
        };

        // Use Store pattern for enhanced model access
        let store: Store = StoreTrait::new(world);
        
        world.write_model_test(@test_player);
        let read_player: Player = store.get_player(player_address);

        assert(read_player.player == player_address, 'Player address mismatch');
        assert(read_player.health == 100, 'Health mismatch');
        assert(read_player.level == 1, 'Level mismatch');

        let test_game_counter = GameCounter { counter_id: 999999999, next_game_id: 1 };
        world.write_model_test(@test_game_counter);
        let read_counter: GameCounter = world.read_model(test_game_counter.counter_id);
        assert(read_counter.next_game_id == 1, 'Counter mismatch');

        let test_inventory = PlayerInventory {
            player: player_address, health_potions: 5, survival_kits: 2, books: 1, capacity: 20,
        };
        world.write_model_test(@test_inventory);
        let read_inventory: PlayerInventory = store.get_player_inventory(player_address);
        assert(read_inventory.health_potions == 5, 'Inventory mismatch');

        let test_level_items = LevelItems {
            game_id: 1,
            level: 1,
            total_health_potions: 10,
            total_survival_kits: 5,
            total_books: 3,
            collected_health_potions: 0,
            collected_survival_kits: 0,
            collected_books: 0,
        };
        world.write_model_test(@test_level_items);
        let read_level_items: LevelItems = store.get_level_items(1, 1);
        assert(read_level_items.total_health_potions == 10, 'Level items mismatch');

        let test_world_item = WorldItem {
            game_id: 1,
            item_id: 1,
            item_type: ItemType::HealthPotion,
            x_position: 10,
            y_position: 20,
            is_collected: false,
            level: 1,
        };
        world.write_model_test(@test_world_item);
        let read_world_item: WorldItem = store.get_world_item(1, 1);
        assert(read_world_item.x_position == 10, 'World item mismatch');
    }

    #[test]
    fn test_basic_system_dispatch() {
        let (world, systems, context) = spawn();

        set_contract_address(context.player1);
        let game_id = systems.actions.create_game();

        assert(game_id > 0, 'Game ID should be positive');

        let store: Store = StoreTrait::new(world);
        let game: Game = store.get_game(game_id);
        assert(game.player == context.player1, 'Game player should match');

        verify_world_storage_works(world);
        test_store_pattern_usage(world, context.player1);
    }

    /// Validates that WorldStorage has a valid dispatcher address
    fn verify_world_storage_works(world: WorldStorage) {
        assert(
            world.dispatcher.contract_address != starknet::contract_address_const::<0>(),
            'World should have address',
        );
    }

    /// Demonstrates Store pattern for accessing player and inventory data
    fn test_store_pattern_usage(world: WorldStorage, player: starknet::ContractAddress) {
        let store: Store = StoreTrait::new(world);
        let player_data = store.get_player(player);
        let inventory = store.get_player_inventory(player);

        assert(player_data.health <= player_data.max_health, 'Health should be valid');
        assert(inventory.capacity > 0, 'Inventory should have capacity');
    }
}
