### **The Definitive, Multi-File Prompt**

Hello! You are an expert Bevy 0.16.0 and Rust developer with a talent for implementing features across a multi-file project structure.

My goal is to implement a complete, interactive dialogue system. This involves two major parts:
1.  **Triggering:** Starting a dialogue when the player collides with a book and presses 'E'.
2.  **Interacting:** Advancing through the dialogue lines and making choices using keyboard input.

This will require modifying **both** my `main.rs` file and my `systems/dialogue_view.rs` file.

#### **Current Project State & Full Context**

My application already has a core setup with Yarn Spinner and a custom dialogue view plugin. The dialogue view plugin is currently too simple—it just logs events and doesn't wait for user input. The trigger logic does not exist at all.

Here is the current state of the two files you need to modify.

**1. Current `main.rs` :**

**2. Current `systems/dialogue_view.rs` (Needs to be made interactive):**
```rust
use bevy::prelude::*;
use bevy_yarnspinner::prelude::*;
use bevy_yarnspinner::events::{PresentLineEvent, PresentOptionsEvent, DialogueCompleteEvent};
use bevy_yarnspinner::prelude::OptionId;

pub struct SimpleDialogueViewPlugin;

impl Plugin for SimpleDialogueViewPlugin {
    fn build(&self, app: &mut App) {
        // These systems are too simple and need to be improved.
        app.add_systems(Update, (
            handle_present_line_events,
            handle_present_options_events,
            handle_dialogue_complete_events,
        ));
    }
}

// FLAW: This system automatically continues the dialogue.
fn handle_present_line_events(
    mut line_events: EventReader<PresentLineEvent>,
    mut dialogue_runners: Query<&mut DialogueRunner>,
) {
    for event in line_events.read() {
        info!("💬 DIALOGUE: {}", event.line.text);
        if let Ok(mut dialogue_runner) = dialogue_runners.single_mut() {
            // PROBLEM: This shouldn't be here. We need to wait for player input.
            dialogue_runner.continue_in_next_update();
        }
    }
}

// FLAW: This system automatically selects the first option.
fn handle_present_options_events(
    mut option_events: EventReader<PresentOptionsEvent>,
    mut dialogue_runners: Query<&mut DialogueRunner>,
) {
    for event in option_events.read() {
        info!("🔸 DIALOGUE CHOICES:");
        for (index, option) in event.options.iter().enumerate() {
            info!("  [{}] {}", index + 1, option.line.text);
        }
        if !event.options.is_empty() {
            if let Ok(mut dialogue_runner) = dialogue_runners.single_mut() {
                // PROBLEM: This auto-selects. We need to wait for player input.
                dialogue_runner.select_option(OptionId(0)).unwrap();
            }
        }
    }
}

fn handle_dialogue_complete_events(
    mut complete_events: EventReader<DialogueCompleteEvent>,
) {
    for _event in complete_events.read() {
        info!("✅ DIALOGUE COMPLETE - Book interaction finished!");
    }
}
```

---

#### **Your Task: Implement the Complete Feature Across Both Files**

#### **Part 1: The Interaction Trigger (in `main.rs`)**

In `main.rs`, add the logic to spawn the necessary entities and trigger the dialogue.
4.  **Create State Management System:** Create a system `manage_active_interaction` that uses `CollisionEvents` to update the `ActiveInteraction` resource.
5.  **Create Trigger System:** Create a system `trigger_dialogue_on_input` that checks for the 'E' key press and starts the dialogue via the `DialogueRunner` if `ActiveInteraction` is Some.
6.  **Register:** Register the new resource and all new systems in the `App` builder in `main`.

#### **Part 2: The Interactive Dialogue UI (in `systems/dialogue_view.rs`)**

In `systems/dialogue_view.rs`, refactor the plugin to be controlled by player input.

1.  **Fix `handle_present_line_events`:** Remove the line `dialogue_runner.continue_in_next_update();`. This system should now *only* display the line and then wait.
2.  **Fix `handle_present_options_events`:** Remove the `dialogue_runner.select_option(...)` call. This system should *only* display the available options and then wait.
3.  **Create `handle_dialogue_input` System:** This is the new, core interactive system. It should:
    *   Query for the `DialogueRunner` and `Input<KeyCode>`.
    *   Only proceed if the `DialogueRunner` `is_running()`.
    *   **To advance lines:** If the 'E' key is `just_pressed` AND the dialogue runner is presenting a line (i.e., not waiting for an option selection), call `dialogue_runner.continue_in_next_update()`.
    *   **To select options:** If the number keys (1, 2, etc.) are `just_pressed` AND the dialogue runner is presenting options, call `dialogue_runner.select_option(OptionId(N-1))`.
4.  **Update Plugin:** Add your new `handle_dialogue_input` system to the `SimpleDialogueViewPlugin`.

#### **Final Deliverable**

Please provide the two complete, final, and corrected files.

1.  **The complete, modified `main.rs`**
2.  **The complete, modified `systems/dialogue_view.rs`**


Feel free to ULTRA THINK, use sub agents where it makes sense and don't feel stuck with my prompt yoy are an expert, just achieve the goal of a complete, interactive dialogue system
