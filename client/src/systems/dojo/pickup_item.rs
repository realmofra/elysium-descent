use crate::constants::dojo::PICKUP_ITEM_SELECTOR;
use crate::screens::Screen;
use crate::systems::collectibles::CollectibleType;
use bevy::prelude::*;
use dojo_bevy_plugin::{DojoEntityUpdated, DojoResource};
use starknet::core::types::Call;
use bevy::tasks::{AsyncComputeTaskPool, Task};
use futures_lite::future;
use starknet::accounts::Account;

/// Event to trigger item pickup on the blockchain
#[derive(Event, Debug)]
pub struct PickupItemEvent {
    pub item_type: CollectibleType,
    pub item_entity: Entity,
}

/// Event emitted when an item pickup is successfully processed on blockchain
#[derive(Event, Debug)]
pub struct ItemPickedUpEvent {
    pub item_type: CollectibleType,
    pub item_entity: Entity,
    pub transaction_hash: String,
}

/// Event emitted when item pickup fails
#[derive(Event, Debug)]
pub struct ItemPickupFailedEvent {
    pub item_type: CollectibleType,
    pub error: String,
}

/// Resource to track pending pickup transactions
#[derive(Resource, Debug, Default)]
pub struct PickupTransactionState {
    pub pending_pickups: Vec<(Entity, CollectibleType)>,
}

#[derive(Resource, Default)]
pub struct PendingPickupTasks(pub Vec<Task<Result<(Entity, CollectibleType, String), (Entity, CollectibleType, String)>>>);

pub(super) fn plugin(app: &mut App) {
    app.add_event::<PickupItemEvent>()
        .add_event::<ItemPickedUpEvent>()
        .add_event::<ItemPickupFailedEvent>()
        .init_resource::<PickupTransactionState>()
        .init_resource::<PendingPickupTasks>()
        .add_systems(
            Update,
            (
                handle_pickup_item_events,
                poll_pickup_tasks,
                handle_item_picked_up_events,
                handle_item_pickup_failed_events,
                handle_pickup_entity_updates,
            )
                .run_if(in_state(Screen::GamePlay)),
        );
}

/// System to handle PickupItemEvent and call the blockchain
fn handle_pickup_item_events(
    mut events: EventReader<PickupItemEvent>,
    dojo: Res<DojoResource>,
    dojo_config: Res<super::DojoSystemState>,
    mut pending_tasks: ResMut<PendingPickupTasks>,
) {
    let thread_pool = AsyncComputeTaskPool::get();
    let account = dojo.sn.account.clone();
    for event in events.read() {
        let call = Call {
            to: dojo_config.config.action_address,
            selector: PICKUP_ITEM_SELECTOR,
            calldata: vec![],
        };
        let entity = event.item_entity;
        let item_type = event.item_type;
        let account = account.clone();
        let task = thread_pool.spawn(async move {
            if let Some(account) = account {
                let tx = account.execute_v3(vec![call]);
                match tx.send().await {
                    Ok(result) => Ok((entity, item_type, format!("{:#x}", result.transaction_hash))),
                    Err(e) => Err((entity, item_type, format!("{:?}", e))),
                }
            } else {
                Err((entity, item_type, "No account available".to_string()))
            }
        });
        pending_tasks.0.push(task);
    }
}

/// System to handle successful item pickup
fn handle_item_picked_up_events(
    mut events: EventReader<ItemPickedUpEvent>,
    mut commands: Commands,
    world: &World,
) {
    for event in events.read() {
        info!(
            "Item pickup confirmed on blockchain! {:?} (TX: {})",
            event.item_type, event.transaction_hash
        );

        // Check if the entity still exists before trying to despawn it
        if world.get_entity(event.item_entity).is_ok() {
            commands.entity(event.item_entity).despawn();
            info!(
                "Item {:?} successfully removed from game world",
                event.item_type
            );
        } else {
            info!(
                "Item {:?} entity no longer exists (ID: {:?}) - likely already removed",
                event.item_type, event.item_entity
            );
        }
    }
}

/// System to handle failed item pickup
fn handle_item_pickup_failed_events(mut events: EventReader<ItemPickupFailedEvent>) {
    for event in events.read() {
        error!(
            "Item pickup failed for {:?}: {}",
            event.item_type, event.error
        );

        // TODO: Show error message to user
        // TODO: Optionally retry the pickup
        warn!(
            "Item {:?} remains in game world due to pickup failure",
            event.item_type
        );
    }
}

/// System to handle entity updates from Dojo/Torii related to pickups
fn handle_pickup_entity_updates(
    mut dojo_events: EventReader<DojoEntityUpdated>,
    mut item_picked_up_events: EventWriter<ItemPickedUpEvent>,
    _item_pickup_failed_events: EventWriter<ItemPickupFailedEvent>,
    mut pickup_state: ResMut<PickupTransactionState>,
) {
    for event in dojo_events.read() {
        // Process each model in the entity update
        for model in &event.models {
            match model.name.as_str() {
                "PlayerInventory" => {
                    info!("PlayerInventory updated - item pickup may have succeeded");

                    // For now, assume any inventory update means pickup succeeded
                    // In a full implementation, you'd parse the model data to confirm
                    if let Some((entity, item_type)) = pickup_state.pending_pickups.pop() {
                        item_picked_up_events.write(ItemPickedUpEvent {
                            item_type,
                            item_entity: entity,
                            transaction_hash: "0x123".to_string(), // TODO: Extract real TX hash
                        });
                    }
                }
                "PlayerStats" => {
                    info!("PlayerStats updated - may be related to item pickup");
                    // TODO: Handle stat changes from item pickup
                }
                _ => {
                    // Other model updates not related to pickup
                }
            }
        }
    }
}

// Poll background tasks and emit events when done
fn poll_pickup_tasks(
    mut pending_tasks: ResMut<PendingPickupTasks>,
    mut item_picked_up_events: EventWriter<ItemPickedUpEvent>,
    mut item_pickup_failed_events: EventWriter<ItemPickupFailedEvent>,
) {
    pending_tasks.0.retain_mut(|task| {
        if let Some(result) = future::block_on(future::poll_once(task)) {
            match result {
                Ok((entity, item_type, tx_hash)) => {
                    item_picked_up_events.write(ItemPickedUpEvent {
                        item_type,
                        item_entity: entity,
                        transaction_hash: tx_hash,
                    });
                }
                Err((entity, item_type, err)) => {
                    item_pickup_failed_events.write(ItemPickupFailedEvent {
                        item_type,
                        error: err,
                    });
                }
            }
            false // Remove finished task
        } else {
            true // Keep unfinished task
        }
    });
}
