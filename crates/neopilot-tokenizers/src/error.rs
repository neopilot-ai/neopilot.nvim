use std::fmt;
use std::path::PathBuf;
use thiserror::Error;

/// Error type for tokenizer operations
#[derive(Debug, thiserror::Error)]
pub enum TokenizerError {
    /// I/O operation failed
    #[error("I/O error: {0}")]
    IoError(#[from] std::io::Error),
    
    /// Tokenizer-specific error
    #[error("Tokenizer error: {0}")]
    TokenizerError(String),
    
    /// Invalid file or directory path
    #[error("Invalid path: {0:?}")]
    InvalidPath(PathBuf),
    
    /// Network-related error
    #[error("Network error: {0}")]
    NetworkError(String),
    
    /// URL parsing error
    #[error("URL error: {0}")]
    UrlError(#[from] url::ParseError),
    
    /// Invalid URL
    #[error("Invalid URL: {0}")]
    InvalidUrl(String),
    
    /// JSON serialization/deserialization error
    #[error("Serialization error: {0}")]
    SerializationError(#[from] serde_json::Error),
    
    /// Failed to load a model
    #[error("Failed to load model: {0}")]
    ModelLoadError(String),
    
    /// Failed to acquire a lock
    #[error("Failed to acquire lock: {0}")]
    LockError(String),
    
    /// Insecure protocol (HTTPS required)
    #[error("Insecure protocol (HTTPS required): {0}")]
    InsecureProtocol(String),
    
    /// Download size exceeded the allowed limit
    #[error("Download size exceeded for {url}: {max_size} bytes")]
    DownloadSizeExceeded {
        /// The URL that was being downloaded
        url: String,
        /// Maximum allowed download size in bytes
        max_size: u64,
    },
    
    /// Domain not allowed
    #[error("Domain not allowed: {0}")]
    DomainNotAllowed(String),
    
    /// Path traversal attempt detected
    #[error("Path traversal attempt detected: {path:?} is outside of {base:?}")]
    PathTraversalAttempt { path: PathBuf, base: PathBuf },
    
    /// Insecure file permissions
    #[error("Insecure file permissions: {0:?}")]
    InsecurePermissions(PathBuf),
    
    /// Path is not absolute
    #[error("Path is not absolute: {0:?}")]
    PathNotAbsolute(PathBuf),
    
    /// Invalid filename
    #[error("Invalid filename: {0}")]
    InvalidFilename(String),
    InsecureProtocol(String),
}

pub type Result<T> = std::result::Result<T, TokenizerError>;

// Implement From for LuaError to convert our error type
impl From<TokenizerError> for mlua::Error {
    fn from(err: TokenizerError) -> Self {
        mlua::Error::RuntimeError(err.to_string())
    }
}
