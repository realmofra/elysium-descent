use bevy::prelude::*;
use crate::rendering::cameras::player_camera::FlyCam;

use super::Screen;

// ===== PLUGIN SETUP =====

pub(super) fn plugin(app: &mut App) {
    app.add_systems(OnEnter(Screen::GamePlay), spawn_environment)
        .add_systems(OnExit(Screen::GamePlay), despawn_scene::<EnvironmentMarker>)
        .insert_resource(ClearColor(Color::srgb(0.529, 0.808, 0.922))); // Sky blue color
}

// ===== SYSTEMS =====

fn despawn_scene<S: Component>(mut commands: Commands, query: Query<Entity, With<S>>) {
    for entity in &query {
        commands.entity(entity).despawn();
    }
}

// ===== COMPONENTS =====

#[derive(Component)]
struct EnvironmentMarker;

// ===== ENVIRONMENT SPAWNING =====

fn spawn_environment(
    mut commands: Commands,
    assets: Res<AssetServer>,
) {
    // Set up ambient light
    commands.insert_resource(AmbientLight {
        color: Color::srgb_u8(68, 71, 88),
        brightness: 120.0,
        ..default()
    });

    // Spawn environment
    let scene_handle = assets.load("models/environment.glb#Scene0");
    commands.spawn((
        Name::new("Environment"),
        EnvironmentMarker,
        SceneRoot(scene_handle),
        Transform {
            translation: Vec3::new(0.0, -1.5, 0.0),
            rotation: Quat::from_rotation_y(-core::f32::consts::PI * 0.5),
            scale: Vec3::splat(0.05), // Scale environment down
        },
    ));

    // Add directional light
    commands.spawn((
        Name::new("Directional Light"),
        DirectionalLight {
            illuminance: 80_000.0, // bright midday sun
            shadows_enabled: true,
            ..default()
        },
        Transform::from_rotation(Quat::from_euler(
            EulerRot::XYZ,
            -std::f32::consts::FRAC_PI_3,
            std::f32::consts::FRAC_PI_4,
            0.0,
        )),
    ));

    // Add camera
    commands.spawn((
        Name::new("Camera"),
        Camera3d::default(),
        Camera {
            order: 1,
            ..default()
        },
        Transform::from_xyz(0.0, 2.0, 6.0).looking_at(Vec3::new(0.0, 1.0, 0.0), Vec3::Y),
        FlyCam::default(),
    ));
}