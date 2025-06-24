use starknet::ContractAddress;
use elysium_descent::helpers::store::{Store, StoreTrait};
use elysium_descent::models::player::Player;
use elysium_descent::models::inventory::PlayerInventory;
use elysium_descent::models::world_state::WorldItem;
use elysium_descent::types::item_types::ItemType;

// Inventory Component - handles all inventory-related business logic
#[generate_trait]
pub impl InventoryComponentImpl of InventoryComponentTrait {
    fn pickup_item(ref store: Store, player: ContractAddress, game_id: u32, item_id: u32) -> bool {
        // Get the item
        let mut world_item = store.get_world_item(game_id, item_id);

        // Validate item can be picked up
        assert(!world_item.is_collected, 'Item already collected');

        // Get player inventory
        let mut inventory = store.get_player_inventory(player);

        // Check inventory capacity
        let current_items = inventory.health_potions + inventory.survival_kits + inventory.books;
        assert(current_items < inventory.capacity, 'Inventory full');

        // Add item to inventory
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

        // Mark item as collected
        let updated_item = WorldItem {
            game_id: world_item.game_id,
            item_id: world_item.item_id,
            item_type: world_item.item_type,
            x_position: world_item.x_position,
            y_position: world_item.y_position,
            is_collected: true,
            level: world_item.level,
        };

        // Update models
        store.update_player_inventory(updated_inventory);
        store.update_world_item(updated_item);

        // Update player stats
        let player_stats = store.get_player(player);
        let new_experience = player_stats.experience + 10;
        let new_items_collected = player_stats.items_collected + 1;

        // Level up logic
        let new_level = (new_experience / 100) + 1;
        let (new_health, new_max_health) = if new_level > player_stats.level {
            let bonus_health = (new_level - player_stats.level) * 10;
            let new_max = player_stats.max_health + bonus_health;
            (new_max, new_max) // Full heal on level up
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

        store.update_player(updated_player);

        // Emit event
        store.emit_item_picked_up(player, game_id, item_id, world_item.item_type, world_item.level);

        true
    }

    fn use_consumable_item(
        ref store: Store, player: ContractAddress, item_type: ItemType, quantity: u32,
    ) -> bool {
        let mut inventory = store.get_player_inventory(player);
        let mut player_stats = store.get_player(player);

        // Check if player has enough items
        let available = match item_type {
            ItemType::HealthPotion => inventory.health_potions,
            ItemType::SurvivalKit => inventory.survival_kits,
            ItemType::Book => inventory.books,
        };

        assert(available >= quantity, 'Insufficient items');

        // Apply item effects and consume items
        match item_type {
            ItemType::HealthPotion => {
                inventory.health_potions -= quantity;
                let heal_amount = quantity * 25; // Each potion heals 25 HP
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
                // Survival kit could provide various benefits
                player_stats.experience += quantity * 50;
            },
            ItemType::Book => {
                inventory.books -= quantity;
                // Books provide experience
                player_stats.experience += quantity * 100;
            },
        };

        // Check for level up
        let new_level = (player_stats.experience / 100) + 1;
        if new_level > player_stats.level {
            player_stats.level = new_level;
            player_stats.max_health += 10 * (new_level - player_stats.level);
        }

        // Update models
        store.update_player_inventory(inventory);
        store.update_player(player_stats);

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

        // Check if from_player has enough items
        let available = match item_type {
            ItemType::HealthPotion => from_inventory.health_potions,
            ItemType::SurvivalKit => from_inventory.survival_kits,
            ItemType::Book => from_inventory.books,
        };
        assert(available >= quantity, 'Insufficient items');

        // Check if to_player has space
        let to_total = to_inventory.health_potions
            + to_inventory.survival_kits
            + to_inventory.books;
        assert(to_total + quantity <= to_inventory.capacity, 'Recipient inventory full');

        // Transfer items
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

        // Update both inventories
        store.update_player_inventory(from_inventory);
        store.update_player_inventory(to_inventory);

        true
    }
}

// Helper struct for inventory queries
#[derive(Drop, Serde)]
pub struct InventorySummary {
    pub total_items: u32,
    pub free_slots: u32,
    pub capacity: u32,
    pub health_potions: u32,
    pub survival_kits: u32,
    pub books: u32,
}
