// tests/integration_tests.rs
use neopilot_tokenizers::{State, from_pretrained, encode};
use std::sync::Arc;

#[test]
fn test_end_to_end_workflow() {
    // Initialize
    let state = Arc::new(State::new());
    
    // Load model
    from_pretrained(&state, "gpt-4o").expect("Failed to load model");
    
    // Process multiple texts
    let texts = [
        "Hello, world!",
        "This is a test",
        "Another test string",
        "The quick brown fox jumps over the lazy dog",
    ];
    
    for text in &texts {
        let (tokens, num_tokens, num_chars) = encode(&state, text).unwrap();
        assert!(!tokens.is_empty());
        assert_eq!(num_chars, text.chars().count());
        assert!(num_tokens > 0);
    }
}