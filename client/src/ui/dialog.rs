use crate::assets::FontAssets;
use crate::ui::widgets::label_widget;
use bevy::prelude::*;

// ===== DIALOG COMPONENTS =====

#[derive(Component)]
pub struct Dialog;

#[derive(Component)]
pub struct DialogProximity {
    pub target_position: Vec3,
    pub proximity_threshold: f32,
}

#[derive(Resource, Clone)]
pub struct DialogConfig {
    pub text: String,
    pub width: f32,  // Percentage of screen width
    pub height: f32, // Percentage of screen height
    pub position: DialogPosition,
    pub background_color: Color,
    pub border_color: Color,
    pub border_width: f32,
    pub font_size_multiplier: f32,
}

#[derive(Clone, Copy)]
pub enum DialogPosition {
    BottomCenter { bottom_margin: f32 },
}

impl Default for DialogConfig {
    fn default() -> Self {
        Self {
            text: "Press E to enter".to_string(),
            width: 40.0,
            height: 8.0,
            position: DialogPosition::BottomCenter { bottom_margin: 4.0 },
            background_color: Color::srgba(0.1, 0.1, 0.2, 0.6),
            border_color: Color::srgba(0.2, 0.2, 0.3, 0.8),
            border_width: 2.0,
            font_size_multiplier: 0.6,
        }
    }
}

// ===== DIALOG SYSTEMS =====

pub fn spawn_dialog(
    commands: &mut Commands,
    font_assets: &Res<FontAssets>,
    windows: Query<&Window>,
    config: DialogConfig,
    scene_marker: impl Component + Clone,
) {
    spawn_dialog_with_proximity(commands, font_assets, windows, config, scene_marker, None);
}

pub fn spawn_dialog_with_proximity(
    commands: &mut Commands,
    font_assets: &Res<FontAssets>,
    windows: Query<&Window>,
    config: DialogConfig,
    scene_marker: impl Component + Clone,
    proximity: Option<DialogProximity>,
) {
    let window = windows.single().expect("No primary window");
    let window_height = window.height();

    let (left, bottom) = match config.position {
        DialogPosition::BottomCenter { bottom_margin } => {
            (50.0 - config.width / 2.0, bottom_margin)
        }
    };

    let mut entity_commands = commands.spawn((
        Node {
            width: Val::Percent(config.width),
            height: Val::Percent(config.height),
            position_type: PositionType::Absolute,
            bottom: Val::Percent(bottom),
            left: Val::Percent(left),
            justify_content: JustifyContent::Center,
            align_items: AlignItems::Center,
            border: UiRect::all(Val::Px(config.border_width)),
            ..default()
        },
        BackgroundColor(config.background_color),
        BorderColor(config.border_color),
        Dialog,
        scene_marker.clone(),
        Name::new(format!("Dialog: {}", config.text)),
        Visibility::Hidden, // Start hidden
    ));

    // Add proximity component if provided
    if let Some(proximity) = proximity {
        entity_commands.insert(proximity);
    }

    entity_commands.with_children(|parent| {
        parent.spawn(label_widget(
            window_height * config.font_size_multiplier,
            font_assets.rajdhani_bold.clone(),
            config.text.clone(),
        ));
    });
}

pub fn animate_dialog(time: Res<Time>, mut query: Query<&mut BackgroundColor, With<Dialog>>) {
    let t = (time.elapsed_secs().sin() * 0.5 + 0.5) * 0.5 + 0.5;
    for mut bg in &mut query {
        let base_alpha = 0.4;
        let pulse_alpha = 0.3;
        let new_alpha = base_alpha + pulse_alpha * t;

        // Create a new color with the same RGB values but animated alpha
        let new_color = Color::srgba(0.1, 0.1, 0.2, new_alpha);
        *bg = BackgroundColor(new_color);
    }
}

pub fn check_dialog_proximity(
    player_query: Query<
        &Transform,
        With<crate::systems::character_controller::CharacterController>,
    >,
    mut dialog_query: Query<(&mut Visibility, Option<&DialogProximity>), With<Dialog>>,
) {
    let Ok(player_transform) = player_query.single() else {
        return;
    };

    for (mut visibility, proximity) in dialog_query.iter_mut() {
        if let Some(proximity) = proximity {
            // Check distance to target position
            let distance = player_transform.translation.distance(proximity.target_position);
            if distance <= proximity.proximity_threshold {
                *visibility = Visibility::Visible;
            } else {
                *visibility = Visibility::Hidden;
            }
        } else {
            // For dialogs without proximity, keep them hidden
            *visibility = Visibility::Hidden;
        }
    }
}

// ===== CONVENIENCE FUNCTIONS =====

// ===== DIALOG PLUGIN =====

pub struct DialogPlugin;

impl Plugin for DialogPlugin {
    fn build(&self, app: &mut App) {
        app.add_systems(Update, (animate_dialog, check_dialog_proximity));
    }
}
