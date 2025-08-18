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

/// Lua bindings for the tokenizer
#[cfg(feature = "lua")]
impl State {
    /// Register the tokenizer with Lua
    pub fn register(lua: &Lua) -> Result<()> {
        let globals = lua.globals();
        
        // Create a new state
        let state = State::new();
        
        // Store the state in the Lua registry
        lua.set_named_registry_value("tokenizer_state", lua.create_any_userdata(state)?)?;
        
        // Register the encode function
        let encode_fn = lua.create_function(|lua, (text,): (String,)| {
            let state = lua.named_registry_value::<State>("tokenizer_state")
                .map_err(|e| LuaError::RuntimeError(e.to_string()))?;
                
            let (tokens, num_tokens, num_chars) = encode(&state, &text)
                .map_err(|e| LuaError::RuntimeError(e.to_string()))?;
                
            let tokens_table = lua.create_sequence_from(tokens)?;
            Ok((tokens_table, num_tokens, num_chars))
        })?;
        
        // Register the from_pretrained function
        let from_pretrained_fn = lua.create_function(|lua, (model,): (String,)| {
            let state = lua.named_registry_value::<State>("tokenizer_state")
                .map_err(|e| LuaError::RuntimeError(e.to_string()))?;
                
            from_pretrained(&state, &model)
                .map_err(|e| LuaError::RuntimeError(e.to_string()))
        })?;
        
        // Create a table to hold the functions
        let tokenizer_table = lua.create_table()?;
        tokenizer_table.set("encode", encode_fn)?;
        tokenizer_table.set("from_pretrained", from_pretrained_fn)?;
        
        // Set the global
        globals.set("tokenizer", tokenizer_table)?;
        
        Ok(())
    }
}
        _ => TokenizerType::HuggingFace(Box::new(HuggingFaceTokenizer::new(model)?)),
    };
    
    let mut tokenizer_mutex = state.tokenizer.lock()
        .map_err(|_| TokenizerError::TokenizerError("Failed to acquire lock".to_string()))?;
        
    *tokenizer_mutex = Some(tokenizer);
    Ok(())
}

#[mlua::lua_module]
fn neopilot_tokenizers(lua: &Lua) -> LuaResult<LuaTable> {
    let core = State::new();
    let state = Arc::new(core);
    let state_clone = Arc::clone(&state);

    let exports = lua.create_table()?;
    
    exports.set(
        "from_pretrained",
        lua.create_function(move |_, model: String| {
            from_pretrained(&state, &model)?;
            Ok(())
        })?,
    )?;
    
    exports.set(
        "encode",
        lua.create_function(move |_, text: String| {
            let result = encode(&state_clone, &text)?;
            Ok(result)
        })?,
    )?;
    
    // Add version info
    exports.set("VERSION", env!("CARGO_PKG_VERSION"))?;
    
    Ok(exports)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_tiktoken() {
        let model = "gpt-4o";
        let source = "Hello, world!";
        let tokenizer = Tiktoken::new(model);
        let (tokens, num_tokens, num_chars) = tokenizer.encode(source);
        assert_eq!(tokens, vec![13225, 11, 2375, 0]);
        assert_eq!(num_tokens, 4);
        assert_eq!(num_chars, source.chars().count());
    }

    #[test]
    fn test_hf() {
        let model = "gpt2";
        let source = "Hello, world!";
        let tokenizer = HuggingFaceTokenizer::new(model);
        let (tokens, num_tokens, num_chars) = tokenizer.encode(source);
        assert_eq!(tokens, vec![15496, 11, 995, 0]);
        assert_eq!(num_tokens, 4);
        assert_eq!(num_chars, source.chars().count());
    }

    #[test]
    fn test_roundtrip() {
        let state = State::new();
        let source = "Hello, world!";
        let model = "gpt2";

        from_pretrained(&state, model);
        let (tokens, num_tokens, num_chars) = encode(&state, "Hello, world!").unwrap();
        assert_eq!(tokens, vec![15496, 11, 995, 0]);
        assert_eq!(num_tokens, 4);
        assert_eq!(num_chars, source.chars().count());
    }

    // For example: https://storage.googleapis.com/cohere-public/tokenizers/command-r-08-2024.json
    // Disable testing on GitHub Actions to avoid rate limiting and file size limits
    #[test]
    fn test_public_url() {
        if std::env::var("GITHUB_ACTIONS").is_ok() {
            return;
        }
        let state = State::new();
        let source = "Hello, world!";
        let model =
            "https://storage.googleapis.com/cohere-public/tokenizers/command-r-08-2024.json";

        from_pretrained(&state, model);
        let (tokens, num_tokens, num_chars) = encode(&state, "Hello, world!").unwrap();
        assert_eq!(tokens, vec![28339, 19, 3845, 8]);
        assert_eq!(num_tokens, 4);
        assert_eq!(num_chars, source.chars().count());
    }
}
