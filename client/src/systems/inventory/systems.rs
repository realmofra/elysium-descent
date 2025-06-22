//! Systems for the inventory system

use crate::assets::{FontAssets, UiAssets};
use crate::systems::collectibles::CollectibleType;
use bevy::prelude::*;

use super::{
    INVENTORY_CAPACITY,
    components::{InventorySlot as ComponentInventorySlot, *},
    events::{self, *},
    resources::*,
};



/// System to handle inventory visibility toggling
pub fn toggle_inventory_visibility(
    keyboard: Res<ButtonInput<KeyCode>>,
    mut visibility_state: ResMut<InventoryVisibilityState>,
) {
    if keyboard.just_pressed(KeyCode::KeyI) {
        visibility_state.toggle();
    }
}

/// System to update inventory UI visibility based on state
pub fn update_inventory_ui_visibility(
    visibility_state: Res<InventoryVisibilityState>,
    mut inventory_ui_query: Query<&mut Visibility, With<InventoryUI>>,
) {
    // Only update if state changed
    if !visibility_state.is_changed() {
        return;
    }

    for mut visibility in inventory_ui_query.iter_mut() {
        *visibility = if visibility_state.is_visible {
            Visibility::Visible
        } else {
            Visibility::Hidden
        };
    }
}

/// System to auto-hide inventory after timer expires
pub fn auto_hide_inventory(
    mut visibility_state: ResMut<InventoryVisibilityState>,
    time: Res<Time>,
) {
    // Only check if inventory is currently visible
    if !visibility_state.is_visible {
        return;
    }
    
    // Tick the timer
    visibility_state.auto_hide_timer.tick(time.delta());
    
    // Check if timer is finished
    if visibility_state.auto_hide_timer.finished() {
        info!("🎒 INVENTORY: Auto-hiding inventory after {:.2}s", 
              visibility_state.auto_hide_timer.elapsed_secs());
        visibility_state.hide();
    }
}

/// Marker component for inventory UI cleanup
#[derive(Component)]
pub struct GameplayInventoryUI;

/// System to spawn the inventory UI
pub fn spawn_inventory_ui(
    mut commands: Commands,
    _font_assets: Res<FontAssets>,
    _ui_assets: Res<UiAssets>,
) {
    let inventory_entity = commands
        .spawn((
            Node {
                width: Val::Percent(50.0),
                height: Val::Percent(15.0),
                position_type: PositionType::Absolute,
                bottom: Val::Percent(2.0),
                left: Val::Percent(25.0),
                justify_content: JustifyContent::Center,
                align_items: AlignItems::Center,
                border: UiRect::all(Val::Percent(0.3)),
                ..default()
            },
            BackgroundColor(Color::srgba(0.0, 0.7, 0.2, 0.7)),
            BorderColor(Color::BLACK),
            InventoryUI,
            GameplayInventoryUI, // Marker for cleanup
            Visibility::Hidden,
            Name::new("Inventory UI"),
        ))
        .id();

    // Spawn inventory slots as children
    for slot_index in 0..INVENTORY_CAPACITY {
        let slot_entity = commands
            .spawn((
                Node {
                    width: Val::Percent(15.0),
                    height: Val::Percent(80.0),
                    justify_content: JustifyContent::Center,
                    align_items: AlignItems::Center,
                    border: UiRect::all(Val::Px(2.0)),
                    ..default()
                },
                BackgroundColor(Color::srgba(0.0, 0.0, 0.0, 0.7)),
                BorderColor(Color::BLACK),
                ComponentInventorySlot::new(slot_index),
                Name::new(format!("Inventory Slot {}", slot_index)),
            ))
            .id();

        // Add slot to inventory container
        commands.entity(inventory_entity).add_child(slot_entity);

        // Add spacing between slots (except after the last one)
        if slot_index < INVENTORY_CAPACITY - 1 {
            let spacer = commands
                .spawn((
                    Node {
                        margin: UiRect::all(Val::Percent(0.5)),
                        ..default()
                    },
                    Name::new(format!("Slot Spacer {}", slot_index)),
                ))
                .id();

            commands.entity(inventory_entity).add_child(spacer);
        }
    }
}

