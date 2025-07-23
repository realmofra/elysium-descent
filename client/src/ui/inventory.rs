use bevy::prelude::*;

use crate::assets::FontAssets;
use crate::assets::UiAssets;
use crate::systems::collectibles::{CollectibleType, NextItemToAdd};

// Inventory UI marker
#[derive(Component)]
pub struct InventoryUI;

#[derive(Component)]
pub struct InventorySlot {
    pub index: usize,
}

#[derive(Component)]
pub struct InventoryItem {
    pub item_type: CollectibleType,
    pub count: usize,
}

#[derive(Component)]
pub struct CountText;

#[derive(Resource)]
pub struct InventoryVisibilityState {
    pub visible: bool,
    pub timer: Timer,
}

impl Default for InventoryVisibilityState {
    fn default() -> Self {
        Self {
            visible: false,
            timer: Timer::from_seconds(2.0, TimerMode::Once),
        }
    }
}

pub fn spawn_inventory_ui<T: Component + Default>(commands: &mut Commands) {
    use crate::ui::styles::ElysiumDescentColorPalette;
    commands
        .spawn((
            Node {
                width: Val::Px(1250.0),
                height: Val::Px(250.0),
                // Remove height so it fits children
                position_type: PositionType::Absolute,
                bottom: Val::Px(32.0),
                left: Val::Percent(50.0),
                margin: UiRect::left(Val::Px(-625.0)), // Center horizontally
                flex_direction: FlexDirection::Row,
                justify_content: JustifyContent::Center,
                align_items: AlignItems::Center,
                border: UiRect::all(Val::Px(2.0)),
                ..default()
            },
            BackgroundColor(Color::srgba(0.12, 0.14, 0.18, 0.85)), // glassy dark
            BorderColor(Color::ELYSIUM_DESCENT_BLUE),
            BorderRadius::all(Val::Px(32.0)),
            InventoryUI,
            Visibility::Hidden,
            T::default(),
        ))
        .with_children(|parent| {
            for i in 0..6 {
                parent.spawn((
                    Node {
                        width: Val::Px(180.0),
                        height: Val::Px(200.0),
                        margin: UiRect::all(Val::Px(12.0)),
                        padding: UiRect::horizontal(Val::Px(48.0)),
                        justify_content: JustifyContent::Center,
                        align_items: AlignItems::Center,
                        border: UiRect::all(Val::Px(2.0)),
                        ..default()
                    },
                    BackgroundColor(Color::srgba(0.18, 0.20, 0.26, 0.65)),
                    BorderColor(Color::ELYSIUM_DESCENT_RED),
                    BorderRadius::all(Val::Px(18.0)),
                    InventorySlot { index: i },
                ))
                .with_children(|slot| {
                    // Always add a filler node to ensure consistent sizing
                    slot.spawn((
                        Node {
                            width: Val::Px(140.0),
                            height: Val::Px(160.0),
                            justify_content: JustifyContent::Center,
                            align_items: AlignItems::Center,
                            ..default()
                        },
                        BackgroundColor(Color::NONE),
                        ZIndex(-2),
                    ));
                });
            }
        });
}

pub fn toggle_inventory_visibility(
    keyboard: Res<ButtonInput<KeyCode>>,
    mut state: ResMut<InventoryVisibilityState>,
    mut query: Query<&mut Visibility, With<InventoryUI>>,
    time: Res<Time>,
) {
    state.timer.tick(time.delta());

    if keyboard.just_pressed(KeyCode::KeyI) {
        for mut visibility in &mut query {
            *visibility = Visibility::Visible;
        }
        state.visible = true;
        state.timer.reset();
    }

    if state.visible && state.timer.finished() {
        for mut visibility in &mut query {
            *visibility = Visibility::Hidden;
        }
        state.visible = false;
    }
}

