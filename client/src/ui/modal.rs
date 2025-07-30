use bevy::prelude::*;
use crate::assets::{FontAssets, UiAssets};
use crate::ui::styles::ElysiumDescentColorPalette;
use crate::systems::objectives::ObjectiveManager;
use bevy::input::mouse::{MouseScrollUnit, MouseWheel};

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

#[derive(Component)]
pub struct QuestEntriesContainer;

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
    println!("🎯 Spawning objectives modal...");
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
            // Main modal panel - positioned higher and more compact
            parent.spawn((
                Node {
                    width: Val::Px(900.0),
                    height: Val::Px(600.0),
                    flex_direction: FlexDirection::Column,
                    justify_content: JustifyContent::FlexStart,
                    align_items: AlignItems::Center,
                    border: UiRect::all(Val::Px(1.0)), // Thin gold border
                    padding: UiRect::all(Val::Px(20.0)),
                    margin: UiRect::top(Val::Px(-50.0)),
                    ..default()
                },
                BackgroundColor(Color::srgba(0.08, 0.10, 0.14, 0.95)), // Darker background
                BorderColor(Color::ELYSIUM_GOLD),
                BorderRadius::all(Val::Px(8.0)),
                ModalContent,
            ))
            .with_children(|modal| {
                // Decorative corner elements (gold infinity symbols)
                // Top-left corner
                modal.spawn((
                    Node {
                        position_type: PositionType::Absolute,
                        top: Val::Px(5.0),
                        left: Val::Px(5.0),
                        width: Val::Px(25.0),
                        height: Val::Px(25.0),
                        justify_content: JustifyContent::Center,
                        align_items: AlignItems::Center,
                        ..default()
                    },
                    children![(
                        Text::new("∞"),
                        TextFont {
                            font_size: 16.0,
                            ..default()
                        },
                        TextColor(Color::ELYSIUM_GOLD),
                    )]
                ));
                
                // Top-right corner
                modal.spawn((
                    Node {
                        position_type: PositionType::Absolute,
                        top: Val::Px(5.0),
                        right: Val::Px(5.0),
                        width: Val::Px(25.0),
                        height: Val::Px(25.0),
                        justify_content: JustifyContent::Center,
                        align_items: AlignItems::Center,
                        ..default()
                    },
                    children![(
                        Text::new("∞"),
                        TextFont {
                            font_size: 16.0,
                            ..default()
                        },
                        TextColor(Color::ELYSIUM_GOLD),
                    )]
                ));
                
                // Bottom-left corner
                modal.spawn((
                    Node {
                        position_type: PositionType::Absolute,
                        bottom: Val::Px(5.0),
                        left: Val::Px(5.0),
                        width: Val::Px(25.0),
                        height: Val::Px(25.0),
                        justify_content: JustifyContent::Center,
                        align_items: AlignItems::Center,
                        ..default()
                    },
                    children![(
                        Text::new("∞"),
                        TextFont {
                            font_size: 16.0,
                            ..default()
                        },
                        TextColor(Color::ELYSIUM_GOLD),
                    )]
                ));
                
                // Bottom-right corner
                modal.spawn((
                    Node {
                        position_type: PositionType::Absolute,
                        bottom: Val::Px(5.0),
                        right: Val::Px(5.0),
                        width: Val::Px(25.0),
                        height: Val::Px(25.0),
                        justify_content: JustifyContent::Center,
                        align_items: AlignItems::Center,
                        ..default()
                    },
                    children![(
                        Text::new("∞"),
                        TextFont {
                            font_size: 16.0,
                            ..default()
                        },
                        TextColor(Color::ELYSIUM_GOLD),
                    )]
                ));
                
                // Navigation tabs - more prominent
                let tabs = ["INVENTORY", "QUESTS", "CONTROLLER", "SETTINGS", "STATS"];
                modal.spawn((
                    Node {
                        width: Val::Percent(100.0),
                        height: Val::Px(50.0),
                        flex_direction: FlexDirection::Row,
                        justify_content: JustifyContent::SpaceEvenly,
                        align_items: AlignItems::Center,
                        margin: UiRect::bottom(Val::Px(30.0)),
                        ..default()
                    },
                ))
                .with_children(|tabs_parent| {
                    // Spawn each tab
                    for (_i, tab_name) in tabs.iter().enumerate() {
                        let is_active = *tab_name == "QUESTS";
                        tabs_parent.spawn((
                            Node {
                                padding: UiRect::all(Val::Px(12.0)),
                                border: if is_active { UiRect::bottom(Val::Px(2.0)) } else { UiRect::all(Val::Px(0.0)) },
                                ..default()
                            },
                            BackgroundColor(if is_active { 
                                Color::srgba(0.15, 0.17, 0.21, 0.8) 
                            } else { 
                                Color::NONE 
                            }),
                            BorderColor(Color::ELYSIUM_GOLD),
                            NavigationTab {
                                tab_name: tab_name.to_string(),
                                is_active,
                            },
                        ))
                        .with_children(|tab| {
                            tab.spawn((
                                Text::new(*tab_name),
                                TextFont {
                                    font: font_assets.rajdhani_medium.clone(),
                                    font_size: 18.0,
                                    ..default()
                                },
                                TextColor(if is_active { Color::ELYSIUM_GOLD } else { Color::WHITE.with_alpha(0.7) }),
                            ));
                        });
                    }
                });
                
                // Title section with horizontal line and infinity symbol
                modal.spawn((
                    Node {
                        width: Val::Percent(100.0),
                        height: Val::Px(80.0),
                        justify_content: JustifyContent::Center,
                        align_items: AlignItems::Center,
                        margin: UiRect::bottom(Val::Px(30.0)),
                        ..default()
                    },
                    children![
                        // Main title with line underneath
                        (
                            Node {
                                flex_direction: FlexDirection::Column,
                                justify_content: JustifyContent::Center,
                                align_items: AlignItems::Center,
                                ..default()
                            },
                            children![
                                // Title text
                                (
                                    Text::new("QUESTS"),
                                    TextFont {
                                        font: font_assets.rajdhani_bold.clone(),
                                        font_size: 36.0,
                                        ..default()
                                    },
                                    TextColor(Color::WHITE),
                                    Node {
                                        margin: UiRect::bottom(Val::Px(15.0)),
                                        ..default()
                                    },
                                ),
                                // Horizontal line with infinity symbol underneath
                                (
                                    Node {
                                        width: Val::Px(200.0),
                                        height: Val::Px(2.0),
                                        justify_content: JustifyContent::Center,
                                        align_items: AlignItems::Center,
                                        position_type: PositionType::Relative,
                                        ..default()
                                    },
                                    BackgroundColor(Color::ELYSIUM_GOLD),
                                    children![
                                        (
                                            Text::new("∞"),
                                            TextFont {
                                                font_size: 14.0,
                                                ..default()
                                            },
                                            TextColor(Color::ELYSIUM_GOLD),
                                            Node {
                                                position_type: PositionType::Absolute,
                                                padding: UiRect::horizontal(Val::Px(8.0)),
                                                ..default()
                                            },
                                            BackgroundColor(Color::srgba(0.08, 0.10, 0.14, 0.95)),
                                        )
                                    ]
                                )
                            ]
                        )
                    ]
                ));
                
                // Quest list container with proper scrollbar - more compact
                modal.spawn((
                    Node {
                        width: Val::Percent(100.0),
                        height: Val::Px(350.0), // Reduced height
                        flex_direction: FlexDirection::Row,
                        justify_content: JustifyContent::SpaceBetween,
                        align_items: AlignItems::FlexStart,
                        padding: UiRect::all(Val::Px(10.0)),
                        border: UiRect::all(Val::Px(1.0)),
                        ..default()
                    },
                    BackgroundColor(Color::srgba(0.05, 0.07, 0.11, 0.8)),
                    BorderColor(Color::ELYSIUM_GOLD.with_alpha(0.3)),
                    BorderRadius::all(Val::Px(6.0)),
                    children![
                        // Quest entries container - scrollable
                        (
                            Node {
                                width: Val::Px(820.0),
                                height: Val::Px(330.0), // Reduced height
                                flex_direction: FlexDirection::Column,
                                justify_content: JustifyContent::FlexStart,
                                align_items: AlignItems::Center,
                                padding: UiRect::all(Val::Px(10.0)),
                                overflow: Overflow::scroll_y(), // Enable vertical scrolling
                                ..default()
                            },
                            QuestEntriesContainer,
                            children![
                                // Quest entries will be spawned here dynamically
                            ]
                        ),
                        // Scrollbar
                        (
                            Node {
                                width: Val::Px(6.0),
                                height: Val::Px(330.0),
                                margin: UiRect::right(Val::Px(8.0)),
                                ..default()
                            },
                            BackgroundColor(Color::srgba(0.2, 0.2, 0.2, 0.8)),
                            BorderRadius::all(Val::Px(3.0)),
                        )
                    ]
                ));
            });
        });
}

