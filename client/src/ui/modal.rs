use bevy::prelude::*;
use crate::assets::{FontAssets, UiAssets};
use crate::ui::styles::ElysiumDescentColorPalette;
use crate::systems::objectives::ObjectiveManager;

// ===== MODAL COMPONENTS =====

#[derive(Component)]
pub struct ModalUI;

#[derive(Component)]
pub struct ModalBackground;

#[derive(Component)]
pub struct ModalContent;

#[derive(Component)]
pub struct NavigationTab {
    pub tab_name: String,
    pub is_active: bool,
}

#[derive(Component)]
pub struct QuestEntry {
    pub quest_id: usize,
}

#[derive(Component)]
pub struct QuestIcon;

#[derive(Component)]
pub struct QuestReward;

#[derive(Resource)]
pub struct ModalState {
    pub visible: bool,
    pub active_tab: String,
}

impl Default for ModalState {
    fn default() -> Self {
        Self {
            visible: false,
            active_tab: "QUESTS".to_string(),
        }
    }
}

// ===== MODAL SYSTEMS =====

pub fn spawn_objectives_modal(commands: &mut Commands, font_assets: &Res<FontAssets>, _ui_assets: &Res<UiAssets>) {
    commands
        .spawn((
            Node {
                width: Val::Percent(100.0),
                height: Val::Percent(100.0),
                position_type: PositionType::Absolute,
                top: Val::Px(0.0),
                left: Val::Px(0.0),
                justify_content: JustifyContent::Center,
                align_items: AlignItems::Center,
                ..default()
            },
            BackgroundColor(Color::srgba(0.0, 0.0, 0.0, 0.7)), // Semi-transparent background
            ModalBackground,
            Visibility::Hidden,
        ))
        .with_children(|parent| {
            // Main modal panel
            parent.spawn((
                Node {
                    width: Val::Px(900.0),
                    height: Val::Px(600.0),
                    flex_direction: FlexDirection::Column,
                    justify_content: JustifyContent::FlexStart,
                    align_items: AlignItems::Center,
                    border: UiRect::all(Val::Px(2.0)),
                    padding: UiRect::all(Val::Px(20.0)),
                    ..default()
                },
                BackgroundColor(Color::srgba(0.12, 0.14, 0.18, 0.95)), // Dark greenish-grey
                BorderColor(Color::ELYSIUM_GOLD),
                BorderRadius::all(Val::Px(15.0)),
                ModalContent,
            ))
            .with_children(|modal| {
                // Decorative corner elements (gold infinity symbols)
                // Top-left corner
                modal.spawn((
                    Node {
                        position_type: PositionType::Absolute,
                        top: Val::Px(10.0),
                        left: Val::Px(10.0),
                        width: Val::Px(30.0),
                        height: Val::Px(30.0),
                        justify_content: JustifyContent::Center,
                        align_items: AlignItems::Center,
                        ..default()
                    },
                    children![(
                        Text::new("∞"),
                        TextFont {
                            font_size: 20.0,
                            ..default()
                        },
                        TextColor(Color::ELYSIUM_GOLD),
                    )]
                ));
                
                // Top-right corner
                modal.spawn((
                    Node {
                        position_type: PositionType::Absolute,
                        top: Val::Px(10.0),
                        right: Val::Px(10.0),
                        width: Val::Px(30.0),
                        height: Val::Px(30.0),
                        justify_content: JustifyContent::Center,
                        align_items: AlignItems::Center,
                        ..default()
                    },
                    children![(
                        Text::new("∞"),
                        TextFont {
                            font_size: 20.0,
                            ..default()
                        },
                        TextColor(Color::ELYSIUM_GOLD),
                    )]
                ));
                
                // Bottom-left corner
                modal.spawn((
                    Node {
                        position_type: PositionType::Absolute,
                        bottom: Val::Px(10.0),
                        left: Val::Px(10.0),
                        width: Val::Px(30.0),
                        height: Val::Px(30.0),
                        justify_content: JustifyContent::Center,
                        align_items: AlignItems::Center,
                        ..default()
                    },
                    children![(
                        Text::new("∞"),
                        TextFont {
                            font_size: 20.0,
                            ..default()
                        },
                        TextColor(Color::ELYSIUM_GOLD),
                    )]
                ));
                
                // Bottom-right corner
                modal.spawn((
                    Node {
                        position_type: PositionType::Absolute,
                        bottom: Val::Px(10.0),
                        right: Val::Px(10.0),
                        width: Val::Px(30.0),
                        height: Val::Px(30.0),
                        justify_content: JustifyContent::Center,
                        align_items: AlignItems::Center,
                        ..default()
                    },
                    children![(
                        Text::new("∞"),
                        TextFont {
                            font_size: 20.0,
                            ..default()
                        },
                        TextColor(Color::ELYSIUM_GOLD),
                    )]
                ));
                
                // Navigation tabs
                let tabs = ["INVENTORY", "QUESTS", "CONTROLLER", "SETTINGS", "STATS"];
                modal.spawn((
                    Node {
                        width: Val::Percent(100.0),
                        height: Val::Px(40.0),
                        flex_direction: FlexDirection::Row,
                        justify_content: JustifyContent::SpaceEvenly,
                        align_items: AlignItems::Center,
                        margin: UiRect::bottom(Val::Px(20.0)),
                        ..default()
                    },
                ))
                .with_children(|tabs_parent| {
                    // Spawn each tab
                    for (_i, tab_name) in tabs.iter().enumerate() {
                        tabs_parent.spawn((
                            Node {
                                padding: UiRect::all(Val::Px(8.0)),
                                border: if *tab_name == "QUESTS" { UiRect::all(Val::Px(1.0)) } else { UiRect::all(Val::Px(0.0)) },
                                ..default()
                            },
                            BackgroundColor(if *tab_name == "QUESTS" { 
                                Color::srgba(0.18, 0.20, 0.26, 0.8) 
                            } else { 
                                Color::NONE 
                            }),
                            BorderColor(Color::ELYSIUM_GOLD),
                            BorderRadius::all(Val::Px(5.0)),
                            NavigationTab {
                                tab_name: tab_name.to_string(),
                                is_active: *tab_name == "QUESTS",
                            },
                        ))
                        .with_children(|tab| {
                            tab.spawn((
                                Text::new(*tab_name),
                                TextFont {
                                    font: font_assets.rajdhani_medium.clone(),
                                    font_size: 16.0,
                                    ..default()
                                },
                                TextColor(Color::WHITE),
                            ));
                        });
                    }
                });
                
                // Title section
                modal.spawn((
                    Node {
                        width: Val::Percent(100.0),
                        height: Val::Px(60.0),
                        justify_content: JustifyContent::Center,
                        align_items: AlignItems::Center,
                        margin: UiRect::bottom(Val::Px(20.0)),
                        ..default()
                    },
                    children![
                        // Main title
                        (
                            Text::new("QUESTS"),
                            TextFont {
                                font: font_assets.rajdhani_bold.clone(),
                                font_size: 32.0,
                                ..default()
                            },
                            TextColor(Color::WHITE),
                            Node {
                                margin: UiRect::bottom(Val::Px(5.0)),
                                ..default()
                            },
                        ),
                        // Decorative symbol below title
                        (
                            Text::new("∞"),
                            TextFont {
                                font_size: 16.0,
                                ..default()
                            },
                            TextColor(Color::ELYSIUM_GOLD),
                        )
                    ]
                ));
                
                // Quest list container with scrollbar
                modal.spawn((
                    Node {
                        width: Val::Percent(100.0),
                        height: Val::Px(400.0),
                        flex_direction: FlexDirection::Row,
                        justify_content: JustifyContent::SpaceBetween,
                        align_items: AlignItems::FlexStart,
                        padding: UiRect::all(Val::Px(10.0)),
                        border: UiRect::all(Val::Px(1.0)),
                        ..default()
                    },
                    BackgroundColor(Color::srgba(0.08, 0.10, 0.14, 0.5)),
                    BorderColor(Color::ELYSIUM_GOLD.with_alpha(0.3)),
                    BorderRadius::all(Val::Px(10.0)),
                    children![
                        // Quest entries container
                        (
                            Node {
                                width: Val::Px(850.0),
                                height: Val::Px(380.0),
                                flex_direction: FlexDirection::Column,
                                justify_content: JustifyContent::FlexStart,
                                align_items: AlignItems::Center,
                                padding: UiRect::all(Val::Px(10.0)),
                                ..default()
                            },
                            children![
                                // Quest entries will be spawned here dynamically
                            ]
                        ),
                        // Scrollbar
                        (
                            Node {
                                width: Val::Px(8.0),
                                height: Val::Px(380.0),
                                margin: UiRect::right(Val::Px(5.0)),
                                ..default()
                            },
                            BackgroundColor(Color::srgba(0.3, 0.3, 0.3, 0.5)),
                            BorderRadius::all(Val::Px(4.0)),
                        )
                    ]
                ));
            });
        });
}

