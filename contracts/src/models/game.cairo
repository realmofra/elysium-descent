use starknet::{get_caller_address};
use death_mountain::models::adventurer::adventurer::{ImplAdventurer, Adventurer};
use death_mountain::constants::adventurer::{
    MAX_ADVENTURER_HEALTH, MAX_ADVENTURER_XP, MAX_PACKABLE_BEAST_HEALTH,
    MAX_STAT_UPGRADES_AVAILABLE,
};
use death_mountain::models::adventurer::equipment::{IEquipment, ImplEquipment};
use death_mountain::models::adventurer::item::{ImplItem};
use death_mountain::models::adventurer::stats::{IStat, ImplStats};
pub use elysium_descent::models::index::Game;

const TWO_POW_10: u256 = 0x400;
const TWO_POW_25: u256 = 0x2000000;
const TWO_POW_34: u256 = 0x400000000;
const TWO_POW_44: u256 = 0x100000000000;
const TWO_POW_48: u256 = 0x1000000000000;
const TWO_POW_78: u256 = 0x40000000000000000000;
const TWO_POW_206: u256 = 0x4000000000000000000000000000000000000000000000000000;
const TWO_POW_222: u256 = 0x40000000000000000000000000000000000000000000000000000000;

#[generate_trait]
pub impl ImplGame of GameTrait {
    #[inline]
    fn new(game_id: u128, starting_item: u8) -> Game {
        let mut adventurer: Adventurer = ImplAdventurer::new(starting_item);
        let packed_adventurer = ImplAdventurer::pack(adventurer);
        Game {
            game_id: game_id, player: get_caller_address(), packed_adventurer: packed_adventurer,
        }
    }

    #[inline]
    fn increase_gold(ref self: Game) {
        let mut adventurer: Adventurer = ImplAdventurer::unpack(self.packed_adventurer);
        adventurer.gold += 1;
        self.packed_adventurer = self.pack(adventurer);
    }

    #[inline]
    fn dynamic_gold_increase(ref self: Game, amount: u16) {
        let mut adventurer: Adventurer = ImplAdventurer::unpack(self.packed_adventurer);
        adventurer.gold += amount;
        self.packed_adventurer = self.pack(adventurer);
    }

    #[inline]
    fn pack(self: Game, adventurer: Adventurer) -> felt252 {
        assert(adventurer.health <= MAX_ADVENTURER_HEALTH, 'health overflow');
        assert(adventurer.xp <= MAX_ADVENTURER_XP, 'xp overflow');
        assert(adventurer.beast_health <= MAX_PACKABLE_BEAST_HEALTH, 'beast health overflow');
        assert(
            adventurer.stat_upgrades_available <= MAX_STAT_UPGRADES_AVAILABLE,
            'stat upgrades avail overflow',
        );

        (adventurer.health.into()
            + adventurer.xp.into() * TWO_POW_10
            + adventurer.gold.into() * TWO_POW_25
            + adventurer.beast_health.into() * TWO_POW_34
            + adventurer.stat_upgrades_available.into() * TWO_POW_44
            + adventurer.stats.pack().into() * TWO_POW_48
            + adventurer.equipment.pack().into() * TWO_POW_78
            + adventurer.item_specials_seed.into() * TWO_POW_206
            + adventurer.action_count.into() * TWO_POW_222)
            .try_into()
            .unwrap()
    }
}
