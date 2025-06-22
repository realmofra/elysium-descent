use crate::game::Player;
use bevy::prelude::*;

/// Enhanced camera system that follows the player with mouse controls
#[derive(Component)]
pub struct EnhancedFlyCam {
    pub distance: f32,
    pub height_offset: f32,
    pub smooth_speed: f32,
    /// Horizontal rotation angle around the player (yaw)
    pub yaw: f32,
    /// Vertical rotation angle (pitch)
    pub pitch: f32,
    /// Mouse sensitivity for camera rotation
    pub sensitivity: f32,
}

impl Default for EnhancedFlyCam {
    fn default() -> Self {
        Self {
            distance: 12.0,
            height_offset: 2.0,
            smooth_speed: 5.0,
            yaw: 0.0,
            pitch: -20.0_f32.to_radians(), // Start looking slightly down
            sensitivity: 0.003, // Mouse sensitivity
        }
    }
}

/// Event for camera rotation from input system
#[derive(Event, Debug)]
pub struct CameraRotationEvent {
    pub delta: Vec2,
}

/// Event for camera zoom from input system
#[derive(Event, Debug)]
pub struct CameraZoomEvent {
    pub delta: f32,
}

/// Update camera position based on player position and camera rotation
fn update_camera_position(
    time: Res<Time>,
    player_query: Query<&Transform, (With<Player>, Without<EnhancedFlyCam>)>,
    mut camera_query: Query<(&EnhancedFlyCam, &mut Transform), (Without<Player>, With<Camera3d>)>,
) {
    // Get player transform first
    let Ok(player_transform) = player_query.single() else {
        return;
    };

    // Then update camera positions
    for (camera, mut transform) in camera_query.iter_mut() {
        let player_pos = player_transform.translation;
        
        // Calculate camera position using spherical coordinates
        // Convert yaw/pitch to 3D position around the player
        let x = camera.distance * camera.yaw.cos() * camera.pitch.cos();
        let y = camera.distance * camera.pitch.sin();
        let z = camera.distance * camera.yaw.sin() * camera.pitch.cos();
        
        let target_pos = player_pos + Vec3::new(x, y + camera.height_offset, z);
        
        // Smoothly move camera to target position
        transform.translation = transform.translation.lerp(
            target_pos,
            (camera.smooth_speed * time.delta_secs()).min(1.0)
        );
        
        // Make camera look at player
        transform.look_at(player_pos + Vec3::new(0.0, camera.height_offset * 0.5, 0.0), Vec3::Y);
    }
}

/// Handle camera rotation events from the input system
fn handle_camera_rotation_events(
    mut rotation_events: EventReader<CameraRotationEvent>,
    mut camera_query: Query<&mut EnhancedFlyCam>,
) {
    for event in rotation_events.read() {
        for mut camera in camera_query.iter_mut() {
            // Apply mouse sensitivity
            let mouse_delta = event.delta * camera.sensitivity;
            
            // Update yaw (horizontal rotation)
            camera.yaw -= mouse_delta.x; // Negative for intuitive rotation
            
            // Update pitch (vertical rotation) with limits
            camera.pitch += mouse_delta.y; // Positive for intuitive rotation
            camera.pitch = camera.pitch.clamp(-1.5, 1.2); // Prevent over-rotation
            
            // Keep yaw in 0-2π range (optional, for cleaner values)
            camera.yaw = camera.yaw % (2.0 * std::f32::consts::PI);
        }
    }
}

/// Handle camera zoom events from the input system
fn handle_camera_zoom_events(
    mut zoom_events: EventReader<CameraZoomEvent>,
    mut camera_query: Query<&mut EnhancedFlyCam>,
) {
    for event in zoom_events.read() {
        for mut camera in camera_query.iter_mut() {
            // Adjust camera distance with zoom
            camera.distance -= event.delta * 0.5;
            camera.distance = camera.distance.clamp(2.0, 50.0); // Zoom range
        }
    }
}

/// Plugin for enhanced camera behavior with mouse controls
pub struct PlayerPlugin;
impl Plugin for PlayerPlugin {
    fn build(&self, app: &mut App) {
        app.add_event::<CameraRotationEvent>()
            .add_event::<CameraZoomEvent>()
            .add_systems(Update, (
                update_camera_position,
                handle_camera_rotation_events,
                handle_camera_zoom_events,
            ));
    }
}