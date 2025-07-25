use bevy::prelude::*;
use serde::{Deserialize, Serialize};

use crate::screens::Screen;
use crate::systems::collectibles::CollectibleType;
use crate::ui::styles::ElysiumDescentColorPalette;

// ===== COMPONENTS & RESOURCES =====

#[derive(Component)]
pub struct ObjectiveUI;

#[derive(Component)]
pub struct ObjectiveSlot {
    // Removed unused objective_id field
}

#[derive(Component)]
pub struct ObjectiveCheckmark;

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Objective {
    pub id: usize,
    pub title: String,
    pub description: String,
    pub item_type: CollectibleType,
    pub required_count: u32,
    pub current_count: u32,
    pub completed: bool,
}

impl Objective {
    pub fn new(id: usize, title: String, description: String, item_type: CollectibleType, required_count: u32) -> Self {
        Self {
            id,
            title,
            description,
            item_type,
            required_count,
            current_count: 0,
            completed: false,
        }
    }

    // Removed unused is_completed and add_progress methods
}

#[derive(Resource, Default)]
pub struct ObjectiveManager {
    pub objectives: Vec<Objective>,
    pub next_id: usize,
}

impl ObjectiveManager {
    pub fn add_objective(&mut self, objective: Objective) {
        self.objectives.push(objective);
        self.next_id += 1;
    }

    // Removed unused update_progress, get_objective, and are_all_completed methods
}

// ===== PLUGIN =====

pub struct ObjectivesPlugin;

impl Plugin for ObjectivesPlugin {
    fn build(&self, app: &mut App) {
        app.init_resource::<ObjectiveManager>()
            .add_systems(OnEnter(Screen::GamePlay), setup_initial_objectives)
            .add_systems(
                Update,
                (update_objective_ui,).run_if(in_state(Screen::GamePlay)),
            );
    }
}

// ===== SYSTEMS =====

fn setup_initial_objectives(mut objective_manager: ResMut<ObjectiveManager>) {
    // Clear any existing objectives
    objective_manager.objectives.clear();
    objective_manager.next_id = 0;

    // Add some example objectives
    let health_id = objective_manager.next_id;
    objective_manager.add_objective(
        Objective::new(health_id, "Collect Health Potions".to_string(), "Collect 5 Health Potions".to_string(), CollectibleType::HealthPotion, 5),
    );
    let survival_id = objective_manager.next_id;
    objective_manager.add_objective(
        Objective::new(survival_id, "Find Survival Kits".to_string(), "Find 3 Survival Kits".to_string(), CollectibleType::SurvivalKit, 3),
    );
    let book_id = objective_manager.next_id;
    objective_manager.add_objective(
        Objective::new(book_id, "Gather Ancient Books".to_string(), "Gather 2 Ancient Books".to_string(), CollectibleType::Book, 2),
    );


}

fn update_objective_ui(
    mut commands: Commands,
    objective_manager: Res<ObjectiveManager>,
    font_assets: Option<Res<crate::assets::FontAssets>>,
    ui_assets: Option<Res<crate::assets::UiAssets>>,
    _objectives_ui_query: Query<Entity, With<ObjectiveUI>>,
    objectives_list_query: Query<Entity, (With<Node>, With<Name>)>,
    existing_slots: Query<Entity, With<ObjectiveSlot>>,
    _children: Query<&Children>,
    names: Query<&Name>,
) {
    if !objective_manager.is_changed() {
        return; // Only update when objectives change
    }

    let Some(font_assets) = font_assets else { return; };
    let Some(ui_assets) = ui_assets else { return; };

    // Find the objectives list container
    let mut objectives_list_entity = None;
    for entity in objectives_list_query.iter() {
        if let Ok(name) = names.get(entity) {
            if name.as_str() == "ObjectivesList" {
                objectives_list_entity = Some(entity);
                break;
            }
        }
    }

    let Some(list_entity) = objectives_list_entity else {
        warn!("Could not find ObjectivesList container");
        return;
    };

    // Clear existing objective slots
    for slot_entity in existing_slots.iter() {
        commands.entity(slot_entity).despawn();
    }

    // Spawn new objective slots for each objective
    let font = font_assets.rajdhani_bold.clone();
    let coin_image = ui_assets.coin.clone(); // Using coin as placeholder for all items

    for objective in &objective_manager.objectives {
        let slot_entity = commands.spawn(create_objective_slot(objective, font.clone(), coin_image.clone())).id();
        commands.entity(list_entity).add_child(slot_entity);
    }
}