pub fn update_quest_list(
    mut commands: Commands,
    objective_manager: Res<ObjectiveManager>,
    font_assets: Option<Res<FontAssets>>,
    ui_assets: Option<Res<UiAssets>>,
    modal_query: Query<Entity, With<ModalContent>>,
    existing_quests: Query<Entity, With<QuestEntry>>,
) {
    if !objective_manager.is_changed() {
        return;
    }

    let Some(font_assets) = font_assets else { return; };
    let Some(ui_assets) = ui_assets else { return; };

    let Some(modal_entity) = modal_query.iter().next() else { return; };

    // Clear existing quest entries
    for entity in existing_quests.iter() {
        commands.entity(entity).despawn();
    }

    // For now, just spawn quest entries directly in the modal
    for (i, objective) in objective_manager.objectives.iter().enumerate() {
        let quest_entity = spawn_quest_entry(&mut commands, objective, &font_assets, &ui_assets, i);
        commands.entity(modal_entity).add_child(quest_entity);
    }
}

fn spawn_quest_entry(
    commands: &mut Commands,
    objective: &crate::systems::objectives::Objective,
    font_assets: &Res<FontAssets>,
    _ui_assets: &Res<UiAssets>,
    index: usize,
) -> Entity {
    let is_active = index < 2; // First two quests are active (lighter background)
    
    commands.spawn((
        Node {
            width: Val::Percent(100.0),
            height: Val::Px(100.0),
            flex_direction: FlexDirection::Row,
            justify_content: JustifyContent::SpaceBetween,
            align_items: AlignItems::Center,
            margin: UiRect::bottom(Val::Px(10.0)),
            padding: UiRect::all(Val::Px(15.0)),
            border: UiRect::all(Val::Px(1.0)),
            ..default()
        },
        BackgroundColor(if is_active { 
            Color::srgba(0.15, 0.17, 0.21, 0.8) 
        } else { 
            Color::srgba(0.10, 0.12, 0.16, 0.6) 
        }),
        BorderColor(Color::ELYSIUM_GOLD.with_alpha(0.3)),
        BorderRadius::all(Val::Px(8.0)),
        QuestEntry { quest_id: objective.id },
        children![
            // Quest icon (golden circle with infinity symbol)
            (
                Node {
                    width: Val::Px(50.0),
                    height: Val::Px(50.0),
                    justify_content: JustifyContent::Center,
                    align_items: AlignItems::Center,
                    border: UiRect::all(Val::Px(2.0)),
                    margin: UiRect::right(Val::Px(15.0)),
                    ..default()
                },
                BackgroundColor(Color::srgba(0.875, 0.667, 0.176, 0.9)), // Gold circle
                BorderColor(Color::ELYSIUM_GOLD),
                BorderRadius::all(Val::Px(25.0)),
                QuestIcon,
                children![
                    (
                        Text::new("∞"),
                        TextFont {
                            font_size: 20.0,
                            ..default()
                        },
                        TextColor(Color::srgba(0.1, 0.1, 0.1, 1.0)), // Dark text on gold
                    )
                ]
            ),
            // Quest info (title and description)
            (
                Node {
                    flex_direction: FlexDirection::Column,
                    justify_content: JustifyContent::FlexStart,
                    align_items: AlignItems::FlexStart,
                    width: Val::Px(500.0),
                    height: Val::Px(70.0),
                    margin: UiRect::right(Val::Px(15.0)),
                    ..default()
                },
                children![
                    // Quest title
                    (
                        Text::new(&objective.title),
                        TextFont {
                            font: font_assets.rajdhani_bold.clone(),
                            font_size: 18.0,
                            ..default()
                        },
                        TextColor(Color::WHITE),
                        Node {
                            margin: UiRect::bottom(Val::Px(8.0)),
                            ..default()
                        },
                    ),
                    // Quest description
                    (
                        Text::new(&objective.description),
                        TextFont {
                            font: font_assets.rajdhani_medium.clone(),
                            font_size: 14.0,
                            ..default()
                        },
                        TextColor(Color::WHITE.with_alpha(0.8)),
                    )
                ]
            ),
            // Quest reward section
            (
                Node {
                    flex_direction: FlexDirection::Column,
                    justify_content: JustifyContent::Center,
                    align_items: AlignItems::FlexEnd,
                    width: Val::Px(150.0),
                    height: Val::Px(70.0),
                    ..default()
                },
                children![
                    // Reward label
                    (
                        Text::new("REWARD"),
                        TextFont {
                            font: font_assets.rajdhani_medium.clone(),
                            font_size: 12.0,
                            ..default()
                        },
                        TextColor(Color::WHITE.with_alpha(0.7)),
                        Node {
                            margin: UiRect::bottom(Val::Px(5.0)),
                            ..default()
                        },
                    ),
                    // Reward icon and amount
                    (
                        Node {
                            flex_direction: FlexDirection::Row,
                            justify_content: JustifyContent::FlexEnd,
                            align_items: AlignItems::Center,
                            ..default()
                        },
                        children![
                            // Reward coin icon
                            (
                                Node {
                                    width: Val::Px(25.0),
                                    height: Val::Px(25.0),
                                    justify_content: JustifyContent::Center,
                                    align_items: AlignItems::Center,
                                    border: UiRect::all(Val::Px(1.0)),
                                    margin: UiRect::right(Val::Px(8.0)),
                                    ..default()
                                },
                                BackgroundColor(Color::srgba(0.875, 0.667, 0.176, 0.9)),
                                BorderColor(Color::ELYSIUM_GOLD),
                                BorderRadius::all(Val::Px(12.5)),
                                QuestReward,
                                children![
                                    (
                                        Text::new("∞"),
                                        TextFont {
                                            font_size: 12.0,
                                            ..default()
                                        },
                                        TextColor(Color::srgba(0.1, 0.1, 0.1, 1.0)),
                                    )
                                ]
                            ),
                            // Reward amount
                            (
                                Text::new(format!("{} Gold", (objective.id + 1) * 250)),
                                TextFont {
                                    font: font_assets.rajdhani_medium.clone(),
                                    font_size: 16.0,
                                    ..default()
                                },
                                TextColor(Color::ELYSIUM_GOLD),
                            )
                        ]
                    )
                ]
            )
        ]
    )).id()
}

