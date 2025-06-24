# Advanced Cairo Programming Patterns

This document outlines advanced Cairo programming language patterns, architectural principles, and best practices for writing efficient, maintainable Cairo code on Starknet. These patterns are framework-agnostic and focus on Cairo language features.

## 1. Cairo Documentation and Code Quality Patterns

### Advanced Documentation Patterns

Cairo enforces strict commenting syntax that directly affects compilation. Proper documentation is not just a best practice—it's a requirement for maintainable Cairo code.

#### Production-Quality Documentation Templates

```cairo
/// Core data structure with comprehensive field documentation
/// 
/// This struct demonstrates proper Cairo documentation patterns
/// including field descriptions and usage constraints.
/// 
/// # Memory Layout
/// Uses efficient field ordering for optimal memory usage
/// with commonly accessed fields first.
#[derive(Copy, Drop, Serde)]
pub struct GameEntity {
    pub id: u32,
    pub position_x: u32,
    pub position_y: u32,
    pub health: u32,
    pub max_health: u32,
    pub active: bool,
}

/// Advanced trait with comprehensive documentation
/// 
/// Demonstrates proper trait documentation including generic constraints,
/// implementation requirements, and usage examples.
/// 
/// # Type Parameters
/// * `T` - Must implement `Copy + Drop + Serde` for compatibility
/// 
/// # Examples
/// ```cairo
/// struct Counter {
///     value: u32,
/// }
/// 
/// impl Counter of IncrementTrait<Counter> {
///     fn increment(ref self: Counter, amount: u32) -> bool {
///         self.value += amount;
///         true
///     }
/// }
/// ```
#[generate_trait]
pub trait IncrementTrait<T> {
    /// Increments the value by the specified amount
    /// 
    /// # Arguments
    /// * `amount` - Amount to increment (must be > 0)
    /// 
    /// # Returns
    /// `true` if increment succeeded, `false` otherwise
    /// 
    /// # Panics
    /// Panics if `amount` is 0 or would cause overflow
    fn increment(ref self: T, amount: u32) -> bool;
    
    /// Gets the current value
    /// 
    /// # Returns
    /// Current value of the counter
    fn get_value(self: @T) -> u32;
}
```

#### Documentation Anti-Patterns to Avoid

```cairo
// ❌ NEVER - Inline comments on enum variants (compilation error)
#[derive(Serde, Copy, Drop, PartialEq)]
pub enum DataType {
    Integer, // This will break compilation
    Text,    // Cairo parser doesn't handle this
    Boolean  // Causes syntax errors
}

// ❌ WRONG - Vague, debugging-style comments
fn process_data() {
    // Do stuff
    let data = get_data(); // Get it
    // Check something
    if data.is_valid() {
        // Process it somehow
        process(data);
    }
}

// ✅ CORRECT - Specific, actionable documentation
/// Processes data with comprehensive validation
/// 
/// Validates data format, checks processing constraints, and updates
/// the result state atomically.
fn process_data_item(data_id: u32, processor_id: u32) -> bool {
    // Retrieve data and validate processing status
    let data = get_data_by_id(data_id);
    assert(!data.is_processed, 'Data already processed');
    
    // Verify processor has sufficient capacity
    let processor = get_processor(processor_id);
    assert(processor.free_capacity() > 0, 'Processor full');
    
    // Execute atomic state update
    update_processing_state(data, processor);
    true
}
```

### Documentation Maintenance Patterns

#### Module-Level Documentation Strategy
```cairo
//! # Data Processing Module
//! 
//! This module implements efficient data processing algorithms using
//! Cairo's type system and memory model for optimal performance.
//! 
//! ## Key Features
//! 
//! - Type-safe data transformations
//! - Memory-efficient operations
//! - Comprehensive error handling
//! - Extensible processing pipeline
//! 
//! ## Usage
//! 
//! ```cairo
//! let processor = DataProcessor::new();
//! let result = processor.process(input_data);
//! ```
```

#### Function Documentation Standards
```cairo
/// Transforms input data using specified algorithm
/// 
/// Applies a transformation algorithm to the input data while maintaining
/// type safety and memory efficiency. The function ensures data integrity
/// through comprehensive validation.
/// 
/// # Arguments
/// * `input` - Source data to transform
/// * `algorithm` - Transformation algorithm to apply
/// * `options` - Processing options and parameters
/// 
/// # Returns
/// Transformed data in the target format
/// 
/// # Panics
/// * If input data is invalid or corrupted
/// * If algorithm is not supported
/// * If memory allocation fails
/// 
/// # Examples
/// ```cairo
/// let result = transform_data(
///     source_data,
///     Algorithm::Compress,
///     ProcessingOptions::default()
/// );
/// ```
fn transform_data(
    input: SourceData,
    algorithm: Algorithm,
    options: ProcessingOptions,
) -> TargetData {
    // Implementation with detailed inline comments
    assert!(!input.is_empty(), "Input data cannot be empty");
    
    // Apply transformation algorithm with error handling
    let intermediate = algorithm.apply(input);
    
    // Finalize transformation with options
    options.finalize(intermediate)
}
```

## 2. Trait-Based Design Patterns in Cairo

### Core Trait Philosophy
Cairo emphasizes **composition over inheritance**, using traits to define shared behavior across different types. Unlike Solidity's inheritance model, Cairo champions composability through trait-based design.

### Advanced Trait Patterns

#### Default Implementation Pattern
```cairo
trait Summary {
    fn summarize_author(self: @Self) -> ByteArray;
    