pub fn update_quest_list(
    mut commands: Commands,
    _objective_manager: Res<ObjectiveManager>,
    font_assets: Option<Res<FontAssets>>,
    ui_assets: Option<Res<UiAssets>>,
    quest_container_query: Query<Entity, With<QuestEntriesContainer>>,
    existing_quests: Query<Entity, With<QuestEntry>>,
) {
    let Some(font_assets) = font_assets else { return; };
    let Some(ui_assets) = ui_assets else { return; };

    let Some(quest_container_entity) = quest_container_query.iter().next() else { return; };

    // Clear existing quest entries
    for entity in existing_quests.iter() {
        commands.entity(entity).despawn();
    }

    // Create 10 quests total - use existing objectives plus additional ones
    let quest_titles = [
        "COLLECT HEALTH POTIONS",
        "FIND SURVIVAL KITS", 
        "GATHER ANCIENT BOOKS",
        "COLLECT GOLDEN COINS",
        "EXPLORE ANCIENT RUINS",
        "DEFEAT DARK CREATURES",
        "RETRIEVE LOST ARTIFACTS",
        "MASTER THE ELEMENTS",
        "UNLOCK HIDDEN PASSAGES",
        "RESTORE THE TEMPLE"
    ];
    
    let quest_descriptions = [
        "Collect 5 health potions scattered throughout the realm.",
        "Find 3 survival kits hidden in the wilderness.",
        "Gather 7 ancient books from the library ruins.",
        "Collect 10 golden coins from fallen enemies.",
        "Explore 4 ancient ruins and discover their secrets.",
        "Defeat 8 dark creatures that roam the shadows.",
        "Retrieve 6 lost artifacts from the depths.",
        "Master the four elements: fire, water, earth, and air.",
        "Unlock 5 hidden passages throughout the realm.",
        "Restore the ancient temple to its former glory."
    ];

    // Spawn 10 quests
    for i in 0..10 {
        let quest_objective = crate::systems::objectives::Objective {
            id: i,
            title: quest_titles[i].to_string(),
            description: quest_descriptions[i].to_string(),
            item_type: crate::systems::collectibles::CollectibleType::Coin,
            required_count: ((i + 1) * 2) as u32,
            current_count: if i < 2 { ((i + 1) * 2) as u32 } else { 0 }, // First 2 are completed
            completed: i < 2,
        };
        
        let quest_entity = spawn_quest_entry(&mut commands, &quest_objective, &font_assets, &ui_assets, i);
        commands.entity(quest_container_entity).add_child(quest_entity);
    }
}