/// System to update inventory slot UI when contents change
pub fn update_inventory_slot_ui(
    mut slot_change_events: EventReader<InventorySlotChangedEvent>,
    mut commands: Commands,
    font_assets: Res<FontAssets>,
    ui_assets: Res<UiAssets>,
    slot_query: Query<(Entity, &ComponentInventorySlot)>,
    children_query: Query<&Children>,
    mut _text_query: Query<&mut Text>,
    mut _image_query: Query<&mut ImageNode>,
    _item_count_query: Query<Entity, With<ItemCountText>>,
    _item_icon_query: Query<Entity, With<ItemIconImage>>,
) {
    for event in slot_change_events.read() {
        // Find the UI slot entity that matches this slot index
        let Some((slot_entity, _)) = slot_query
            .iter()
            .find(|(_, slot)| slot.index == event.slot_index)
        else {
            warn!("Could not find UI slot for index {}", event.slot_index);
            continue;
        };

        // Clear existing slot contents
        if let Ok(children) = children_query.get(slot_entity) {
            for child in children {
                commands.entity(*child).despawn();
            }
        }

        // Add new content if slot is not empty
        if let Some(content) = &event.new_content {
            spawn_slot_contents(
                &mut commands,
                &font_assets,
                &ui_assets,
                slot_entity,
                content,
                event.slot_index,
            );
        }
    }
}

/// Helper function to spawn UI contents for an inventory slot
fn spawn_slot_contents(
    commands: &mut Commands,
    font_assets: &FontAssets,
    ui_assets: &UiAssets,
    slot_entity: Entity,
    content: &events::SlotContent,
    slot_index: usize,
) {
    commands.entity(slot_entity).with_children(|parent| {
        // Create main item container
        parent
            .spawn((
                Node {
                    width: Val::Percent(100.0),
                    height: Val::Percent(100.0),
                    align_items: AlignItems::Center,
                    justify_content: JustifyContent::Center,
                    ..default()
                },
                Name::new(format!("Item Container {}", slot_index)),
            ))
            .with_children(|item_parent| {
                // Spawn item icon
                item_parent.spawn((
                    Node {
                        width: Val::Percent(80.0),
                        height: Val::Percent(80.0),
                        position_type: PositionType::Absolute,
                        ..default()
                    },
                    ImageNode {
                        image: get_item_icon(ui_assets, content.item_type),
                        ..default()
                    },
                    ItemIconImage::new(slot_index),
                    Name::new(format!("Item Icon {}", slot_index)),
                ));

                // Spawn count text if count > 1
                if content.count > 1 {
                    item_parent
                        .spawn((
                            Node {
                                position_type: PositionType::Absolute,
                                width: Val::Percent(30.0),
                                height: Val::Percent(30.0),
                                right: Val::Percent(5.0),
                                bottom: Val::Percent(5.0),
                                align_items: AlignItems::Center,
                                justify_content: JustifyContent::Center,
                                ..default()
                            },
                            BorderRadius::MAX,
                            BackgroundColor(Color::srgba(1.0, 1.0, 1.0, 0.8)),
                            ZIndex(10),
                            Name::new(format!("Count Background {}", slot_index)),
                        ))
                        .with_children(|count_parent| {
                            count_parent.spawn((
                                Text::new(content.count.to_string()),
                                TextFont {
                                    font: font_assets.rajdhani_bold.clone(),
                                    font_size: 20.0,
                                    ..default()
                                },
                                TextColor(Color::BLACK),
                                ItemCountText::new(slot_index),
                                Name::new(format!("Count Text {}", slot_index)),
                            ));
                        });
                }
            });
    });
}

/// Helper function to get the appropriate icon for an item type
fn get_item_icon(ui_assets: &UiAssets, item_type: CollectibleType) -> Handle<Image> {
    match item_type {
        CollectibleType::FirstAidKit => ui_assets.first_aid_kit.clone(),
        CollectibleType::Book => ui_assets.book.clone(),
    }
}

/// System to cleanup inventory UI when exiting gameplay
pub fn cleanup_inventory_ui(
    mut commands: Commands,
    inventory_ui_query: Query<Entity, With<GameplayInventoryUI>>,
) {
    for entity in inventory_ui_query.iter() {
        commands.entity(entity).despawn();
    }
}

