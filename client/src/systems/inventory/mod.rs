//! Inventory System for Elysium Descent
//! 
//! This module provides a professional, event-driven inventory system that follows
//! Bevy 0.16 best practices and proper separation of concerns.

pub mod components;
pub mod events;
pub mod resources;
pub mod systems;

use bevy::prelude::*;
use crate::screens::Screen;

/// Maximum number of inventory slots
pub const INVENTORY_CAPACITY: usize = 6;


/// Duration to show inventory after item collection (seconds)
pub const INVENTORY_DISPLAY_DURATION: f32 = 2.0;

/// Plugin function for the inventory system
pub fn plugin(app: &mut App) {
    app
        // Add events
        .add_event::<events::ItemCollectedEvent>()
        .add_event::<events::InventoryUpdatedEvent>()
        .add_event::<events::InventorySlotChangedEvent>()
        
        // Initialize resources
        .init_resource::<resources::InventoryVisibilityState>()
        .init_resource::<resources::InventoryData>()
        
        // Add observers for reactive programming - NOTE: May have issues with Bevy 0.16
        // Temporarily disabled to avoid conflicts with event-based systems
        // .add_observer(systems::handle_item_collected)
        // .add_observer(systems::handle_inventory_updated)
        
        // Add systems
        .add_systems(
            OnEnter(Screen::GamePlay),
            systems::spawn_inventory_ui,
        )
        .add_systems(
            OnExit(Screen::GamePlay),
            systems::cleanup_inventory_ui,
        )
        .add_systems(
            Update,
            (
                systems::toggle_inventory_visibility,
                systems::update_inventory_ui_visibility,
                systems::auto_hide_inventory,
                systems::update_inventory_slot_ui,
                systems::debug_inventory_events, // Debug system to trace events
                systems::handle_item_collected_events, // Backup event-based system
                systems::handle_inventory_updated_events, // Backup event-based system
            ).run_if(in_state(Screen::GamePlay))
        );
}