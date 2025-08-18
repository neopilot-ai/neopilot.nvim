//! HuggingFace tokenizer implementation for models from the HuggingFace Hub

use crate::error::{Result, TokenizerError};
use std::path::{Path, PathBuf};
use tokenizers::Tokenizer;
use url::Url;

const MAX_DOWNLOAD_SIZE: u64 = 100 * 1024 * 1024; // 100MB

/// Wrapper around the HuggingFace tokenizer
pub struct HuggingFaceTokenizer {
    tokenizer: Tokenizer,
}

impl HuggingFaceTokenizer {
    /// Create a new HuggingFace tokenizer
    ///
    /// # Arguments
    /// * `model` - The model name (e.g., "bert-base-uncased") or path to a local tokenizer file
    pub fn new(model: &str) -> Result<Self> {
        let tokenizer_path = if is_valid_url(model)? {
            Self::download_tokenizer(model)?
        } else {
            // For local models, ensure they exist and are accessible
            let path = Path::new(model);
            if !path.exists() {
                return Err(TokenizerError::InvalidPath(path.to_path_buf()));
            }
            path.to_path_buf()
        };

        let tokenizer = Tokenizer::from_file(tokenizer_path)
            .map_err(|e| TokenizerError::TokenizerError(e.to_string()))?;

        Ok(Self { tokenizer })
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
    pub fn encode(&self, text: &str) -> Result<(Vec<u32>, usize, usize)> {
        let encoding = self.tokenizer
            .encode(text, false)
            .map_err(|e| TokenizerError::TokenizerError(e.to_string()))?;

        let tokens = encoding.get_ids().to_vec();
        let num_tokens = tokens.len();
        let num_chars = text.chars().count();

        Ok((tokens, num_tokens, num_chars))
    }

    /// Download a tokenizer from a URL and cache it locally
    fn download_tokenizer(url: &str) -> Result<PathBuf> {
        let parsed_url = validate_url(url)?;
        let filename = parsed_url.path_segments()
            .and_then(|segments| segments.last()
            .filter(|&s| !s.is_empty() && s != "/")
            .map(|s| s.to_string()))
            .ok_or_else(|| TokenizerError::InvalidUrl("Invalid URL path or filename".to_string()))?;
        
        let cache_dir = dirs::cache_dir()
            .ok_or_else(|| TokenizerError::IoError(std::io::Error::new(
                std::io::ErrorKind::NotFound,
                "Could not determine cache directory"
            )))?
            .join("neopilot");
            
        std::fs::create_dir_all(&cache_dir)
            .map_err(TokenizerError::IoError)?;
            
        let cache_path = cache_dir.join(&filename);
        
        // Check if file exists and is valid
        if let Ok(metadata) = std::fs::metadata(&cache_path) {
            if metadata.len() > 0 && metadata.len() < MAX_DOWNLOAD_SIZE * 2 {
                return Ok(cache_path);
            }
        }
        
        // Download the file
        let client = reqwest::blocking::Client::new();
        let response = client.get(url)
            .send()
            .map_err(|e| TokenizerError::NetworkError(e.to_string()))?;
            
        if !response.status().is_success() {
            return Err(TokenizerError::NetworkError(
                format!("HTTP error: {}", response.status())
            ));
        }
        
        // Download with size limit
        let content = response.bytes()
            .map_err(|e| TokenizerError::NetworkError(e.to_string()))?;
            
        if content.len() as u64 > MAX_DOWNLOAD_SIZE {
            return Err(TokenizerError::DownloadSizeExceeded {
                url: url.to_string(),
                max_size: MAX_DOWNLOAD_SIZE,
            });
        }
        
        // Write to temp file first
        let temp_path = cache_path.with_extension(".tmp");
        std::fs::write(&temp_path, &content)
            .map_err(TokenizerError::IoError)?;
            
        // Atomic rename
        std::fs::rename(&temp_path, &cache_path)
            .map_err(TokenizerError::IoError)?;
            
        Ok(cache_path)
    }
}

/// Validate that a URL is valid and secure (HTTPS)
fn is_valid_url(url: &str) -> Result<()> {
    let parsed = Url::parse(url).map_err(TokenizerError::UrlError)?;
    
    // Require HTTPS for security
    if parsed.scheme() != "https" {
        return Err(TokenizerError::InsecureProtocol(url.to_string()));
    }
    
    // Require a domain
    if parsed.host_str().is_none() {
        return Err(TokenizerError::InvalidUrl("Missing host in URL".to_string()));
    }
    
    Ok(())
}

/// Parse and validate a URL
fn validate_url(url: &str) -> Result<Url> {
    let parsed = Url::parse(url).map_err(TokenizerError::UrlError)?;
    is_valid_url(url)?;
    Ok(parsed)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_invalid_url() {
        let result = HuggingFaceTokenizer::new("http://invalid-url");
        assert!(matches!(
            result,
            Err(TokenizerError::InsecureProtocol(_))
        ));
    }

    #[test]
    fn test_nonexistent_file() {
        let result = HuggingFaceTokenizer::new("/nonexistent/path/to/tokenizer.json");
        assert!(matches!(
            result,
            Err(TokenizerError::InvalidPath(_))
        ));
    }
}