    // Default implementation that can be overridden
    fn summarize(self: @Self) -> ByteArray {
        format!("(Read more from {}...)", self.summarize_author())
    }
}
```

#### Trait Composition Pattern
```cairo
trait Movable {
    fn move_to(ref self: Self, position: Position);
}

trait Attackable {
    fn attack(ref self: Self, target: EntityId) -> AttackResult;
}

// Compose traits for complex behaviors
trait Combatant: Movable + Attackable {
    fn combat_action(ref self: Self, action: CombatAction);
}
```

#### Generic Trait Constraints
```cairo
trait Serializable<T> {
    fn serialize(self: @Self) -> Span<felt252>;
    fn deserialize(data: Span<felt252>) -> T;
    fn type_id() -> felt252;
}

// Use trait bounds for generic functions
fn store_data<T, +Serializable<T>>(data: T) -> Span<felt252> {
    data.serialize()
}
```

## 3. Memory Management and Ownership Patterns

### Snapshot and Reference Patterns

```cairo
// Efficient snapshot usage
fn calculate_total(values: @Array<u32>) -> u32 {
    let mut total = 0;
    let mut i = 0;
    while i < values.len() {
        total += *values.at(i);
        i += 1;
    }
    total
}

// Reference passing for mutation
fn update_values(ref values: Array<u32>, increment: u32) {
    let mut i = 0;
    while i < values.len() {
        let current = values.at(i);
        values.set(i, *current + increment);
        i += 1;
    }
}
```

### Clone vs Move Semantics

```cairo
// Explicit clone for expensive operations
fn expensive_clone_operation(data: @LargeStruct) -> LargeStruct {
    data.clone() // Explicit clone when needed
}

// Move semantics for ownership transfer
fn transfer_ownership(data: OwnedData) -> ProcessedData {
    // data is moved here, cannot be used after
    process_and_transform(data)
}
```

## 4. Type System Patterns

### Advanced Enum Patterns

```cairo
/// Comprehensive result type with error details
#[derive(Drop, Serde)]
pub enum ProcessingResult<T> {
    Success: T,
    Error: ProcessingError,
    Partial: (T, Array<Warning>),
}

/// Error type with context information
#[derive(Drop, Serde)]
pub enum ProcessingError {
    InvalidInput: ByteArray,
    ResourceExhausted: felt252,
    InternalError: (u32, ByteArray),
}

// Pattern matching with comprehensive error handling
fn handle_result<T>(result: ProcessingResult<T>) -> Option<T> {
    match result {
        ProcessingResult::Success(value) => Option::Some(value),
        ProcessingResult::Error(err) => {
            log_error(err);
            Option::None
        },
        ProcessingResult::Partial(value, warnings) => {
            log_warnings(warnings);
            Option::Some(value)
        }
    }
}
```

### Generic Type Patterns

```cairo
/// Generic container with type constraints
#[derive(Drop, Serde)]
pub struct Container<T> {
    items: Array<T>,
    capacity: u32,
    metadata: felt252,
}

#[generate_trait]
pub impl ContainerImpl<T, +Drop<T>, +Serde<T>> of ContainerTrait<T> {
    fn new(capacity: u32) -> Container<T> {
        Container {
            items: ArrayTrait::new(),
            capacity,
            metadata: 0,
        }
    }
    
    fn add(ref self: Container<T>, item: T) -> bool {
        if self.items.len() >= self.capacity {
            return false;
        }
        self.items.append(item);
        true
    }
    
    fn get(self: @Container<T>, index: u32) -> Option<@T> {
        if index >= self.items.len() {
            Option::None
        } else {
            Option::Some(self.items.at(index))
        }
    }
}
```

## 5. Error Handling and Validation Patterns

### Robust Error Handling

#### Assert and Panic Patterns
```cairo
// Validation using assert for conditions
fn validate_input(value: u32, min: u32, max: u32) {
    assert(
        value >= min && value <= max,
        'Value must be within range'
    );
}

// Formatted error messages with context
fn transfer_tokens(ref balance: u32, amount: u32) {
    assert!(
        balance >= amount,
        "Insufficient balance: have {}, need {}",
        balance,
        amount
    );
    balance -= amount;
}
```

#### Result-Based Error Handling  
```cairo
// Use Result for recoverable errors
#[derive(Drop, Serde)]
pub enum ValidationError {
    InvalidFormat,
    OutOfRange,
    MissingRequired,
    TooLarge,
}

