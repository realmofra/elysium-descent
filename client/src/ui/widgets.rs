use crate::ui::styles::ElysiumDescentColorPalette;
use bevy::ecs::relationship::{RelatedSpawnerCommands, Relationship};
use bevy::ecs::system::IntoObserverSystem;
use bevy::prelude::*;

pub fn label_widget(
    window_height: f32,
    font: Handle<Font>,
    text: impl Into<String> + Clone,
) -> impl Bundle {
    (
        Node {
            width: Val::Percent(100.0),
            height: Val::Percent(20.0),
            justify_content: JustifyContent::Center,
            align_items: AlignItems::Center,
            ..default()
        },
        Name::new(text.clone().into()),
        Pickable::IGNORE,
        children![(
            Text::new(text.into()),
            TextFont {
                font_size: window_height * 0.04,
                font,
                ..default()
            },
            TextColor::WHITE,
        )],
    )
}

fn volume_display_widget(
    window_height: f32,
    font: Handle<Font>,
    text: impl Into<String> + Clone,
) -> impl Bundle {
    (
        Node {
            width: Val::Percent(8.0),
            height: Val::Percent(20.0),
            justify_content: JustifyContent::Center,
            align_items: AlignItems::Center,
            border: UiRect::all(Val::Px(5.0)),
            ..default()
        },
        Name::new(text.clone().into()),
        BorderColor(Color::ELYSIUM_DESCENT_BLUE),
        Pickable::IGNORE,
        BorderRadius::MAX,
        children![(
            Text::new(text.into()),
            TextFont {
                font_size: window_height * 0.03,
                font,
                ..default()
            },
            TextColor::WHITE,
        )],
    )
}

fn button_widget(
    window_height: f32,
    font: Handle<Font>,
    text: impl Into<String> + Clone,
) -> impl Bundle {
    (
        Node {
            width: Val::Percent(6.0),
            height: Val::Percent(20.0),
            justify_content: JustifyContent::Center,
            align_items: AlignItems::Center,
            border: UiRect::all(Val::Px(3.0)),
            ..default()
        },
        Button,
        Name::new(text.clone().into()),
        BackgroundColor(Color::ELYSIUM_DESCENT_RED),
        BorderColor(Color::BLACK),
        BorderRadius::MAX,
        children![(
            Text::new(text.into()),
            TextFont {
                font_size: window_height * 0.05,
                font,
                ..default()
            },
            TextColor(Color::BLACK),
        )],
    )
}

pub(crate) fn volume_widget<R, E, B, M, IL, IR>(
    parent: &mut RelatedSpawnerCommands<'_, R>,
    window_height: f32,
    font: Handle<Font>,
    text: impl Into<String> + Clone,
    volume_value: impl Into<String> + Clone,
    top: f32,
    lower_volume_system: IL,
    raise_volume_system: IR,
) -> impl Bundle
where
    E: Event,
    B: Bundle,
    R: Relationship,
    IL: IntoObserverSystem<E, B, M>,
    IR: IntoObserverSystem<E, B, M>,
{
    parent
        .spawn((
            Node {
                position_type: PositionType::Absolute,
                width: Val::Percent(100.0),
                height: Val::Percent(40.0),
                top: Val::Percent(top),
                ..default()
            },
            Name::new("Sound settings row"),
            Pickable::IGNORE,
        ))
        .with_children(|content| {
            content.spawn(label_widget(window_height, font.clone(), text));

            content
                .spawn(button_widget(window_height, font.clone(), "-"))
                .observe(lower_volume_system);

            content.spawn((Node {
                margin: UiRect::all(Val::Percent(0.5)),
                ..default()
            },));

            content.spawn((volume_display_widget(
                window_height,
                font.clone(),
                volume_value,
            ),));

            content.spawn((Node {
                margin: UiRect::all(Val::Percent(0.5)),
                ..default()
            },));

            content
                .spawn(button_widget(window_height, font.clone(), "+"))
                .observe(raise_volume_system);
        });
}

pub enum HudPosition {
    Left,
    Right,
}

