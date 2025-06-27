use bevy::prelude::*;
use super::{Screen, despawn_scene};

// ===== PLUGIN SETUP =====

pub(super) fn plugin(app: &mut App) {
    app.add_systems(OnEnter(Screen::FightScene), spawn_fight_scene)
        .add_systems(OnExit(Screen::FightScene), despawn_scene::<FightScene>)
        .add_systems(Update, handle_fight_input.run_if(in_state(Screen::FightScene)));
}

// ===== SYSTEMS =====

fn spawn_fight_scene(mut commands: Commands) {
    // Set up a simple background color for the fight scene
    commands.insert_resource(ClearColor(Color::srgb(0.1, 0.1, 0.1))); // Dark background
    
    // Add a simple camera
    commands.spawn((
        Name::new("Fight Camera"),
        Camera3d::default(),
        Camera {
            order: 1,
            ..default()
        },
        Transform::from_xyz(0.0, 5.0, 10.0).looking_at(Vec3::ZERO, Vec3::Y),
        FightScene,
    ));

    // Add some basic lighting
    commands.spawn((
        Name::new("Fight Scene Light"),
        DirectionalLight {
            illuminance: 50_000.0,
            shadows_enabled: true,
            ..default()
        },
        Transform::from_rotation(Quat::from_euler(
            bevy::math::EulerRot::XYZ,
            -std::f32::consts::FRAC_PI_4,
            std::f32::consts::FRAC_PI_4,
            0.0,
        )),
        FightScene,
    ));

    // Add a simple UI text to show we're in the fight scene
    commands.spawn((
        Node {
            width: Val::Percent(100.0),
            height: Val::Percent(100.0),
            justify_content: JustifyContent::Center,
            align_items: AlignItems::Center,
            ..default()
        },
        FightScene,
    )).with_children(|parent| {
        parent.spawn((
            Text::new("FIGHT SCENE\nPress ESC to return to gameplay"),
            TextFont {
                font_size: 40.0,
                ..default()
            },
            TextColor::WHITE,
            FightScene,
        ));
    });
}

fn handle_fight_input(
    keyboard_input: Res<ButtonInput<KeyCode>>,
    mut next_state: ResMut<NextState<Screen>>,
) {
    // Return to gameplay when ESC is pressed
    if keyboard_input.just_pressed(KeyCode::Escape) {
        next_state.set(Screen::GamePlay);
    }
}

// ===== SCENE MARKER =====

#[derive(Component, Default, Clone)]
struct FightScene; 