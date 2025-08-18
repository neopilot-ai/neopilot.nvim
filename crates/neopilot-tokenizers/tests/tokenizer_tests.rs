// tests/tokenizer_tests.rs
use neopilot_tokenizers::*;
use std::sync::Arc;
use std::time::Duration;

#[test]
fn test_tokenizer_initialization() {
    let state = State::new();
    let state = Arc::new(state);
    
    // Test with valid model
    let result = from_pretrained(&state, "gpt-4o");
    assert!(result.is_ok(), "Failed to initialize tokenizer with valid model");
    
    // Test with invalid model
    let result = from_pretrained(&state, "invalid-model");
    assert!(result.is_err(), "Should fail with invalid model");
}

#[test]
fn test_tokenizer_encoding() {
    let state = State::new();
    let state = Arc::new(state);
    
    from_pretrained(&state, "gpt-4o").unwrap();
    
    // Test encoding
    let (tokens, num_tokens, num_chars) = encode(&state, "Hello, world!").unwrap();
    assert!(!tokens.is_empty(), "No tokens generated");
    assert_eq!(num_chars, 13, "Incorrect character count");
    assert!(num_tokens > 0, "No tokens generated");
}

#[test]
fn test_tokenizer_multithreaded() {
    use std::thread;
    
    let state = State::new();
    let state = Arc::new(state);
    from_pretrained(&state, "gpt-4o").unwrap();
    
    let handles: Vec<_> = (0..4).map(|i| {
        let state = state.clone();
        thread::spawn(move || {
            let text = format!("Thread {}: Hello, world!", i);
            let (tokens, _, _) = encode(&state, &text).unwrap();
            (i, tokens)
        })
    }).collect();
    
    for handle in handles {
        let (i, tokens) = handle.join().unwrap();
        assert!(!tokens.is_empty(), "Thread {} failed to encode", i);
    }
}