fn validate_and_process(
    input: ByteArray
) -> Result<ProcessedData, ValidationError> {
    // Validate format
    if !is_valid_format(input) {
        return Result::Err(ValidationError::InvalidFormat);
    }
    
    // Check constraints
    if input.len() > MAX_SIZE {
        return Result::Err(ValidationError::TooLarge);
    }
    
    // Process valid input
    let processed = process_input(input);
    Result::Ok(processed)
}
```

## 6. Performance Optimization Patterns

### Memory-Efficient Data Structures

```cairo
// Pack data efficiently for gas optimization
#[derive(Drop, Serde)]
struct PackedData {
    // Use felt252 to pack multiple small values
    packed_values: felt252, // Contains flags (8 bits) + counter (16 bits) + type (8 bits)
    timestamp: felt252,
    hash: felt252,
}

// Bit manipulation helpers
mod bit_utils {
    const FLAG_MASK: felt252 = 0xFF;
    const COUNTER_MASK: felt252 = 0xFFFF00;
    const TYPE_MASK: felt252 = 0xFF0000;
    
    fn pack_values(flags: u8, counter: u16, value_type: u8) -> felt252 {
        flags.into() + (counter.into() * 0x100) + (value_type.into() * 0x10000)
    }
    
    fn unpack_flags(packed: felt252) -> u8 {
        (packed & FLAG_MASK).try_into().unwrap()
    }
    
    fn unpack_counter(packed: felt252) -> u16 {
        ((packed & COUNTER_MASK) / 0x100).try_into().unwrap()
    }
}
```

### Efficient Array Operations

```cairo
// Batch operations for efficiency
fn batch_process<T, +Drop<T>, +Copy<T>>(
    items: @Array<T>,
    processor: fn(@T) -> T
) -> Array<T> {
    let mut results = ArrayTrait::new();
    let mut i = 0;
    
    while i < items.len() {
        let processed = processor(items.at(i));
        results.append(processed);
        i += 1;
    }
    
    results
}

// Memory-efficient filtering
fn filter_items<T, +Drop<T>, +Copy<T>>(
    items: @Array<T>,
    predicate: fn(@T) -> bool
) -> Array<T> {
    let mut filtered = ArrayTrait::new();
    let mut i = 0;
    
    while i < items.len() {
        let item = items.at(i);
        if predicate(item) {
            filtered.append(*item);
        }
        i += 1;
    }
    
    filtered
}
```

## 7. Cryptographic and Hash Patterns

### Safe Hashing Patterns

```cairo
use poseidon::poseidon_hash_span;

// Safe hash computation with overflow protection
fn generate_safe_id(components: Array<felt252>) -> u32 {
    let hash = poseidon_hash_span(components.span());
    let hash_u256: u256 = hash.into();
    // Use modulo to constrain to u32 range
    (hash_u256 % 0x100000000_u256).try_into().unwrap()
}

// Merkle tree verification
fn verify_merkle_proof(
    leaf: felt252,
    root: felt252,
    proof: Array<felt252>
) -> bool {
    let mut current_hash = leaf;
    let mut i = 0;
    
    while i < proof.len() {
        let proof_element = *proof.at(i);
        current_hash = poseidon_hash_span(
            array![current_hash, proof_element].span()
        );
        i += 1;
    }
    
    current_hash == root
}
```

## 8. Advanced Control Flow Patterns

### Recursive Patterns
```cairo
// Tail-recursive function for efficiency
fn factorial_tail_recursive(n: u32, accumulator: u32) -> u32 {
    if n <= 1 {
        accumulator
    } else {
        factorial_tail_recursive(n - 1, n * accumulator)
    }
}

// Recursive data processing
fn process_nested_data(data: NestedData, depth: u32) -> ProcessedData {
    if depth == 0 {
        return ProcessedData::Empty;
    }
    
    let processed_children = process_children(data.children, depth - 1);
    ProcessedData::Node(data.value, processed_children)
}
```

### Loop Patterns and Alternatives
```cairo
// While loop for bounded iteration
fn bounded_search<T, +PartialEq<T>>(
    items: @Array<T>,
    target: @T,
    max_iterations: u32
) -> Option<u32> {
    let mut i = 0;
    let limit = items.len().min(max_iterations);
    
    while i < limit {
        if items.at(i) == target {
            return Option::Some(i);
        }
        i += 1;
    }
    
    Option::None
}
```

## Key Cairo Architectural Principles

1. **Trait Composition Over Inheritance**: Use traits and composition instead of hierarchical structures
2. **Explicit Memory Management**: Understand snapshot (@) vs reference (ref) semantics
3. **Type Safety First**: Leverage Cairo's strong type system to prevent errors at compile time
4. **Gas-Optimized Operations**: Pack data efficiently and use batch operations when possible
5. **Robust Error Handling**: Combine assertions for invariants with Result types for recoverable errors
6. **Documentation as Code**: Write documentation that compiles and serves as executable examples
7. **Generic Programming**: Use generics and trait bounds for reusable, type-safe code

This pattern collection provides a foundation for writing sophisticated, efficient, and maintainable Cairo code that leverages the language's unique features and constraints.