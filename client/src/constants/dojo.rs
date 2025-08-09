#[cfg(not(target_arch = "wasm32"))]
use starknet::core::types::Felt;
#[cfg(not(target_arch = "wasm32"))]
use starknet::macros::selector;
use std::env;

/// Configuration for Dojo blockchain integration
#[derive(Debug, Clone)]
pub struct DojoConfig {
    #[allow(dead_code)]
    pub torii_url: String,
    #[allow(dead_code)]
    pub katana_url: String,
    #[allow(dead_code)]
    #[cfg(not(target_arch = "wasm32"))]
    pub world_address: Felt,
    #[allow(dead_code)]
    #[cfg(not(target_arch = "wasm32"))]
    pub action_address: Felt,
    #[allow(dead_code)]
    pub use_dev_account: bool,
    #[allow(dead_code)]
    pub dev_account_index: u32,
}

impl Default for DojoConfig {
    fn default() -> Self {
        Self {
            torii_url: env::var("TORII_URL").unwrap_or_else(|_| {
                "https://api.cartridge.gg/x/elysium-descent001/torii".to_string()
            }),
            katana_url: env::var("KATANA_URL").unwrap_or_else(|_| {
                "https://api.cartridge.gg/x/elysium-descent001/katana".to_string()
            }),
            #[cfg(not(target_arch = "wasm32"))]
            world_address: env::var("WORLD_ADDRESS")
                .ok()
                .and_then(|addr| Felt::from_hex(&addr).ok())
                .unwrap_or_else(|| {
                    // Real deployed world address from manifest_dev.json
                    Felt::from_hex_unchecked(
                        "0x002f3fd3e14a14bb1c98095c6f9c305b5660e41f6bbbf8f8dc8a52c6104fe5fa",
                    )
                }),
            #[cfg(not(target_arch = "wasm32"))]
            action_address: env::var("ACTION_ADDRESS")
                .ok()
                .and_then(|addr| Felt::from_hex(&addr).ok())
                .unwrap_or_else(|| {
                    // Real deployed action address from manifest_dev.json
                    Felt::from_hex_unchecked(
                        "0x0714c627d3dd04f47d301b29f2db8e3dd0587055e32b366ce13182f7c7e031a7",
                    )
                }),
            use_dev_account: env::var("USE_DEV_ACCOUNT").unwrap_or_else(|_| "true".to_string())
                == "true",
            dev_account_index: env::var("DEV_ACCOUNT_INDEX")
                .unwrap_or_else(|_| "0".to_string())
                .parse()
                .unwrap_or(0),
        }
    }
}

// Updated selectors for Elysium Descent contract functions
#[allow(dead_code)]
#[cfg(not(target_arch = "wasm32"))]
pub const CREATE_GAME_SELECTOR: Felt = selector!("create_game");
#[allow(dead_code)]
#[cfg(not(target_arch = "wasm32"))]
pub const PICKUP_ITEM_SELECTOR: Felt = selector!("pickup_item");
