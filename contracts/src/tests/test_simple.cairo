#[cfg(test)]
mod tests {
    use starknet::{ContractAddress, contract_address_const, testing::set_contract_address};
    use dojo::world::{WorldStorage, WorldStorageTrait};
    use dojo::model::{ModelStorage, ModelStorageTest};
    use dojo_cairo_test::{spawn_test_world, NamespaceDef, TestResource, ContractDefTrait, WorldStorageTestTrait};

    use elysium_descent::systems::actions::{actions, IActionsDispatcher, IActionsDispatcherTrait};
    use elysium_descent::systems::actions::{e_GameCreated, e_LevelStarted, e_ItemPickedUp};
    use elysium_descent::models::index::{Player, Game, GameCounter, LevelItems, PlayerInventory, WorldItem};
    use elysium_descent::models::player::m_Player;
    use elysium_descent::models::game::{m_Game, m_GameCounter, m_LevelItems};
    use elysium_descent::models::inventory::m_PlayerInventory;
    use elysium_descent::models::world_state::m_WorldItem;

    fn PLAYER() -> ContractAddress {
        contract_address_const::<'PLAYER'>()
    }

    #[test]
    fn test_basic_model_operations() {
        // Test basic model operations without complex setup
        let namespace_def = NamespaceDef {
            namespace: "elysium_001",
            resources: [
                TestResource::Model(m_Player::TEST_CLASS_HASH),
                TestResource::Model(m_Game::TEST_CLASS_HASH),
                TestResource::Model(m_GameCounter::TEST_CLASS_HASH),
                TestResource::Model(m_LevelItems::TEST_CLASS_HASH),
                TestResource::Model(m_PlayerInventory::TEST_CLASS_HASH),
                TestResource::Model(m_WorldItem::TEST_CLASS_HASH),
                TestResource::Event(e_GameCreated::TEST_CLASS_HASH),
                TestResource::Event(e_LevelStarted::TEST_CLASS_HASH),
                TestResource::Event(e_ItemPickedUp::TEST_CLASS_HASH),
                TestResource::Contract(actions::TEST_CLASS_HASH),
            ].span(),
        };

        let mut world = spawn_test_world([namespace_def].span());
        
        // Test that we can read/write basic models
        let player_address = PLAYER();
        
        // Create a test player model
        let test_player = Player {
            player: player_address,
            health: 100,
            max_health: 100,
            level: 1,
            experience: 0,
            items_collected: 0,
        };
        
        // Write and read back
        world.write_model_test(@test_player);
        let read_player: Player = world.read_model(player_address);
        
        // Verify data integrity
        assert(read_player.player == player_address, 'Player address mismatch');
        assert(read_player.health == 100, 'Health mismatch');
        assert(read_player.level == 1, 'Level mismatch');
    }

    #[test]
    fn test_basic_system_dispatch() {
        // Test basic system dispatch without complex operations
        let namespace_def = NamespaceDef {
            namespace: "elysium_001",
            resources: [
                TestResource::Model(m_Player::TEST_CLASS_HASH),
                TestResource::Model(m_Game::TEST_CLASS_HASH),
                TestResource::Model(m_GameCounter::TEST_CLASS_HASH),
                TestResource::Model(m_LevelItems::TEST_CLASS_HASH),
                TestResource::Model(m_PlayerInventory::TEST_CLASS_HASH),
                TestResource::Model(m_WorldItem::TEST_CLASS_HASH),
                TestResource::Event(e_GameCreated::TEST_CLASS_HASH),
                TestResource::Event(e_LevelStarted::TEST_CLASS_HASH),
                TestResource::Event(e_ItemPickedUp::TEST_CLASS_HASH),
                TestResource::Contract(actions::TEST_CLASS_HASH),
            ].span(),
        };

        let mut world = spawn_test_world([namespace_def].span());
        
        // Set up permissions
        let contract_defs = [
            ContractDefTrait::new(@"elysium_001", @"actions")
                .with_writer_of([dojo::utils::bytearray_hash(@"elysium_001")].span())
        ].span();
        world.sync_perms_and_inits(contract_defs);
        
        // Get the actions contract
        let (actions_address, _) = world.dns(@"actions").unwrap();
        let actions = IActionsDispatcher { contract_address: actions_address };
        
        // Test that we can call system methods
        set_contract_address(PLAYER());
        let game_id = actions.create_game();
        
        // Verify game was created
        assert(game_id > 0, 'Game ID should be positive');
        
        let game: Game = world.read_model(game_id);
        assert(game.player == PLAYER(), 'Game player should match');
    }
}