fn create_objective_slot(
    objective: &Objective,
    font: Handle<Font>,
    item_image: Handle<Image>,
) -> impl Bundle {
    let progress_percent = if objective.required_count > 0 {
        objective.current_count as f32 / objective.required_count as f32
    } else {
        1.0
    };

    (
        Node {
            width: Val::Percent(100.0),
            height: Val::Px(80.0),
            flex_direction: FlexDirection::Row,
            align_items: AlignItems::Center,
            margin: UiRect::bottom(Val::Px(8.0)),
            padding: UiRect::all(Val::Px(8.0)),
            border: UiRect::all(Val::Px(2.0)),
            ..default()
        },
        BackgroundColor(Color::DARKER_GLASS),
        BorderColor(if objective.completed {
            Color::SUCCESS_GREEN.with_alpha(0.8)
        } else {
            Color::ELYSIUM_GOLD.with_alpha(0.4)
        }),
        BorderRadius::all(Val::Px(12.0)),
        ObjectiveSlot {
            // Removed unused objective_id field
        },
        children![
            // Item Icon Container
            (
                Node {
                    width: Val::Px(64.0),
                    height: Val::Px(64.0),
                    justify_content: JustifyContent::Center,
                    align_items: AlignItems::Center,
                    margin: UiRect::right(Val::Px(12.0)),
                    border: UiRect::all(Val::Px(2.0)),
                    ..default()
                },
                BackgroundColor(Color::LIGHT_GLASS),
                BorderColor(Color::ELYSIUM_GOLD.with_alpha(0.6)),
                BorderRadius::all(Val::Px(8.0)),
                                children![
                    // Checkmark for completed objectives
                    (
                        Node {
                            width: Val::Px(48.0),
                            height: Val::Px(48.0),
                            justify_content: JustifyContent::Center,
                            align_items: AlignItems::Center,
                            display: if objective.completed { Display::Flex } else { Display::None },
                            ..default()
                        },
                        BackgroundColor(Color::SUCCESS_GREEN),
                        BorderRadius::all(Val::Px(24.0)),
                        Name::new("Checkmark"),
                        children![(
                            Text::new("✓"),
                            TextFont {
                                font: font.clone(),
                                font_size: 32.0,
                                ..default()
                            },
                            TextColor::WHITE,
                        )]
                    ),
                    // Item icon for incomplete objectives
                    (
                        Node {
                            width: Val::Px(48.0),
                            height: Val::Px(48.0),
                            justify_content: JustifyContent::Center,
                            align_items: AlignItems::Center,
                            display: if objective.completed { Display::None } else { Display::Flex },
                            ..default()
                        },
                        BackgroundColor(Color::NONE),
                        BorderRadius::all(Val::Px(6.0)),
                        Name::new("ItemIcon"),
                        children![(
                            ImageNode {
                                image: item_image,
                                ..Default::default()
                            },
                            Node {
                                width: Val::Px(48.0),
                                height: Val::Px(48.0),
                                ..default()
                            },
                        )]
                    )
                ]
            ),
            // Objective Info Container
            (
                Node {
                    flex_direction: FlexDirection::Column,
                    justify_content: JustifyContent::SpaceBetween,
                    width: Val::Px(200.0),
                    height: Val::Px(64.0),
                    ..default()
                },
                children![
                    // Objective Title
                    (
                        Text::new(&objective.title),
                        TextFont {
                            font: font.clone(),
                            font_size: 14.0,
                            ..default()
                        },
                        TextColor(if objective.completed {
                            Color::SUCCESS_GREEN
                        } else {
                            Color::WHITE
                        }),
                        Node {
                            margin: UiRect::bottom(Val::Px(4.0)),
                            ..default()
                        },
                    ),
                    // Objective Description
                    (
                        Text::new(&objective.description),
                        TextFont {
                            font: font.clone(),
                            font_size: 12.0,
                            ..default()
                        },
                        TextColor(Color::WHITE),
                        Node {
                            margin: UiRect::bottom(Val::Px(4.0)),
                            ..default()
                        },
                    ),
                    // Progress Text
                    (
                        Text::new(format!("{}/{}", objective.current_count, objective.required_count)),
                        TextFont {
                            font: font.clone(),
                            font_size: 12.0,
                            ..default()
                        },
                        TextColor(if objective.completed {
                            Color::SUCCESS_GREEN
                        } else {
                            Color::ELYSIUM_GOLD
                        }),
                        Node {
                            margin: UiRect::bottom(Val::Px(4.0)),
                            ..default()
                        },
                    ),
                    // Progress Bar
                    (
                        Node {
                            width: Val::Px(180.0),
                            height: Val::Px(8.0),
                            border: UiRect::all(Val::Px(1.0)),
                            ..default()
                        },
                        BackgroundColor(Color::DARKER_GLASS),
                        BorderColor(Color::ELYSIUM_GOLD.with_alpha(0.4)),
                        BorderRadius::all(Val::Px(4.0)),
                        children![
                            (
                                Node {
                                    width: Val::Px(178.0 * progress_percent),
                                    height: Val::Px(6.0),
                                    margin: UiRect::all(Val::Px(1.0)),
                                    ..default()
                                },
                                BackgroundColor(if objective.completed {
                                    Color::SUCCESS_GREEN
                                } else {
                                    Color::ELYSIUM_GOLD
                                }),
                                BorderRadius::all(Val::Px(3.0)),
                            )
                        ]
                    )
                ]
            )
        ],
    )
} 