pub fn player_hud_widget(
    avatar: Handle<Image>,
    name: &str,
    level: u32,
    health: (u32, u32),
    xp: (u32, u32),
    font: Handle<Font>,
    position: HudPosition,
) -> impl Bundle {
    let health_percent = health.0 as f32 / health.1 as f32;
    let xp_percent = xp.0 as f32 / xp.1 as f32;
    let (left, right, flex_direction) = match position {
        HudPosition::Left => (Val::Px(32.0), Val::Auto, FlexDirection::Row),
        HudPosition::Right => (Val::Auto, Val::Px(32.0), FlexDirection::RowReverse),
    };
    
    (
        Node {
            position_type: PositionType::Absolute,
            left,
            right,
            top: Val::Px(32.0),
            width: Val::Px(420.0),
            height: Val::Px(120.0),
            flex_direction,
            justify_content: JustifyContent::FlexStart,
            align_items: AlignItems::Center,
            padding: UiRect::all(Val::Px(16.0)),
            border: UiRect::all(Val::Px(2.0)),
            ..default()
        },
        BackgroundColor(Color::DARK_GLASS),
        BorderColor(Color::ELYSIUM_GOLD.with_alpha(0.6)),
        BorderRadius::all(Val::Px(16.0)),
        Name::new("Modern Player HUD"),
        children![
            // Avatar Container with Glow Effect
            (
                Node {
                    width: Val::Px(80.0),
                    height: Val::Px(80.0),
                    margin: UiRect::all(Val::Px(8.0)),
                    justify_content: JustifyContent::Center,
                    align_items: AlignItems::Center,
                    border: UiRect::all(Val::Px(3.0)),
                    ..default()
                },
                BorderColor(Color::ELYSIUM_GOLD.with_alpha(0.8)),
                BorderRadius::all(Val::Px(42.0)),
                BackgroundColor(Color::DARKER_GLASS),
                children![
                    // Avatar Image
                    (
                        ImageNode {
                            image: avatar.clone(),
                            ..Default::default()
                        },
                        Node {
                            width: Val::Px(70.0),
                            height: Val::Px(70.0),
                            ..default()
                        },
                        BorderRadius::all(Val::Px(35.0)),
                    ),
                    // Level Badge
                    (
                        Node {
                            position_type: PositionType::Absolute,
                            right: Val::Px(-8.0),
                            bottom: Val::Px(-8.0),
                            width: Val::Px(36.0),
                            height: Val::Px(36.0),
                            justify_content: JustifyContent::Center,
                            align_items: AlignItems::Center,
                            border: UiRect::all(Val::Px(2.0)),
                            ..default()
                        },
                        BackgroundColor(Color::ELYSIUM_GOLD),
                        BorderColor(Color::ELYSIUM_GOLD_DIM),
                        BorderRadius::MAX,
                        children![(
                            Text::new(level.to_string()),
                            TextFont {
                                font: font.clone(),
                                font_size: 16.0,
                                ..default()
                            },
                            TextColor(Color::srgb(0.1, 0.1, 0.1)),
                        )]
                    )
                ]
            ),
            // Stats Container
            (
                Node {
                    width: Val::Px(300.0),
                    height: Val::Px(88.0),
                    flex_direction: FlexDirection::Column,
                    justify_content: JustifyContent::SpaceBetween,
                    margin: UiRect::horizontal(Val::Px(12.0)),
                    ..default()
                },
                children![
                    // Player Name
                    (
                        Text::new(name),
                        TextFont {
                            font: font.clone(),
                            font_size: 22.0,
                            ..default()
                        },
                        TextColor(Color::ELYSIUM_GOLD),
                        Node {
                            margin: UiRect::bottom(Val::Px(8.0)),
                            ..default()
                        },
                    ),
                    // Health Bar Container
                    (
                        Node {
                            width: Val::Px(280.0),
                            height: Val::Px(26.0),
                            flex_direction: FlexDirection::Column,
                            margin: UiRect::vertical(Val::Px(2.0)),
                            ..default()
                        },
                        children![
                            // Health Label Row
                            (
                                Node {
                                    width: Val::Percent(100.0),
                                    flex_direction: FlexDirection::Row,
                                    justify_content: JustifyContent::SpaceBetween,
                                    align_items: AlignItems::Center,
                                    margin: UiRect::bottom(Val::Px(2.0)),
                                    ..default()
                                },
                                children![
                                    (
                                        Text::new("HEALTH"),
                                        TextFont {
                                            font: font.clone(),
                                            font_size: 11.0,
                                            ..default()
                                        },
                                        TextColor(Color::HEALTH_GREEN),
                                    ),
                                    (
                                        Text::new(format!("{}/{}", health.0, health.1)),
                                        TextFont {
                                            font: font.clone(),
                                            font_size: 11.0,
                                            ..default()
                                        },
                                        TextColor::WHITE,
                                    )
                                ]
                            ),
                            // Health Bar
                            (
                                Node {
                                    width: Val::Px(280.0),
                                    height: Val::Px(18.0),
                                    border: UiRect::all(Val::Px(1.0)),
                                    ..default()
                                },
                                BackgroundColor(Color::DARKER_GLASS),
                                BorderColor(Color::HEALTH_GREEN_DARK.with_alpha(0.6)),
                                BorderRadius::all(Val::Px(9.0)),
                                children![
                                    (
                                        Node {
                                            width: Val::Px(278.0 * health_percent),
                                            height: Val::Px(16.0),
                                            margin: UiRect::all(Val::Px(1.0)),
                                            ..default()
                                        },
                                        BackgroundColor(Color::HEALTH_GREEN),
                                        BorderRadius::all(Val::Px(8.0)),
                                    )
                                ]
                            )
                        ]
                    ),
                    // XP Bar Container
                    (
                        Node {
                            width: Val::Px(280.0),
                            height: Val::Px(22.0),
                            flex_direction: FlexDirection::Column,
                            margin: UiRect::vertical(Val::Px(2.0)),
                            ..default()
                        },
                        children![
                            // XP Label Row
                            (
                                Node {
                                    width: Val::Percent(100.0),
                                    flex_direction: FlexDirection::Row,
                                    justify_content: JustifyContent::SpaceBetween,
                                    align_items: AlignItems::Center,
                                    margin: UiRect::bottom(Val::Px(2.0)),
                                    ..default()
                                },
                                children![
                                    (
                                        Text::new("EXPERIENCE"),
                                        TextFont {
                                            font: font.clone(),
                                            font_size: 9.0,
                                            ..default()
                                        },
                                        TextColor(Color::XP_PURPLE),
                                    ),
                                    (
                                        Text::new(format!("{}/{}", xp.0, xp.1)),
                                        TextFont {
                                            font: font.clone(),
                                            font_size: 9.0,
                                            ..default()
                                        },
                                        TextColor::WHITE,
                                    )
                                ]
                            ),
                            // XP Bar
                            (
                                Node {
                                    width: Val::Px(280.0),
                                    height: Val::Px(14.0),
                                    border: UiRect::all(Val::Px(1.0)),
                                    ..default()
                                },
                                BackgroundColor(Color::DARKER_GLASS),
                                BorderColor(Color::XP_PURPLE_DARK.with_alpha(0.6)),
                                BorderRadius::all(Val::Px(7.0)),
                                children![
                                    (
                                        Node {
                                            width: Val::Px(278.0 * xp_percent),
                                            height: Val::Px(12.0),
                                            margin: UiRect::all(Val::Px(1.0)),
                                            ..default()
                                        },
                                        BackgroundColor(Color::XP_PURPLE),
                                        BorderRadius::all(Val::Px(6.0)),
                                    )
                                ]
                            )
                        ]
                    )
                ]
            )
        ],
    )
}

