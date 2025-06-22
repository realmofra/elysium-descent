//! Events for the inventory system

use bevy::prelude::*;
use crate::systems::collectibles::CollectibleType;

/// Event triggered when an item is collected by the player
#[derive(Event, Debug)]
pub struct ItemCollectedEvent {
    /// The type of item that was collected
    pub item_type: CollectibleType,
    /// The entity of the player who collected the item
    pub collector: Entity,
    /// The amount collected (defaults to 1)
    pub amount: u32,
}

impl ItemCollectedEvent {
    /// Create a new item collected event with default amount of 1
    pub fn new(item_type: CollectibleType, collector: Entity, _item_entity: Entity) -> Self {
        Self {
            item_type,
            collector,
            amount: 1,
        }
    }
}

/// Event triggered when the inventory state changes
#[derive(Event, Debug)]
pub struct InventoryUpdatedEvent {
    /// The player whose inventory was updated
    pub player: Entity,
    /// The slot index that was modified
    pub slot_index: Option<usize>,
    /// The type of update that occurred
    pub update_type: InventoryUpdateType,
}

/// Types of inventory updates
#[derive(Debug, Clone, Copy)]
pub enum InventoryUpdateType {
    /// Item count was increased in existing slot
    ItemCountIncreased {
        item_type: CollectibleType,
        old_count: u32,
        new_count: u32,
    },
    /// Item was added to inventory
    ItemAdded {
        item_type: CollectibleType,
        new_count: u32,
    },
}

/// Event for specific slot changes (for UI updates)
#[derive(Event, Debug)]
pub struct InventorySlotChangedEvent {
    /// The player whose inventory slot changed
    pub player: Entity,
    /// The slot that changed
    pub slot_index: usize,
    /// New slot content
    pub new_content: Option<SlotContent>,
}

/// Represents the content of an inventory slot
#[derive(Debug, Clone)]
pub struct SlotContent {
    pub item_type: CollectibleType,
    pub count: u32,
}