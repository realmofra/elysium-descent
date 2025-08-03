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
    pub attack_cooldown: f32,
    pub last_attack_time: f32,
    pub is_attacking: bool,
    pub attack_duration: f32,
    pub current_attack_time: f32,
}

impl Default for EnemyAI {
    fn default() -> Self {
        Self {
            attack_range: 3.5,
            move_speed: 3.0,
            attack_cooldown: 2.0,
            last_attack_time: 0.0,
            is_attacking: false,
            attack_duration: 1.0, // Duration of attack animation
            current_attack_time: 0.0,
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
                current_animation: 3, // Start with idle animation
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
                enemy_ai_attack,
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

        // Update attack cooldown
        enemy_ai.last_attack_time += delta_time;

        // Update attack duration if attacking
        if enemy_ai.is_attacking {
            enemy_ai.current_attack_time += delta_time;
            if enemy_ai.current_attack_time >= enemy_ai.attack_duration {
                enemy_ai.is_attacking = false;
                enemy_ai.current_attack_time = 0.0;
            }
        }

        // Check if we should start attacking
        if distance_to_player <= enemy_ai.attack_range && 
           enemy_ai.last_attack_time >= enemy_ai.attack_cooldown && 
           !enemy_ai.is_attacking {
            enemy_ai.is_attacking = true;
            enemy_ai.last_attack_time = 0.0;
            enemy_ai.current_attack_time = 0.0;
        }

        if !enemy_ai.is_attacking {
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
        } else {
            // Stop moving when attacking
            enemy_velocity.x *= 0.8;
            enemy_velocity.z *= 0.8;
            enemy_velocity.y = 0.0;
            animation_state.forward_hold_time = 0.0;
        }
    }
}

/// System that handles enemy attack logic
fn enemy_ai_attack(
    mut enemy_query: Query<(&mut EnemyAI, &mut GltfAnimations), (With<Enemy>, Without<crate::systems::character_controller::CharacterController>)>,
    mut animation_players: Query<&mut AnimationPlayer>,
) {
    for (enemy_ai, mut animations) in &mut enemy_query {
        if enemy_ai.is_attacking && enemy_ai.current_attack_time < 0.1 {
            // Just started attacking, play attack animation
            if let Some(attack_animation) = animations.get_by_number(5) {
                if let Ok(mut player) = animation_players.get_mut(animations.animation_player) {
                    player.stop_all();
                    player.play(attack_animation);
                }
            }
        }
    }
}

/// System that handles enemy animations
fn enemy_ai_animations(
    mut enemy_query: Query<(&LinearVelocity, &mut GltfAnimations, &mut AnimationState, &EnemyAI), (With<Enemy>, Without<crate::systems::character_controller::CharacterController>)>,
    mut animation_players: Query<&mut AnimationPlayer>,
) {
    for (velocity, mut animations, mut animation_state, enemy_ai) in &mut enemy_query {
        let horizontal_velocity = Vec2::new(velocity.x, velocity.z);
        let is_moving = horizontal_velocity.length() > 0.1;

        // Determine target animation based on state
        // let target_animation = if enemy_ai.is_attacking {
        //     5 // Attack animation
        // } else if !is_moving {
        //     3 // Idle
        // } else {
        //     1 // Walking animation (index 1)
        // };

        let target_animation = 1;

        // Only change animation if we need to
        if target_animation != animation_state.current_animation {
            if let Some(animation) = animations.get_by_number(target_animation) {
                if let Ok(mut player) = animation_players.get_mut(animations.animation_player) {
                    player.stop_all();
                    if enemy_ai.is_attacking {
                        player.play(animation); // Don't repeat attack animation
                    } else {
                        player.play(animation).repeat(); // Repeat movement animations
                    }
                    animation_state.current_animation = target_animation;
                }
            }
        }
    }
} 