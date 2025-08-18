//! Tiktoken tokenizer implementation for OpenAI models

use crate::error::{Result, TokenizerError};
use tiktoken_rs::CoreBPE;

/// Wrapper around the Tiktoken tokenizer
pub struct Tiktoken {
    bpe: CoreBPE,
}

impl Tiktoken {
    /// Create a new Tiktoken tokenizer for the specified model
    ///
    /// # Arguments
    /// * `model` - The model name (e.g., "gpt-4")
    pub fn new(model: &str) -> Result<Self> {
        let bpe = tiktoken_rs::get_bpe_from_model(model)
            .map_err(|e| TokenizerError::ModelLoadError(e.to_string()))?;
        Ok(Self { bpe })
    }

    /// Encode text into tokens
    ///
    /// # Arguments
    /// * `text` - The text to encode
    ///
    /// # Returns
    /// A tuple containing:
    /// - A vector of token IDs
    /// - The number of tokens
    /// - The number of characters in the input text
    pub fn encode(&self, text: &str) -> (Vec<u32>, usize, usize) {
        let tokens = self.bpe.encode_with_special_tokens(text);
        let num_tokens = tokens.len();
        let num_chars = text.chars().count();
        (tokens, num_tokens, num_chars)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_tiktoken_initialization() {
        let tokenizer = Tiktoken::new("gpt-4");
        assert!(tokenizer.is_ok());
    }

    #[test]
    fn test_tiktoken_encoding() {
        let tokenizer = Tiktoken::new("gpt-4").unwrap();
        let (tokens, num_tokens, num_chars) = tokenizer.encode("Hello, world!");
        assert!(!tokens.is_empty());
        assert!(num_tokens > 0);
        assert_eq!(num_chars, 13);
    }

    #[test]
    fn test_invalid_model() {
        let tokenizer = Tiktoken::new("invalid-model");
        assert!(matches!(
            tokenizer,
            Err(TokenizerError::ModelLoadError(_))
        ));
    }
}
