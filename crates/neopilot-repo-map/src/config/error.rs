//! Error types for configuration handling

use std::fmt;
use std::path::PathBuf;
use std::io;

/// Errors that can occur during configuration loading and processing
#[derive(Debug, Error)]
pub enum ConfigError {
    /// I/O error while reading configuration
    #[error("I/O error reading {1:?}: {0}")]
    IoError(io::Error, PathBuf),
    
    /// TOML parsing error
    #[error("TOML error in {1:?}: {0}")]
    TomlError(toml::de::Error, PathBuf),
    
    /// Invalid configuration path
    #[error("Invalid configuration path: {0}")]
    InvalidPath(String),
    
    /// Could not determine configuration directory
    #[error("Could not determine configuration directory")]
    NoConfigDir,
    
    /// Configuration validation error
    #[error("Configuration validation error: {0}")]
    ValidationError(String),
    
    /// Invalid configuration value
    #[error("Invalid configuration value: {0}")]
    InvalidValue(String),
    
    /// Missing required configuration
    #[error("Missing required configuration: {0}")]
    MissingValue(String),
}

impl From<ConfigError> for std::io::Error {
    fn from(err: ConfigError) -> Self {
        match err {
            ConfigError::IoError(e, _) => e,
            _ => io::Error::new(io::ErrorKind::Other, err.to_string()),
        }
    }
}

impl From<toml::de::Error> for ConfigError {
    fn from(err: toml::de::Error) -> Self {
        ConfigError::TomlError(err, PathBuf::from("<unknown>"))
    }
}

impl From<io::Error> for ConfigError {
    fn from(err: io::Error) -> Self {
        ConfigError::IoError(err, PathBuf::from("<unknown>"))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io;
    
    #[test]
    fn test_io_error_display() {
        let io_error = io::Error::new(io::ErrorKind::NotFound, "File not found");
        let config_error = ConfigError::IoError(io_error, PathBuf::from("config.toml"));
        
        assert_eq!(
            config_error.to_string(),
            "I/O error reading \"config.toml\": File not found"
        );
    }
    
    #[test]
    fn test_validation_error_display() {
        let error = ConfigError::ValidationError("invalid value".to_string());
        assert_eq!(
            error.to_string(),
            "Configuration validation error: invalid value"
        );
    }
    
    #[test]
    fn test_from_toml_error() {
        let toml_str = "invalid toml";
        let result: Result<toml::Value, _> = toml::from_str(toml_str);
        
        if let Err(e) = result {
            let config_error: ConfigError = ConfigError::from(e);
            assert!(matches!(config_error, ConfigError::TomlError(_, _)));
        } else {
            panic!("Expected TOML parse error");
        }
    }
}
