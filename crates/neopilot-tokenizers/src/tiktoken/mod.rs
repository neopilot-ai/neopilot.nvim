use crate::error::{Result, TokenizerError};
use std::sync::Arc;
use tiktoken_rs::CoreBPE;

pub struct Tiktoken {
    bpe: CoreBPE,
}

impl Tiktoken {
    pub fn new(model: &str) -> Result<Self> {
        let bpe = tiktoken_rs::get_bpe_from_model(model)
            .map_err(|e| TokenizerError::ModelLoadError(e.to_string()))?;
        Ok(Self { bpe })
    }

    pub fn encode(&self, text: &str) -> (Vec<u32>, usize, usize) {
        let tokens = self.bpe.encode_ordinary(text);
        let num_tokens = tokens.len();
        let num_chars = text.chars().count();
        (tokens, num_tokens, num_chars)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_invalid_model() {
        let result = Tiktoken::new("invalid-model");
        assert!(matches!(
            result,
            Err(TokenizerError::ModelLoadError(_))
        ));
    }
}
