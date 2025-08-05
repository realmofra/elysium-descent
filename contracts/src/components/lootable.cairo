//fn try_spawn_loot_box(
//    game_id: u128,
//    level: u32,
//    current_time: u64,
//) -> Option<LootBox> {
//    // Get level configuration
//    let level_config = get_level_config(level);

//    // Check if we can spawn based on interval
//    let last_spawn_time = get_last_spawn_time(level);
//    if current_time < last_spawn_time + level_config.spawn_interval {
//        return None; // Too soon to spawn
//    }

//    // Count current active boxes
//    let active_boxes = count_active_loot_boxes(level);
//    if active_boxes >= level_config.max_loot_boxes {
//        return None; // At max capacity
//    }

//    // Get available loot types from LootTable for this level
//    let loot_tables = get_loot_tables(level);

//    // Select a random loot type based on probabilities
//    let selected_loot = select_random_loot(loot_tables);

//    // Calculate amount based on min/max and potentially gold multiplier
//    let mut amount = random_range(
//        selected_loot.min_amount,
//        selected_loot.max_amount
//    );

//    // Apply gold multiplier if this is a gold loot type
//    if selected_loot.loot_type == GOLD_LOOT_TYPE {
//        amount *= level_config.gold_multiplier;
//    }

//    // Create new LootBox
//    Some(LootBox {
//        game_id,
//        level,
//        box_id: generate_box_id(),
//        loot_type: selected_loot.loot_type,
//        amount,
//        is_collected: false,
//        spawn_time: current_time,
//        expires_at: current_time + level_config.box_lifetime
//    })
//}