pub fn add_item_to_inventory(
    mut commands: Commands,
    mut slot_query: Query<(Entity, &InventorySlot)>,
    children_query: Query<&Children>,
    mut item_query: Query<&mut InventoryItem>,
    mut text_query: Query<&mut Text>,
    font_assets: Res<FontAssets>,
    ui_assets: Res<UiAssets>,
    collectible_type: Option<Res<NextItemToAdd>>,
    mut visibility_state: ResMut<InventoryVisibilityState>,
    mut ui_query: Query<&mut Visibility, With<InventoryUI>>,
) {
    let Some(collectible_type) = collectible_type else {
        return;
    };

    if let Ok(mut visibility) = ui_query.single_mut() {
        *visibility = Visibility::Visible;
        visibility_state.visible = true;
        visibility_state.timer.reset();
    }

    // First: look for a slot that already has this item
    for (slot_entity, _) in slot_query.iter_mut() {
        if let Ok(children) = children_query.get(slot_entity) {
            for child in children.iter() {
                if let Ok(mut item) = item_query.get_mut(child) {
                    if item.item_type == collectible_type.0 {
                        // Found matching item → increase count
                        item.count += 1;

                        // Now do some iterations to update the text count
                        if let Ok(grandchildren) = children_query.get(child) {
                            if let Ok(grand_grandchildren) = children_query.get(grandchildren[1]) {
                                if let Some(&leaf) = grand_grandchildren.first() {
                                    if let Ok(mut text) = text_query.get_mut(leaf) {
                                        text.clear();
                                        text.push_str(&item.count.to_string());
                                    }
                                }
                            }
                        };

                        commands.remove_resource::<NextItemToAdd>();
                        return;
                    }
                }
            }
        }
    }

    // Otherwise: find first empty slot and add the item
    let mut sorted_slots: Vec<(Entity, &InventorySlot)> = slot_query.iter_mut().collect();
    sorted_slots.sort_by_key(|(_, slot)| slot.index);
    for (slot_entity, _) in sorted_slots {
        let is_empty = children_query
            .get(slot_entity)
            .map_or(true, |c| c.is_empty());
        if is_empty {
            commands.entity(slot_entity).with_children(|parent| {
                parent
                    .spawn((
                        Node {
                            width: Val::Percent(100.0),
                            height: Val::Percent(100.0),
                            align_items: AlignItems::Center,
                            justify_content: JustifyContent::Center,
                            ..default()
                        },
                        ZIndex(-1),
                        InventoryItem {
                            item_type: collectible_type.0,
                            count: 1,
                        },
                    ))
                    .with_children(|item_parent| {
                        // spawn the image (large, centered)
                        item_parent.spawn((
                            Node {
                                width: Val::Px(140.0),
                                height: Val::Px(160.0),
                                justify_content: JustifyContent::Center,
                                align_items: AlignItems::Center,
                                ..default()
                            },
                            ImageNode {
                                image: match collectible_type.0 {
                                    CollectibleType::Coin => ui_assets.coin.clone(),
                                    CollectibleType::MysteryBox => ui_assets.coin.clone(), // Use coin image as placeholder, or add a mystery_box image if available
                                },
                                ..default()
                            },
                            ZIndex(1),
                        ));

                        // Spawn count text (large, pill, bottom right)
                        item_parent
                            .spawn((
                                Node {
                                    position_type: PositionType::Absolute,
                                    width: Val::Percent(38.0),
                                    height: Val::Percent(48.0),
                                    right: Val::Percent(2.0),
                                    bottom: Val::Percent(2.0),
                                    align_items: AlignItems::Center,
                                    justify_content: JustifyContent::Center,
                                    ..default()
                                },
                                BorderRadius::MAX,
                                BackgroundColor(Color::srgba(1.0, 1.0, 1.0, 0.92)),
                                ZIndex(2),
                            ))
                            .with_children(|text_parent| {
                                text_parent.spawn((
                                    TextFont {
                                        font_size: 34.0,
                                        font: font_assets.rajdhani_extra_bold.clone(),
                                        ..default()
                                    },
                                    Text::new("1"),
                                    TextColor(Color::BLACK),
                                    CountText,
                                ));
                            });
                    });
            });

            commands.remove_resource::<NextItemToAdd>();
            return;
        }
    }
}
