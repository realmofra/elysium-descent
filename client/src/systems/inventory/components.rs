//! Components for the inventory system

use bevy::prelude::*;

/// Marker component for the main inventory UI container
#[derive(Component, Debug)]
pub struct InventoryUI;

/// Component that marks an inventory slot with its index
#[derive(Component, Debug)]
pub struct InventorySlot {
    /// Zero-based index of this slot
    pub index: usize,
}

impl InventorySlot {
    /// Create a new inventory slot with the given index
    pub fn new(index: usize) -> Self {
        Self { index }
    }
}

/// Component for marking UI text that displays item counts
#[derive(Component, Debug)]
pub struct ItemCountText;

impl ItemCountText {
    pub fn new(_slot_index: usize) -> Self {
        Self
    }
}

/// Component for marking UI images that display item icons
#[derive(Component, Debug)]
pub struct ItemIconImage;

impl ItemIconImage {
    pub fn new(_slot_index: usize) -> Self {
        Self
    }
}

/// Errors that can occur during inventory operations
#[derive(Debug, Clone, Copy)]
pub enum InventoryError {
    /// The inventory is full and cannot accept more items
    InventoryFull,
    /// Tried to add more items than u32 can hold
    CountOverflow,
}