fn spawn_quest_entry(
    commands: &mut Commands,
    objective: &crate::systems::objectives::Objective,
    font_assets: &Res<FontAssets>,
    ui_assets: &Res<UiAssets>,
    index: usize,
) -> Entity {
    let is_active = index < 2; // First two quests are active (lighter background)
    
    commands.spawn((
        Node {
            width: Val::Percent(100.0),
            height: Val::Px(85.0), // More compact height
            flex_direction: FlexDirection::Row,
            justify_content: JustifyContent::SpaceBetween,
            align_items: AlignItems::Center,
            margin: UiRect::bottom(Val::Px(8.0)), // Reduced margin
            padding: UiRect::all(Val::Px(15.0)), // Reduced padding
            border: UiRect::all(Val::Px(1.0)),
            ..default()
        },
        BackgroundColor(if is_active { 
            Color::srgba(0.12, 0.14, 0.18, 0.8) 
        } else { 
            Color::srgba(0.08, 0.10, 0.14, 0.6) 
        }),
        BorderColor(Color::ELYSIUM_GOLD.with_alpha(0.2)),
        BorderRadius::all(Val::Px(6.0)),
        QuestEntry { quest_id: objective.id },
        children![
            // Quest icon (coin image)
            (
                Node {
                    width: Val::Px(70.0), // Larger icon
                    height: Val::Px(70.0), // Larger icon
                    justify_content: JustifyContent::Center,
                    align_items: AlignItems::Center,
                    margin: UiRect::right(Val::Px(-70.0)), // Much smaller margin to bring text very close
                    ..default()
                },
                ImageNode {
                    image: ui_assets.coin.clone(),
                    ..default()
                },
                QuestIcon,
            ),
            // Quest info (title and description)
            (
                Node {
                    flex_direction: FlexDirection::Column,
                    justify_content: JustifyContent::Center, // Center like the reward section
                    align_items: AlignItems::FlexStart,
                    width: Val::Px(450.0), // Reduced width
                    height: Val::Px(65.0), // Reduced height
                    margin: UiRect::right(Val::Px(15.0)),
                    ..default()
                },
                children![
                    // Quest title
                    (
                        Text::new(&objective.title),
                        TextFont {
                            font: font_assets.rajdhani_bold.clone(),
                            font_size: 18.0, // Smaller font
                            ..default()
                        },
                        TextColor(Color::WHITE),
                        Node {
                            margin: UiRect::bottom(Val::Px(6.0)), // Reduced margin
                            ..default()
                        },
                    ),
                    // Quest description
                    (
                        Text::new(&objective.description),
                        TextFont {
                            font: font_assets.rajdhani_medium.clone(),
                            font_size: 14.0, // Smaller font
                            ..default()
                        },
                        TextColor(Color::WHITE.with_alpha(0.7)),
                    )
                ]
            ),
            // Quest reward section
            (
                Node {
                    flex_direction: FlexDirection::Column,
                    justify_content: JustifyContent::Center,
                    align_items: AlignItems::FlexEnd,
                    width: Val::Px(150.0), // Reduced width
                    height: Val::Px(65.0), // Reduced height
                    ..default()
                },
                children![
                    // Reward label
                    (
                        Text::new("REWARD"),
                        TextFont {
                            font: font_assets.rajdhani_medium.clone(),
                            font_size: 12.0, // Smaller font
                            ..default()
                        },
                        TextColor(Color::WHITE.with_alpha(0.6)),
                        Node {
                            margin: UiRect::bottom(Val::Px(4.0)), // Reduced margin
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
                                    width: Val::Px(30.0), // Slightly larger but still small
                                    height: Val::Px(30.0), // Slightly larger but still small
                                    justify_content: JustifyContent::Center,
                                    align_items: AlignItems::Center,
                                    margin: UiRect::right(Val::Px(4.0)), // Reduced margin to bring coin closer to text
                                    ..default()
                                },
                                ImageNode {
                                    image: ui_assets.coin.clone(),
                                    ..default()
                                },
                                QuestReward,
                            ),
                            // Reward amount
                            (
                                Text::new(format!("{} Gold", (objective.id + 1) * 250)),
                                TextFont {
                                    font: font_assets.rajdhani_medium.clone(),
                                    font_size: 16.0, // Smaller font
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
    mut interaction_query: Query<(&Interaction, &Name), Changed<Interaction>>,
) {
    println!("🔍 Checking for View More button interactions...");
    for (interaction, name) in &mut interaction_query {
        println!("🔍 Found interaction: {:?} for component: {}", interaction, name.as_str());
        if name.as_str() == "View More Button" {
            println!("🎯 Found View More Button! Interaction: {:?}", interaction);
            match *interaction {
                Interaction::Pressed => {
                    println!("🎯 Modal opened! View More button clicked");
                    modal_state.visible = true;
                    for mut visibility in &mut background_query {
                        *visibility = Visibility::Visible;
                    }
                }
                Interaction::Hovered => {
                    println!("🎯 View More button hovered");
                    // No hover effect - removed
                }
                Interaction::None => {
                    // No background color change - removed
                }
            }
        }
    }
}

pub fn update_scroll_position(
    mut mouse_wheel_events: EventReader<MouseWheel>,
    mut query: Query<&mut bevy::ui::ScrollPosition>,
) {
    for event in mouse_wheel_events.read() {
        for mut scroll in &mut query {
            let dy = match event.unit {
                MouseScrollUnit::Line => event.y * 20.0,
                MouseScrollUnit::Pixel => event.y,
            };
            scroll.offset_y -= dy;
        }
    }
}

pub fn despawn_modal(mut commands: Commands, query: Query<Entity, With<ModalBackground>>) {
    for entity in &query {
        commands.entity(entity).despawn();
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
                update_scroll_position,
            ));
    }
} 