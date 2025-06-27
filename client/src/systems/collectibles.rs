use crate::assets::ModelAssets;
use avian3d::prelude::*;
use bevy::prelude::*;
use std::sync::Arc;

use crate::systems::dojo::PickupItemEvent;
use crate::systems::character_controller::CharacterController;
use crate::systems::inventory::events::ItemCollectedEvent;
use crate::screens::Screen;

// ===== COMPONENTS & RESOURCES =====

#[derive(Resource)]
pub struct CollectibleCounter {
    pub collectibles_collected: u32,
}

#[derive(Component)]
pub struct Collectible {
    pub on_collect: Arc<dyn Fn(&mut Commands, Entity) + Send + Sync>,
}

#[derive(Component, Clone)]
pub struct CollectibleRotation {
    pub enabled: bool,
    pub clockwise: bool,
    pub speed: f32,
}

#[derive(Component)]
pub struct FloatingItem {
    pub base_height: f32,
    pub hover_amplitude: f32,
    pub hover_speed: f32,
}

#[derive(Component, Clone, Copy, Debug, PartialEq, Eq)]
pub enum CollectibleType {
    Book,
    FirstAidKit,
}

/// Component to track blockchain item ID for collectibles
#[derive(Component, Debug, Clone)]
pub struct BlockchainItemId {
    pub item_id: u32,
    pub game_id: u32,
}


// Removed NextItemToAdd resource - replaced with proper event system


#[derive(Component)]
pub struct Sensor;

/// Component to mark that an item has been collected (to prevent double collection)
#[derive(Component)]
pub struct Collected;

/// Component marking objects that can be interacted with
#[derive(Component)]
pub struct Interactable {
    pub interaction_radius: f32,
    pub prompt_text: String,
}

/// Event triggered when player presses interaction key
#[derive(Event, Debug)]
pub struct InteractionEvent;

/// Event triggered when player starts being near an interactable object
#[derive(Event, Debug)]
pub struct InteractionPromptEvent {
    pub show: bool,
    pub text: String,
}


/// Resource to track current interactable object
#[derive(Resource, Default)]
pub struct NearbyInteractable {
    pub entity: Option<Entity>,
    pub distance: f32,
}

// Configuration for spawning collectibles
#[derive(Clone)]
pub struct CollectibleConfig {
    pub position: Vec3,
    pub collectible_type: CollectibleType,
    pub scale: f32,
    pub rotation: Option<CollectibleRotation>,
    pub on_collect: Arc<dyn Fn(&mut Commands, Entity) + Send + Sync>,
    pub blockchain_item_id: Option<BlockchainItemId>,
}

// ===== PLUGIN =====

pub struct CollectiblesPlugin;

impl Plugin for CollectiblesPlugin {
    fn build(&self, app: &mut App) {
        app.insert_resource(CollectibleCounter {
            collectibles_collected: 0,
        })
        .add_event::<InteractionEvent>()
        .add_event::<InteractionPromptEvent>()
        .add_event::<ItemCollectedEvent>()
        .init_resource::<NearbyInteractable>()
        .add_systems(
            Update,
            (
                collect_items, 
                update_floating_items, 
                rotate_collectibles,
                detect_nearby_interactables,
                handle_interactions,
                update_interaction_prompts,
            )
                .run_if(in_state(Screen::GamePlay)),
        );
    }
}

// ===== SYSTEMS =====


pub fn spawn_collectible(
    commands: &mut Commands,
    assets: &Res<ModelAssets>,
    config: CollectibleConfig,
    scene_marker: impl Component + Clone,
) {
    let model_handle = match config.collectible_type {
        CollectibleType::Book => assets.book.clone(),
        CollectibleType::FirstAidKit => assets.first_aid_kit.clone(),
    };

    let mut entity = commands.spawn((
        Name::new(format!("{:?}", config.collectible_type)),
        SceneRoot(model_handle),
        Transform {
            translation: config.position,
            scale: Vec3::splat(config.scale),
            ..default()
        },
        Collider::sphere(0.5), // Simple sphere collider - won't interfere with character movement
        RigidBody::Kinematic,
        Visibility::Visible,
        InheritedVisibility::default(),
        ViewVisibility::default(),
        Collectible {
            on_collect: config.on_collect,
        },
        config.collectible_type,
        FloatingItem {
            base_height: config.position.y,
            hover_amplitude: 0.2,
            hover_speed: 2.0,
        },
        Sensor,
        scene_marker.clone(),
    ));

    if let Some(rotation) = config.rotation {
        entity.insert(rotation);
    }

    if let Some(blockchain_id) = config.blockchain_item_id {
        entity.insert(blockchain_id);
    }
}

