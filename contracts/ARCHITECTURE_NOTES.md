# Elysium Descent - Architecture & Design Notes

## Current Status: MVP - Working Dojo Inventory System

The contracts currently implement a basic but functional inventory management system with game creation, level progression, and item collection.

## Architecture Decisions & Open Questions

### 1. Pickup Validation Strategy

**Current State**: The `pickup_item()` function trusts the client completely - no position validation.

**Question**: Should we add proximity validation for item pickups?

**Options**:

#### Option A: Trust Client (Current Implementation)
```cairo
fn pickup_item(ref self: ContractState, game_id: u32, item_id: u32) -> bool
```
**Pros**: 
- Simple implementation
- Lower gas costs
- Faster development
- No need to sync player position

**Cons**:
- Vulnerable to cheating (players could collect items from anywhere)
- No enforcement of game physics/rules
- Could break game balance in multiplayer

#### Option B: Add Proximity Validation
```cairo
fn pickup_item(ref self: ContractState, game_id: u32, item_id: u32, player_x: u32, player_y: u32) -> bool {
    // Validate player is within pickup range
    let distance = calculate_distance(player_pos, item_pos);
    assert(distance <= PICKUP_RANGE, 'Too far from item');
}
```
**Pros**:
- Prevents basic cheating
- Enforces game rules on-chain
- Better for competitive/multiplayer gameplay
- More robust game integrity

**Cons**:
- Slightly more complex
- Higher gas costs
- Client must send position data
- Need to define pickup ranges

#### Option C: Hybrid - Optional Validation
- Add a game mode flag for "validation enabled"
- Trust mode for casual play
- Validation mode for competitive play

**Recommendation**: For MVP/development, current trust-based approach is fine. For production, especially with multiplayer or economic incentives, proximity validation would be better.

**Decision Needed**: Which approach aligns with your game's vision and security requirements?

### 2. Movement Architecture (RESOLVED ✅)

**Decision**: Movement is handled entirely client-side in Bevy 3D engine.
**Rationale**: 
- 3D exploration is inherently client-side
- No need for blockchain to track player movement
- Reduces gas costs and complexity
- Faster, smoother gameplay experience

**Implementation**: Only WorldItem positions are stored on-chain for rendering collectibles.

## Future Considerations

### Scalability
- Current simple models work for MVP
- May need to implement full Shinigami pattern for complex features
- Consider item batching for gas optimization

### Security
- Monitor for suspicious pickup patterns
- Consider implementing cooldowns or rate limiting
- Evaluate need for more sophisticated anti-cheat measures

### Integration Points
- Bevy client fetches WorldItem positions via Torii
- Real-time inventory updates through events
- Game state synchronization between client and blockchain

## Technical Debt & Improvements

1. **Pickup Validation** - Needs architectural decision (see above)
2. **Error Handling** - Could add more specific error types
3. **Gas Optimization** - Batch operations for multiple items
4. **Event Structure** - Consider more detailed event data for client
5. **Testing** - Need comprehensive test suite for game logic

## Notes for Development

- Keep models simple until feature requirements are clear
- Prioritize working functionality over perfect architecture
- Can refactor to full Shinigami pattern when needed
- Focus on client-blockchain integration points