pub fn toggle_modal_visibility(
    mut modal_state: ResMut<ModalState>,
    mut background_query: Query<&mut Visibility, With<ModalBackground>>,
    keyboard: Res<ButtonInput<KeyCode>>,
) {
    // Toggle modal with Escape key
    if keyboard.just_pressed(KeyCode::Escape) {
        modal_state.visible = !modal_state.visible;
        
        if modal_state.visible {
            println!("🎯 Modal opened with ESC key");
        } else {
            println!("🎯 Modal closed with ESC key");
        }
        
        for mut visibility in &mut background_query {
            *visibility = if modal_state.visible { 
                Visibility::Visible 
            } else { 
                Visibility::Hidden 
            };
        }
    }
}

pub fn handle_view_more_click(
    mut modal_state: ResMut<ModalState>,
    mut background_query: Query<&mut Visibility, With<ModalBackground>>,
    mut interaction_query: Query<(&Interaction, &mut BackgroundColor, &Name), Changed<Interaction>>,
) {
    for (interaction, mut background_color, name) in &mut interaction_query {
        if name.as_str() == "View More Button" {
            match *interaction {
                Interaction::Pressed => {
                    println!("🎯 Modal opened! View More button clicked");
                    modal_state.visible = true;
                    for mut visibility in &mut background_query {
                        *visibility = Visibility::Visible;
                    }
                }
                Interaction::Hovered => {
                    *background_color = BackgroundColor(Color::ELYSIUM_GOLD.with_alpha(0.3));
                }
                Interaction::None => {
                    *background_color = BackgroundColor(Color::NONE);
                }
            }
        }
    }
}

// ===== MODAL PLUGIN =====

pub struct ModalPlugin;

impl Plugin for ModalPlugin {
    fn build(&self, app: &mut App) {
        app.init_resource::<ModalState>()
            .add_systems(Update, (
                toggle_modal_visibility,
                handle_view_more_click,
                update_quest_list,
            ));
    }
} 