pub fn objectives_ui_widget(
    objectives: &[crate::systems::objectives::Objective],
    font: Handle<Font>,
    _ui_assets: &crate::assets::UiAssets,
) -> impl Bundle {
    (
        Node {
            position_type: PositionType::Absolute,
            top: Val::Px(32.0),
            right: Val::Px(32.0),
            width: Val::Px(320.0),
            height: Val::Px(80.0 + (objectives.len() as f32 * 90.0)),
            flex_direction: FlexDirection::Column,
            padding: UiRect::all(Val::Px(16.0)),
            border: UiRect::all(Val::Px(2.0)),
            ..default()
        },
        BackgroundColor(Color::DARK_GLASS),
        BorderColor(Color::ELYSIUM_GOLD.with_alpha(0.6)),
        BorderRadius::all(Val::Px(16.0)),
        Name::new("Objectives UI"),
        crate::systems::objectives::ObjectiveUI,
        children![
            // Title
            (
                Node {
                    width: Val::Percent(100.0),
                    height: Val::Px(32.0),
                    justify_content: JustifyContent::Center,
                    align_items: AlignItems::Center,
                    margin: UiRect::bottom(Val::Px(12.0)),
                    ..default()
                },
                children![(
                    Text::new("OBJECTIVES"),
                    TextFont {
                        font: font.clone(),
                        font_size: 18.0,
                        ..default()
                    },
                    TextColor(Color::ELYSIUM_GOLD),
                )]
            ),
            // Objectives List
            (
                Node {
                    width: Val::Percent(100.0),
                    flex_direction: FlexDirection::Column,
                    ..default()
                },
                children![
                    // Individual objective slots will be spawned dynamically
                ]
            )
        ],
    )
}

pub fn objective_slot_widget(
    objective: &crate::systems::objectives::Objective,
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
        crate::systems::objectives::ObjectiveSlot {
            objective_id: objective.id,
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
