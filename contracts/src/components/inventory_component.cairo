use starknet::ContractAddress;
use elysium_descent::helpers::store::{Store, StoreTrait};
use elysium_descent::models::player::Player;
use elysium_descent::models::inventory::PlayerInventory;
use elysium_descent::models::world_state::WorldItem;
use elysium_descent::types::item_types::ItemType;

/// Inventory Component - handles all inventory-related business logic
#[generate_trait]
pub impl InventoryComponentImpl of InventoryComponentTrait {
    fn pickup_item(ref store: Store, player: ContractAddress, game_id: u32, item_id: u32) -> bool {
        // Retrieve the world item to be collected
        let mut world_item = store.get_world_item(game_id, item_id);

        // Ensure item hasn't been collected yet
        assert(!world_item.is_collected, 'Item already collected');

        // Load current player inventory state
        let mut inventory = store.get_player_inventory(player);

        // Verify player has inventory space available
        let current_items = inventory.health_potions + inventory.survival_kits + inventory.books;
        assert(current_items < inventory.capacity, 'Inventory full');

        // Create updated inventory with new item added
        let updated_inventory = match world_item.item_type {
            ItemType::HealthPotion => PlayerInventory {
                player: inventory.player,
                health_potions: inventory.health_potions + 1,
                survival_kits: inventory.survival_kits,
                books: inventory.books,
                capacity: inventory.capacity,
            },
            ItemType::SurvivalKit => PlayerInventory {
                player: inventory.player,
                health_potions: inventory.health_potions,
                survival_kits: inventory.survival_kits + 1,
                books: inventory.books,
                capacity: inventory.capacity,
            },
            ItemType::Book => PlayerInventory {
                player: inventory.player,
                health_potions: inventory.health_potions,
                survival_kits: inventory.survival_kits,
                books: inventory.books + 1,
                capacity: inventory.capacity,
            },
        };

        // Update world item to mark as collected
        let updated_item = WorldItem {
            game_id: world_item.game_id,
            item_id: world_item.item_id,
            item_type: world_item.item_type,
            x_position: world_item.x_position,
            y_position: world_item.y_position,
            is_collected: true,
            level: world_item.level,
        };

        // Persist updated inventory and item states
        store.set_player_inventory(updated_inventory);
        store.set_world_item(updated_item);

        // Calculate player experience and level progression
        let player_stats = store.get_player(player);
        let new_experience = player_stats.experience + 10;
        let new_items_collected = player_stats.items_collected + 1;

        // Handle level progression and health bonuses
        let new_level = (new_experience / 100) + 1;
        let (new_health, new_max_health) = if new_level > player_stats.level {
            let bonus_health = (new_level - player_stats.level) * 10;
            let new_max = player_stats.max_health + bonus_health;
            // Restore health to maximum on level up
            (new_max, new_max)
        } else {
            (player_stats.health, player_stats.max_health)
        };

        let updated_player = Player {
            player: player_stats.player,
            health: new_health,
            max_health: new_max_health,
            level: new_level,
            experience: new_experience,
            items_collected: new_items_collected,
        };

        store.set_player(updated_player);

        // Notify external systems of successful item pickup
        store.emit_item_picked_up(player, game_id, item_id, world_item.item_type, world_item.level);

        true
    }

    fn use_consumable_item(
        ref store: Store, player: ContractAddress, item_type: ItemType, quantity: u32,
    ) -> bool {
        let mut inventory = store.get_player_inventory(player);
        let mut player_stats = store.get_player(player);

        // Validate sufficient items are available for consumption
        let available = match item_type {
            ItemType::HealthPotion => inventory.health_potions,
            ItemType::SurvivalKit => inventory.survival_kits,
            ItemType::Book => inventory.books,
        };

        assert(available >= quantity, 'Insufficient items');

        // Consume items and apply their beneficial effects
        match item_type {
            ItemType::HealthPotion => {
                inventory.health_potions -= quantity;
                // Standard healing: 25 HP per potion
                let heal_amount = quantity * 25;
                let new_health = player_stats.health + heal_amount;
                player_stats
                    .health =
                        if new_health > player_stats.max_health {
                            player_stats.max_health
                        } else {
                            new_health
                        };
            },
            ItemType::SurvivalKit => {
                inventory.survival_kits -= quantity;
                // Survival kits provide moderate experience bonus
                player_stats.experience += quantity * 50;
            },
            ItemType::Book => {
                inventory.books -= quantity;
                // Books provide high experience bonus for knowledge gain
                player_stats.experience += quantity * 100;
            },
        };

        // Process level advancement from experience gain
        let new_level = (player_stats.experience / 100) + 1;
        if new_level > player_stats.level {
            player_stats.level = new_level;
            player_stats.max_health += 10 * (new_level - player_stats.level);
        }

        // Save updated inventory and player progression
        store.set_player_inventory(inventory);
        store.set_player(player_stats);

        true
    }

    fn get_inventory_summary(store: @Store, player: ContractAddress) -> InventorySummary {
        let inventory = store.get_player_inventory(player);
        let total_items = inventory.health_potions + inventory.survival_kits + inventory.books;
        let free_slots = inventory.capacity - total_items;

        InventorySummary {
            total_items,
            free_slots,
            capacity: inventory.capacity,
            health_potions: inventory.health_potions,
            survival_kits: inventory.survival_kits,
            books: inventory.books,
        }
    }

    fn transfer_item(
        ref store: Store,
        from_player: ContractAddress,
        to_player: ContractAddress,
        item_type: ItemType,
        quantity: u32,
    ) -> bool {
        let mut from_inventory = store.get_player_inventory(from_player);
        let mut to_inventory = store.get_player_inventory(to_player);

        // Validate sender has sufficient items for transfer
        let available = match item_type {
            ItemType::HealthPotion => from_inventory.health_potions,
            ItemType::SurvivalKit => from_inventory.survival_kits,
            ItemType::Book => from_inventory.books,
        };
        assert(available >= quantity, 'Insufficient items');

        // Ensure recipient inventory has adequate capacity
        let to_total = to_inventory.health_potions
            + to_inventory.survival_kits
            + to_inventory.books;
        assert(to_total + quantity <= to_inventory.capacity, 'Recipient inventory full');

        // Execute item transfer between inventories
        match item_type {
            ItemType::HealthPotion => {
                from_inventory.health_potions -= quantity;
                to_inventory.health_potions += quantity;
            },
            ItemType::SurvivalKit => {
                from_inventory.survival_kits -= quantity;
                to_inventory.survival_kits += quantity;
            },
            ItemType::Book => {
                from_inventory.books -= quantity;
                to_inventory.books += quantity;
            },
        };

        // Persist changes to both player inventories
        store.set_player_inventory(from_inventory);
        store.set_player_inventory(to_inventory);

        true
    }
}

/// Data structure for consolidated inventory information queries
#[derive(Drop, Serde)]
pub struct InventorySummary {
    pub total_items: u32,
    pub free_slots: u32,
    pub capacity: u32,
    pub health_potions: u32,
    pub survival_kits: u32,
    pub books: u32,
}
