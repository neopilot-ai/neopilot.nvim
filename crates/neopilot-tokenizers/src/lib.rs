//! # Neopilot Tokenizers
//! 
//! A Rust library for tokenization with support for multiple backends including
//! Tiktoken and HuggingFace tokenizers.

pub mod error;
pub mod tiktoken;
pub mod huggingface;

use std::sync::{Arc, Mutex};

pub use error::{Result, TokenizerError};
use tiktoken::Tiktoken;
use huggingface::HuggingFaceTokenizer;

/// Represents the type of tokenizer being used
pub enum TokenizerType {
    /// Tiktoken tokenizer (used by OpenAI models)
    Tiktoken(Tiktoken),
    /// HuggingFace tokenizer (for models from the HuggingFace Hub)
    HuggingFace(Box<HuggingFaceTokenizer>),
}

/// Global state for the tokenizer
#[derive(Clone)]
pub struct State {
    /// The tokenizer instance wrapped in an Arc<Mutex<>> for thread safety
    pub tokenizer: Arc<Mutex<Option<TokenizerType>>>,
}

impl State {
    /// Create a new State with no tokenizer loaded
    pub fn new() -> Self {
        Self {
            tokenizer: Arc::new(Mutex::new(None)),
        }
    }
}

/// Load a pretrained tokenizer by model name or path
///
/// # Arguments
/// * `state` - The global state to store the tokenizer in
/// * `model` - The model name (e.g., "gpt-4") or path to a local tokenizer file
///
/// # Returns
/// `Result<()>` indicating success or failure
pub fn from_pretrained(state: &State, model: &str) -> Result<()> {
    let mut tokenizer_mutex = state.tokenizer.lock()
        .map_err(|e| TokenizerError::LockError(e.to_string()))?;
    
    *tokenizer_mutex = Some(match model {
        "gpt-4" | "gpt-3.5-turbo" => {
            let tiktoken = Tiktoken::new(model)?;
            TokenizerType::Tiktoken(tiktoken)
        },
        _ => {
            let hf_tokenizer = HuggingFaceTokenizer::new(model)?;
            TokenizerType::HuggingFace(Box::new(hf_tokenizer))
        },
    });
    
    Ok(())
}

/// Encode text into tokens using the loaded tokenizer
///
/// # Arguments
/// * `state` - The global state containing the tokenizer
/// * `text` - The text to encode
///
/// # Returns
/// A tuple containing:
/// - A vector of token IDs
/// - The number of tokens
/// - The number of characters in the input text
pub fn encode(state: &State, text: &str) -> Result<(Vec<u32>, usize, usize)> {
    let tokenizer = state.tokenizer.lock()
        .map_err(|e| TokenizerError::LockError(e.to_string()))?;
        
    match tokenizer.as_ref() {
        Some(TokenizerType::Tiktoken(tokenizer)) => {
            let (tokens, num_tokens, num_chars) = tokenizer.encode(text);
            Ok((tokens, num_tokens, num_chars))
        },
        Some(TokenizerType::HuggingFace(tokenizer)) => {
            tokenizer.encode(text)
        },
        None => Err(TokenizerError::TokenizerError("Tokenizer not initialized".to_string())),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_tokenizer_initialization() {
        let state = State::new();
        assert!(from_pretrained(&state, "gpt-4").is_ok());
    }

    #[test]
    fn test_encoding() {
        let state = State::new();
        from_pretrained(&state, "gpt-4").unwrap();
        let (tokens, num_tokens, num_chars) = encode(&state, "Hello, world!").unwrap();
        assert!(!tokens.is_empty());
        assert!(num_tokens > 0);
        assert!(num_chars > 0);
    }
}

    
