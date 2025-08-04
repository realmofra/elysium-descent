use bevy::prelude::*;
use bevy_gltf_animation::prelude::*;
use avian3d::{math::*, prelude::*};
use crate::systems::character_controller::AnimationState;

/// Marker component for enemy entities
#[derive(Component)]
pub struct Enemy;

/// Component to track enemy AI state
#[derive(Component)]
pub struct EnemyAI {
    pub attack_range: f32,
    pub move_speed: f32,
    pub last_position: Option<Vec3>,
    pub is_moving: bool,
    pub animation_switch_timer: f32,
}

impl Default for EnemyAI {
    fn default() -> Self {
        Self {
            attack_range: 3.5,
            move_speed: 3.0,
            last_position: None,
            is_moving: false,
            animation_switch_timer: 0.0,
        }
    }
}

/// Bundle for enemy entities
#[derive(Bundle)]
pub struct EnemyBundle {
    pub enemy: Enemy,
    pub ai: EnemyAI,
    pub animation_state: AnimationState,
    pub body: RigidBody,
    pub collider: Collider,
    pub locked_axes: LockedAxes,
    pub ground_caster: ShapeCaster,
}

impl Default for EnemyBundle {
    fn default() -> Self {
        Self {
            enemy: Enemy,
            ai: EnemyAI::default(),
            animation_state: AnimationState {
                forward_hold_time: 0.0,
                current_animation: 1, // Start with walking animation
                fight_move_1: false,
                fight_move_2: false,
            },
            body: RigidBody::Kinematic, // Use kinematic instead of dynamic
            collider: Collider::capsule(0.5, 1.5),
            locked_axes: LockedAxes::ROTATION_LOCKED,
            ground_caster: ShapeCaster::new(
                Collider::sphere(0.2),
                Vector::ZERO,
                Quaternion::default(),
                Dir3::NEG_Y,
            )
            .with_max_distance(2.0), // Ground detection
        }
    }
}

/// Plugin for enemy AI systems
pub struct EnemyAIPlugin;

impl Plugin for EnemyAIPlugin {
    fn build(&self, app: &mut App) {
        app.add_systems(
            Update,
            (
                enemy_ai_movement,
                enemy_ai_animations,
            ).chain(),
        );
    }
}

/// System that handles enemy movement towards the player
fn enemy_ai_movement(
    time: Res<Time>,
    mut enemy_query: Query<(&mut Transform, &mut LinearVelocity, &mut EnemyAI, &mut AnimationState), (With<Enemy>, Without<crate::systems::character_controller::CharacterController>)>,
    player_query: Query<&Transform, (With<crate::systems::character_controller::CharacterController>, Without<Enemy>)>,
) {
    let delta_time = time.delta_secs();
    
    // Find the player
    let Ok(player_transform) = player_query.single() else {
        return;
    };

    for (mut enemy_transform, mut enemy_velocity, mut enemy_ai, mut animation_state) in &mut enemy_query {
        let player_pos = player_transform.translation;
        let enemy_pos = enemy_transform.translation;
        let distance_to_player = enemy_pos.distance(player_pos);

        // Track actual movement by comparing positions
        let moved = if let Some(last_pos) = enemy_ai.last_position {
            enemy_pos.distance(last_pos) > 0.1 // Increased threshold to reduce twitching
        } else {
            // On first frame, assume moving if not in attack range
            distance_to_player > enemy_ai.attack_range
        };
        
        // Only update is_moving if we're not in attack range to prevent twitching
        if distance_to_player > enemy_ai.attack_range {
            enemy_ai.is_moving = moved;
        } else {
            // Force idle when in attack range
            enemy_ai.is_moving = false;
        }
        enemy_ai.last_position = Some(enemy_pos);


        


        // Check if we're close enough to the player
        if distance_to_player <= enemy_ai.attack_range {
            // Stop moving when close to player
            enemy_velocity.x *= 0.8;
            enemy_velocity.z *= 0.8;
            enemy_velocity.y = 0.0;
            animation_state.forward_hold_time = 0.0;
        } else {
            // Move towards player
            let direction_to_player = (player_pos - enemy_pos).normalize();
            let target_velocity = direction_to_player * enemy_ai.move_speed;
            
            // Keep Y velocity at 0 for kinematic movement
            enemy_velocity.x = enemy_velocity.x.lerp(target_velocity.x, 5.0 * delta_time);
            enemy_velocity.z = enemy_velocity.z.lerp(target_velocity.z, 5.0 * delta_time);
            enemy_velocity.y = 0.0; // Keep enemy on ground
            
            // Rotate enemy to face the player (only Y rotation)
            let direction_2d = Vec2::new(direction_to_player.x, direction_to_player.z).normalize();
            let target_rotation = Quat::from_rotation_arc(Vec3::Z, Vec3::new(direction_2d.x, 0.0, direction_2d.y));
            enemy_transform.rotation = enemy_transform.rotation.slerp(target_rotation, 3.0 * delta_time);
            
            // Keep enemy on ground level
            enemy_transform.translation.y = -1.65; // Match the original enemy Y position
            
            // Update animation state for walking
            let horizontal_speed = Vec2::new(enemy_velocity.x, enemy_velocity.z).length();
            if horizontal_speed > 0.1 {
                animation_state.forward_hold_time += delta_time;
            } else {
                animation_state.forward_hold_time = 0.0;
            }
        }
    }
}



/// System that handles enemy animations
fn enemy_ai_animations(
    time: Res<Time>,
    mut enemy_query: Query<(&mut GltfAnimations, &mut AnimationState, &mut EnemyAI), (With<Enemy>, Without<crate::systems::character_controller::CharacterController>)>,
    mut animation_players: Query<&mut AnimationPlayer>,
) {
    let delta_time = time.delta_secs();
    
    for (mut animations, mut animation_state, mut enemy_ai) in &mut enemy_query {
        // Update animation switch timer
        enemy_ai.animation_switch_timer += delta_time;
        
        // Determine target animation based on state
        let target_animation = if !enemy_ai.is_moving {
            3 // Idle animation when not moving
        } else {
            1 // Walking animation when moving
        };

        // Only change animation if we need to and enough time has passed
        if target_animation != animation_state.current_animation && 
           enemy_ai.animation_switch_timer > 0.2 {
            if let Some(animation) = animations.get_by_number(target_animation) {
                if let Ok(mut player) = animation_players.get_mut(animations.animation_player) {
                    player.stop_all();
                    player.play(animation).repeat(); // Repeat movement animations
                    animation_state.current_animation = target_animation;
                    enemy_ai.animation_switch_timer = 0.0; // Reset timer
                }
            }
        }
    }
} 