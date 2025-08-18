// tests/property_tests.rs
use proptest::prelude::*;
use neopilot_tokenizers::{State, from_pretrained, encode};
use std::sync::Arc;

proptest! {
    #[test]
    fn test_tokenizer_roundtrip(text in "\\PC*") {
        let state = Arc::new(State::new());
        from_pretrained(&state, "gpt-4o").unwrap();
        
        let (tokens, _, _) = encode(&state, &text).unwrap();
        // In a real implementation, we would decode tokens back and compare
        // This is a simplified example
        assert!(!tokens.is_empty());
    }
    
    #[test]
    fn test_tokenizer_length_properties(text in "\\PC*") {
        let state = Arc::new(State::new());
        from_pretrained(&state, "gpt-4o").unwrap();
        
        let (tokens, num_tokens, num_chars) = encode(&state, &text).unwrap();
        
        // Number of tokens should be <= number of characters for most cases
        // (there are exceptions for some tokenizers, adjust accordingly)
        prop_assert!(num_tokens <= text.chars().count() || text.is_empty());
        
        // Empty string should produce no tokens
        if text.is_empty() {
            prop_assert_eq!(num_tokens, 0);
            prop_assert!(tokens.is_empty());
        }
    }
}