fn collect_items(
    mut commands: Commands,
    mut collectible_counter: ResMut<CollectibleCounter>,
    player_query: Query<(Entity, &Transform), With<CharacterController>>,
    collectible_query: Query<(Entity, &Transform, &CollectibleType, &Collectible, Option<&BlockchainItemId>), (With<Sensor>, Without<Interactable>, Without<Collected>)>,
    mut pickup_events: EventWriter<PickupItemEvent>,
    mut item_collected_events: EventWriter<ItemCollectedEvent>,
) {
    // Proper Bevy 0.16 error handling with expect for single player
    let Ok((player_entity, player_transform)) = player_query.single() else {
        // No warning needed - it's normal to not have a player during startup
        return;
    };

    for (collectible_entity, collectible_transform, collectible_type, collectible, blockchain_item_id) in
        collectible_query.iter()
    {
        let distance = player_transform
            .translation
            .distance(collectible_transform.translation);
        if distance < 5.0 {
            // Collection radius - only for non-interactable items (like FirstAidKit)
            info!("Collected a {:?}!", collectible_type);
            
            // Mark as collected to prevent multiple collections
            commands.entity(collectible_entity).insert(Collected);
            
            // Send item collected event for inventory system
            warn!("🚀 COLLECTIBLES: Sending ItemCollectedEvent for {:?} (player: {:?}, item: {:?})", 
                  collectible_type, player_entity, collectible_entity);
            item_collected_events.write(ItemCollectedEvent::new(
                *collectible_type,
                player_entity,
                collectible_entity,
            ));

            match collectible_type {
                CollectibleType::FirstAidKit => {
                    // Trigger blockchain transaction for FirstAidKit
                    if let Some(blockchain_id) = blockchain_item_id {
                        info!("🏥 FirstAidKit collected - triggering blockchain transaction (item_id: {})", blockchain_id.item_id);
                        pickup_events.write(PickupItemEvent {
                            item_type: *collectible_type,
                            item_entity: collectible_entity,
                            item_id: blockchain_id.item_id,
                        });
                    } else {
                        warn!("🏥 FirstAidKit collected but no blockchain item_id found - skipping blockchain transaction");
                        // Fallback: collect locally without blockchain
                        (collectible.on_collect)(&mut commands, collectible_entity);
                    }
                    
                    // Note: The item will be removed from the world when the blockchain transaction is confirmed
                    // in the pickup_item system's handle_item_picked_up_events
                }
                _ => {
                    // For other items (not FirstAidKit), use the local collection method and despawn immediately
                    (collectible.on_collect)(&mut commands, collectible_entity);
                }
            }

            collectible_counter.collectibles_collected += 1;
            info!(
                "Total collectibles collected: {}",
                collectible_counter.collectibles_collected
            );
        }
    }
}


fn update_floating_items(time: Res<Time>, mut query: Query<(&FloatingItem, &mut Transform)>) {
    for (floating, mut transform) in query.iter_mut() {
        let time = time.elapsed_secs();
        let hover_offset = (time * floating.hover_speed).sin() * floating.hover_amplitude;
        transform.translation.y = floating.base_height + hover_offset;
    }
}

pub fn rotate_collectibles(
    mut collectible_query: Query<(&mut Transform, &CollectibleRotation)>,
    time: Res<Time>,
) {
    for (mut transform, rotation) in collectible_query.iter_mut() {
        if rotation.enabled {
            let rotation_amount = if rotation.clockwise {
                rotation.speed * time.delta_secs()
            } else {
                -rotation.speed * time.delta_secs()
            };
            transform.rotate_y(rotation_amount);
        }
    }
}

/// System to detect when player is near interactable objects
fn detect_nearby_interactables(
    player_query: Query<&Transform, With<CharacterController>>,
    interactable_query: Query<(Entity, &Transform, &Interactable)>,
    mut nearby_interactable: ResMut<NearbyInteractable>,
    mut prompt_events: EventWriter<InteractionPromptEvent>,
) {
    let Ok(player_transform) = player_query.single() else {
        return;
    };

    let mut closest_interactable: Option<(Entity, f32, &Interactable)> = None;

    // Find the closest interactable within range
    for (entity, transform, interactable) in interactable_query.iter() {
        let distance = player_transform.translation.distance(transform.translation);
        
        if distance <= interactable.interaction_radius {
            if let Some((_, closest_distance, _)) = closest_interactable {
                if distance < closest_distance {
                    closest_interactable = Some((entity, distance, interactable));
                }
            } else {
                closest_interactable = Some((entity, distance, interactable));
            }
        }
    }

    // Update nearby interactable state
    match closest_interactable {
        Some((entity, distance, interactable)) => {
            if nearby_interactable.entity != Some(entity) {
                // New interactable entered range
                // warn!("🔍 PROXIMITY: Player entered range of interactable entity {:?} - '{}'", entity, interactable.prompt_text);
                nearby_interactable.entity = Some(entity);
                nearby_interactable.distance = distance;
                prompt_events.write(InteractionPromptEvent {
                    show: true,
                    text: interactable.prompt_text.clone(),
                });
            } else {
                // Update distance for existing interactable
                nearby_interactable.distance = distance;
            }
        }
        None => {
            if nearby_interactable.entity.is_some() {
                // Left interaction range
                // warn!("🚶 PROXIMITY: Player left interaction range");
                nearby_interactable.entity = None;
                nearby_interactable.distance = 0.0;
                prompt_events.write(InteractionPromptEvent {
                    show: false,
                    text: String::new(),
                });
            }
        }
    }
}

