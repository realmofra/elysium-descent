/// Integration tests that verify overall system functionality and multi-player interactions

#[cfg(test)]
mod integration_tests {
    use starknet::testing::set_contract_address;
    use dojo::world::WorldStorage;
    use dojo::model::{ModelStorage, ModelStorageTest};
    use elysium_descent::systems::actions::IActionsDispatcherTrait;

    use elysium_descent::tests::setup::{
        spawn, Player, Game, LevelItems, GameCounter, PlayerInventory, WorldItem,
    };
    use elysium_descent::helpers::store::{Store, StoreTrait};

    #[test]
    fn test_world_setup_works() {
        let (world, systems, context) = spawn();

        set_contract_address(context.player1);
        let game_id = systems.actions.create_game();

        assert(game_id == 1, 'First game ID should be 1');

        let store: Store = StoreTrait::new(world);
        let game: Game = store.get_game(game_id);
        assert(game.player == context.player1, 'Game player should match');
    }

    #[test]
    fn test_multiple_players_isolated() {
        let (world, systems, context) = spawn();

        set_contract_address(context.player1);
        let game_id_1 = systems.actions.create_game();

        set_contract_address(context.player2);
        let game_id_2 = systems.actions.create_game();

        assert(game_id_1 != game_id_2, 'Game IDs should be different');

        let store: Store = StoreTrait::new(world);
        let game_1: Game = store.get_game(game_id_1);
        let game_2: Game = store.get_game(game_id_2);

        assert(game_1.player == context.player1, 'Game 1 belongs to player 1');
        assert(game_2.player == context.player2, 'Game 2 belongs to player 2');

        test_additional_models(world, context.player1);
    }

    /// Tests all model types to ensure comprehensive model storage functionality
    fn test_additional_models(mut world: WorldStorage, player: starknet::ContractAddress) {
        let counter = GameCounter { counter_id: 999999999, next_game_id: 3 };
        world.write_model_test(@counter);
        let read_counter: GameCounter = world.read_model(counter.counter_id);
        assert(read_counter.next_game_id == 3, 'Counter should be 3');

        let level_items = LevelItems {
            game_id: 1,
            level: 1,
            total_health_potions: 5,
            total_survival_kits: 3,
            total_books: 2,
            collected_health_potions: 0,
            collected_survival_kits: 0,
            collected_books: 0,
        };
        world.write_model_test(@level_items);
        let read_level_items: LevelItems = world.read_model((1_u32, 1_u32));
        assert(read_level_items.total_health_potions == 5, 'Level items mismatch');

        // Use Store pattern for enhanced model access
        let store: Store = StoreTrait::new(world);

        let player_model = Player {
            player, health: 80, max_health: 100, level: 2, experience: 150, items_collected: 3,
        };
        world.write_model_test(@player_model);
        let read_player: Player = store.get_player(player);
        assert(read_player.level == 2, 'Player level should be 2');

        let inventory = PlayerInventory {
            player, health_potions: 3, survival_kits: 1, books: 1, capacity: 15,
        };
        world.write_model_test(@inventory);
        let read_inventory: PlayerInventory = store.get_player_inventory(player);
        assert(read_inventory.health_potions == 3, 'Inventory mismatch');

        let world_item = WorldItem {
            game_id: 1,
            item_id: 100,
            item_type: elysium_descent::types::item::ItemType::Book,
            x_position: 15,
            y_position: 25,
            is_collected: false,
            level: 1,
        };
        world.write_model_test(@world_item);
        let read_world_item: WorldItem = store.get_world_item(1, 100);
        assert(read_world_item.x_position == 15, 'World item position mismatch');
    }
}