/// Debug system to trace inventory events
pub fn debug_inventory_events(
    mut item_collected_events: EventReader<ItemCollectedEvent>,
    mut inventory_updated_events: EventReader<InventoryUpdatedEvent>,
    mut slot_changed_events: EventReader<InventorySlotChangedEvent>,
) {
    for event in item_collected_events.read() {
        debug!(
            "📦 DEBUG: ItemCollectedEvent detected! {:?} (amount: {}) collector: {:?}",
            event.item_type, event.amount, event.collector
        );
    }

    for event in inventory_updated_events.read() {
        debug!(
            "📦 DEBUG: InventoryUpdatedEvent detected! Player: {:?}, slot: {:?}, type: {:?}",
            event.player, event.slot_index, event.update_type
        );
    }

    for event in slot_changed_events.read() {
        debug!(
            "📦 DEBUG: InventorySlotChangedEvent detected! Player: {:?}, slot: {}, content: {:?}",
            event.player, event.slot_index, event.new_content
        );
    }
}

/// Event-based system to handle item collected events (backup for observers)
pub fn handle_item_collected_events(
    mut item_collected_events: EventReader<ItemCollectedEvent>,
    mut inventory_data: ResMut<InventoryData>,
    mut visibility_state: ResMut<InventoryVisibilityState>,
    mut inventory_updated_events: EventWriter<InventoryUpdatedEvent>,
) {
    for event in item_collected_events.read() {
        info!(
            "🎒 INVENTORY: Event-based system received ItemCollectedEvent for {:?} (amount: {})",
            event.item_type, event.amount
        );

        let inventory = inventory_data.get_or_create_inventory(event.collector);
        info!(
            "🎒 INVENTORY: Got inventory for player {:?}, current slots: {}",
            event.collector,
            inventory.get_used_slots()
        );

        match inventory.add_item(event.item_type, event.amount) {
            Ok(result) => {
                // Show inventory temporarily when item is collected
                visibility_state.show(false); // false = automatic display
                info!("🎒 INVENTORY: Item added successfully! Showing inventory with auto-hide timer...");

                // Send appropriate update event based on result
                let update_type = match result {
                    super::resources::InventoryAddResult::StackedExisting {
                        old_count,
                        new_count,
                        ..
                    } => InventoryUpdateType::ItemCountIncreased {
                        item_type: event.item_type,
                        old_count,
                        new_count,
                    },
                    super::resources::InventoryAddResult::NewSlot { count, .. } => {
                        InventoryUpdateType::ItemAdded {
                            item_type: event.item_type,
                            new_count: count,
                        }
                    }
                };

                let slot_index = match result {
                    super::resources::InventoryAddResult::StackedExisting {
                        slot_index, ..
                    }
                    | super::resources::InventoryAddResult::NewSlot { slot_index, .. } => {
                        Some(slot_index)
                    }
                };

                inventory_updated_events.write(InventoryUpdatedEvent {
                    player: event.collector,
                    slot_index,
                    update_type,
                });

                info!(
                    "Added {:?} x{} to inventory (slot: {:?})",
                    event.item_type, event.amount, slot_index
                );
            }
            Err(error) => {
                warn!("Failed to add item to inventory: {:?}", error);
                // TODO: Could emit a UI notification event here
            }
        }
    }
}

/// Event-based system to handle inventory updated events (backup for observers)
pub fn handle_inventory_updated_events(
    mut inventory_updated_events: EventReader<InventoryUpdatedEvent>,
    mut slot_change_events: EventWriter<InventorySlotChangedEvent>,
    inventory_data: Res<InventoryData>,
) {
    for event in inventory_updated_events.read() {
        info!(
            "🎒 INVENTORY: Event-based system received InventoryUpdatedEvent for player {:?}",
            event.player
        );

        if let Some(slot_index) = event.slot_index {
            if let Some(inventory) = inventory_data.get_inventory(event.player) {
                let new_content = inventory
                    .get_slot(slot_index)
                    .map(|slot| events::SlotContent {
                        item_type: slot.item_type,
                        count: slot.count,
                    });

                info!(
                    "🎒 INVENTORY: Sending InventorySlotChangedEvent for slot {} with content: {:?}",
                    slot_index, new_content
                );

                slot_change_events.write(InventorySlotChangedEvent {
                    player: event.player,
                    slot_index,
                    new_content,
                });
            }
        }
    }
}
