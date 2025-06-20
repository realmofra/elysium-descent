use bevy::prelude::*;
use bevy_yarnspinner::prelude::*;
use bevy_yarnspinner::events::{PresentLineEvent, PresentOptionsEvent, DialogueCompleteEvent};
use bevy_yarnspinner::prelude::OptionId;

pub struct SimpleDialogueViewPlugin;

impl Plugin for SimpleDialogueViewPlugin {
    fn build(&self, app: &mut App) {
        app.add_systems(Update, (
            debug_all_dialogue_events,
            handle_present_line_events,
            handle_present_options_events,
            handle_dialogue_complete_events,
        ));
    }
}

/// System to debug all dialogue-related events and state
fn debug_all_dialogue_events(
    mut line_events: EventReader<PresentLineEvent>,
    mut option_events: EventReader<PresentOptionsEvent>,
    mut complete_events: EventReader<DialogueCompleteEvent>,
    dialogue_runners: Query<&DialogueRunner>,
) {
    let line_count = line_events.len();
    let option_count = option_events.len();
    let complete_count = complete_events.len();
    let runner_count = dialogue_runners.iter().count();
    
    // Log individual events for detailed debugging
    for event in line_events.read() {
        warn!("📝 LINE EVENT: '{}'", event.line.text);
    }
    
    for event in option_events.read() {
        warn!("🎯 OPTIONS EVENT: {} choices available", event.options.len());
        for (i, option) in event.options.iter().enumerate() {
            warn!("  Option {}: '{}'", i, option.line.text);
        }
    }
    
    for _event in complete_events.read() {
        warn!("✅ DIALOGUE COMPLETE EVENT");
    }
    
    if line_count > 0 || option_count > 0 || complete_count > 0 {
        warn!("🔍 DIALOGUE DEBUG SUMMARY: Lines: {}, Options: {}, Complete: {}, Runners: {}", 
              line_count, option_count, complete_count, runner_count);
    }
}

/// System to handle line presentation events
fn handle_present_line_events(
    mut line_events: EventReader<PresentLineEvent>,
    mut dialogue_runners: Query<&mut DialogueRunner>,
) {
    for event in line_events.read() {
        // Display the dialogue line to the user
        info!("💬 DIALOGUE: {}", event.line.text);
        
        // CRITICAL: Must call continue_in_next_update() to progress dialogue
        if let Ok(mut dialogue_runner) = dialogue_runners.single_mut() {
            dialogue_runner.continue_in_next_update();
            info!("✅ Called continue_in_next_update() - dialogue should progress");
        } else {
            warn!("❌ No DialogueRunner found when trying to continue dialogue");
        }
    }
}

/// System to handle choice presentation events
fn handle_present_options_events(
    mut option_events: EventReader<PresentOptionsEvent>,
    mut dialogue_runners: Query<&mut DialogueRunner>,
) {
    for event in option_events.read() {
        info!("🔸 DIALOGUE CHOICES:");
        for (index, option) in event.options.iter().enumerate() {
            info!("  [{}] {}", index + 1, option.line.text);
        }
        
        // For now, automatically choose the first option
        // In a real game, you'd wait for user input to select
        if !event.options.is_empty() {
            info!("🎯 Auto-selecting first choice...");
            if let Ok(mut dialogue_runner) = dialogue_runners.single_mut() {
                match dialogue_runner.select_option(OptionId(0)) {
                    Ok(_) => {
                        info!("✅ Successfully selected option 0");
                        // Continue dialogue after selection
                        dialogue_runner.continue_in_next_update();
                    }
                    Err(e) => {
                        warn!("❌ Failed to select option 0: {:?}", e);
                    }
                }
            } else {
                warn!("❌ No DialogueRunner found when trying to select option");
            }
        }
    }
}

/// System to handle dialogue completion
fn handle_dialogue_complete_events(
    mut complete_events: EventReader<DialogueCompleteEvent>,
) {
    for _event in complete_events.read() {
        info!("✅ DIALOGUE COMPLETE - Book interaction finished!");
    }
}