/// System to handle interaction events
fn handle_interactions(
    mut commands: Commands,
    mut interaction_events: EventReader<InteractionEvent>,
    mut collectible_counter: ResMut<CollectibleCounter>,
    nearby_interactable: Res<NearbyInteractable>,
    interactable_query: Query<(&CollectibleType, &Collectible, Option<&BlockchainItemId>), With<Interactable>>,
    mut prompt_events: EventWriter<InteractionPromptEvent>,
    mut pickup_events: EventWriter<PickupItemEvent>,
) {
    for _event in interaction_events.read() {
        // warn!("🎯 INTERACTION EVENT RECEIVED! Checking for nearby interactable...");
        
        if let Some(entity) = nearby_interactable.entity {
            // warn!("✅ Found nearby interactable entity: {:?}", entity);
            
            if let Ok((collectible_type, _collectible, blockchain_item_id)) = interactable_query.get(entity) {
                // warn!("✅ Entity is valid with type: {:?}", collectible_type);
                
                // Handle different collectible types
                match collectible_type {
                    CollectibleType::Book => {
                        info!("📚 Book collected - You found an ancient tome!");
                        info!("The book's wisdom becomes part of your understanding.");
                        
                        // Collect the book directly
                        (_collectible.on_collect)(&mut commands, entity);
                        collectible_counter.collectibles_collected += 1;
                        info!(
                            "Total collectibles collected: {}",
                            collectible_counter.collectibles_collected
                        );
                    }
                    CollectibleType::FirstAidKit => {
                        // Trigger blockchain transaction for FirstAidKit
                        if let Some(blockchain_id) = blockchain_item_id {
                            info!("🏥 FirstAidKit interacted with - triggering blockchain transaction (item_id: {})", blockchain_id.item_id);
                            pickup_events.write(PickupItemEvent {
                                item_type: *collectible_type,
                                item_entity: entity,
                                item_id: blockchain_id.item_id,
                            });
                            collectible_counter.collectibles_collected += 1;
                            info!(
                                "Total collectibles collected: {}",
                                collectible_counter.collectibles_collected
                            );
                        } else {
                            warn!("🏥 FirstAidKit interacted with but no blockchain item_id found - skipping blockchain transaction");
                        }
                    }
                }

                // Hide the interaction prompt
                prompt_events.write(InteractionPromptEvent {
                    show: false,
                    text: String::new(),
                });
            } else {
                // warn!("❌ Nearby entity is not a valid interactable!");
            }
        } else {
            // warn!("❌ No nearby interactable entity when E was pressed!");
        }
    }
}

/// System to update interaction prompt UI (placeholder for now)
fn update_interaction_prompts(
    mut prompt_events: EventReader<InteractionPromptEvent>,
) {
    for event in prompt_events.read() {
        if event.show {
            info!("SHOW PROMPT: {}", event.text);
            // TODO: Show UI prompt with event.text
        } else {
            info!("HIDE PROMPT");
            // TODO: Hide UI prompt
        }
    }
}

/// Helper function to spawn an interactable book
pub fn spawn_interactable_book(
    commands: &mut Commands,
    assets: &Res<ModelAssets>,
    position: Vec3,
    scale: f32,
    on_collect: Arc<dyn Fn(&mut Commands, Entity) + Send + Sync>,
    scene_marker: impl Component + Clone,
) {
    let mut entity = commands.spawn((
        Name::new("Interactable Book"),
        SceneRoot(assets.book.clone()),
        Transform {
            translation: position,
            scale: Vec3::splat(scale),
            ..default()
        },
        scene_marker.clone(),
    ));

    // Add physics components - simple sphere collider to avoid character movement interference
    entity.insert((
        Collider::sphere(0.5),
        RigidBody::Kinematic,
    ));

    // Add visibility components
    entity.insert((
        Visibility::Visible,
        InheritedVisibility::default(),
        ViewVisibility::default(),
    ));

    // Add collectible components
    entity.insert((
        Collectible { on_collect },
        CollectibleType::Book,
        FloatingItem {
            base_height: position.y,
            hover_amplitude: 0.2,
            hover_speed: 2.0,
        },
        Sensor,
    ));

    // Add interaction components
    entity.insert((
        Interactable {
            interaction_radius: 3.0,
            prompt_text: "Press E to read".to_string(),
        },
        CollectibleRotation {
            enabled: true,
            clockwise: true,
            speed: 1.0,
        },
    ));
}
