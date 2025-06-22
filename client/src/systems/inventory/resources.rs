//! Resources for the inventory system

use bevy::prelude::*;
use crate::systems::collectibles::CollectibleType;
use super::{components::InventoryError, INVENTORY_CAPACITY, INVENTORY_DISPLAY_DURATION};
use std::collections::HashMap;

/// Resource that manages inventory visibility state
#[derive(Resource, Debug)]
pub struct InventoryVisibilityState {
    /// Whether the inventory is currently visible
    pub is_visible: bool,
    /// Timer for auto-hiding the inventory
    pub auto_hide_timer: Timer,
    /// Whether the inventory was shown manually (I key) vs automatically (item pickup)
    pub manual_display: bool,
}

impl Default for InventoryVisibilityState {
    fn default() -> Self {
        Self {
            is_visible: false,
            auto_hide_timer: Timer::from_seconds(INVENTORY_DISPLAY_DURATION, TimerMode::Once),
            manual_display: false,
        }
    }
}

impl InventoryVisibilityState {
    /// Show the inventory and start the auto-hide timer
    pub fn show(&mut self, manual: bool) {
        self.is_visible = true;
        self.manual_display = manual;
        self.auto_hide_timer.reset();
    }
    
    /// Hide the inventory immediately
    pub fn hide(&mut self) {
        self.is_visible = false;
        self.manual_display = false;
    }
    
    /// Toggle visibility state
    pub fn toggle(&mut self) {
        if self.is_visible {
            self.hide();
        } else {
            self.show(true); // Manual toggle
        }
    }
    
    /// Update the timer and return true if it should auto-hide (unused now, kept for compatibility)
    #[allow(dead_code)]
    pub fn should_auto_hide(&mut self, delta: std::time::Duration) -> bool {
        if !self.is_visible || self.manual_display {
            return false;
        }
        
        self.auto_hide_timer.tick(delta);
        self.auto_hide_timer.finished()
    }
}

/// Resource that holds the actual inventory data for all players
#[derive(Resource, Debug, Default)]
pub struct InventoryData {
    /// Map from player entity to their inventory slots
    player_inventories: HashMap<Entity, PlayerInventory>,
}

impl InventoryData {
    /// Get a player's inventory, creating it if it doesn't exist
    pub fn get_or_create_inventory(&mut self, player: Entity) -> &mut PlayerInventory {
        self.player_inventories.entry(player).or_insert_with(PlayerInventory::new)
    }
    
    /// Get a player's inventory (read-only)
    pub fn get_inventory(&self, player: Entity) -> Option<&PlayerInventory> {
        self.player_inventories.get(&player)
    }
}

/// Represents a single player's inventory
#[derive(Debug, Clone)]
pub struct PlayerInventory {
    /// The inventory slots (fixed size array)
    slots: [Option<InventorySlot>; INVENTORY_CAPACITY],
}

impl PlayerInventory {
    /// Create a new empty inventory
    pub fn new() -> Self {
        Self {
            slots: [None; INVENTORY_CAPACITY],
        }
    }
    
    /// Try to add an item to the inventory
    pub fn add_item(&mut self, item_type: CollectibleType, amount: u32) -> Result<InventoryAddResult, InventoryError> {
        // First, try to stack with existing items
        for (index, slot) in self.slots.iter_mut().enumerate() {
            if let Some(slot) = slot {
                if slot.item_type == item_type {
                    let old_count = slot.count;
                    slot.count = slot.count.checked_add(amount)
                        .ok_or(InventoryError::CountOverflow)?;
                    
                    return Ok(InventoryAddResult::StackedExisting {
                        slot_index: index,
                        old_count,
                        new_count: slot.count,
                    });
                }
            }
        }
        
        // If no existing stack, find an empty slot
        for (index, slot) in self.slots.iter_mut().enumerate() {
            if slot.is_none() {
                *slot = Some(InventorySlot {
                    item_type,
                    count: amount,
                });
                
                return Ok(InventoryAddResult::NewSlot {
                    slot_index: index,
                    count: amount,
                });
            }
        }
        
        Err(InventoryError::InventoryFull)
    }
    
    /// Get an item from a specific slot
    pub fn get_slot(&self, index: usize) -> Option<&InventorySlot> {
        if index >= INVENTORY_CAPACITY {
            return None;
        }
        self.slots[index].as_ref()
    }
    
    /// Get the number of used slots (for debugging)
    pub fn get_used_slots(&self) -> usize {
        self.slots.iter().filter(|slot| slot.is_some()).count()
    }
}

impl Default for PlayerInventory {
    fn default() -> Self {
        Self::new()
    }
}

/// A single slot in the inventory
#[derive(Debug, Clone, Copy)]
pub struct InventorySlot {
    pub item_type: CollectibleType,
    pub count: u32,
}

/// Result of adding an item to inventory
#[derive(Debug)]
pub enum InventoryAddResult {
    /// Item was stacked with an existing item
    StackedExisting {
        slot_index: usize,
        old_count: u32,
        new_count: u32,
    },
    /// Item was placed in a new slot
    NewSlot {
        slot_index: usize,
        count: u32,
    },
}