//! Configuration management for Neopilot Repo Map
//! 
//! This module handles loading, validating, and managing configuration from
//! various sources including files, environment variables, and defaults.

mod error;
mod loader;
mod validation;

use std::path::PathBuf;
use std::time::Duration;
use std::collections::HashMap;
use serde::{Deserialize, Serialize};
use thiserror::Error;

pub use error::ConfigError;
pub use loader::ConfigLoader;
pub use validation::validate_config;

/// Main configuration structure containing all configuration options
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct Config {
    /// Tokenizer configuration
    pub tokenizer: TokenizerConfig,
    /// Network-related configuration
    pub network: NetworkConfig,
    /// Caching configuration
    pub cache: CacheConfig,
    /// Performance-related settings
    pub performance: PerformanceConfig,
    /// Logging configuration
    pub logging: LoggingConfig,
    /// Internal field for storing raw configuration values
    #[serde(skip_serializing, skip_deserializing)]
    pub overrides: HashMap<String, toml::Value>,
}

/// Configuration for tokenizer-related settings
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct TokenizerConfig {
    /// The model to use for tokenization
    pub model: String,
    /// Directory for caching tokenizer files
    pub cache_dir: PathBuf,
    /// Maximum number of tokens to process
    pub max_tokens: usize,
    /// Size of text chunks to process at once
    pub chunk_size: usize,
    /// Number of items to process in a batch
    pub batch_size: usize,
    /// Timeout for tokenizer operations
    pub timeout: Duration,
}

/// Network-related configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct NetworkConfig {
    /// Maximum number of retry attempts
    pub max_retries: u32,
    /// Connection timeout in seconds
    pub connect_timeout: Duration,
    /// Request timeout in seconds
    pub request_timeout: Duration,
    /// List of allowed domains for network requests
    pub allowed_domains: Vec<String>,
    /// Maximum download size in bytes
    pub max_download_size: u64,
}

/// Caching configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct CacheConfig {
    /// Whether caching is enabled
    pub enabled: bool,
    /// Time-to-live for cache entries in seconds
    pub ttl: Duration,
    /// Maximum cache size in bytes
    pub max_size: u64,
    /// Path to the cache directory
    pub path: PathBuf,
}

/// Performance-related configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct PerformanceConfig {
    /// Number of worker threads to use
    pub worker_threads: usize,
    /// Capacity of the channel for inter-thread communication
    pub channel_capacity: usize,
    /// Debounce time in milliseconds
    pub debounce_ms: u64,
    /// Maximum memory usage in MB
    pub max_memory_mb: u64,
}

/// Logging configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct LoggingConfig {
    /// Logging level (error, warn, info, debug, trace)
    pub level: String,
    /// Optional path to log file
    pub file: Option<PathBuf>,
    /// Maximum number of log files to keep
    pub max_files: usize,
    /// Maximum size of each log file in MB
    pub max_size_mb: u64,
}

// Implement default values for all configuration structs
impl Default for Config {
    fn default() -> Self {
        Self {
            tokenizer: TokenizerConfig::default(),
            network: NetworkConfig::default(),
            cache: CacheConfig::default(),
            performance: PerformanceConfig::default(),
            logging: LoggingConfig::default(),
            overrides: HashMap::new(),
        }
    }
}

impl Default for TokenizerConfig {
    fn default() -> Self {
        Self {
            model: "gpt-4o".to_string(),
            cache_dir: dirs::cache_dir()
                .unwrap_or_else(|| PathBuf::from("/tmp/neopilot")),
            max_tokens: 4096,
            chunk_size: 1000,
            batch_size: 10,
            timeout: Duration::from_secs(30),
        }
    }
}

impl Default for NetworkConfig {
    fn default() -> Self {
        Self {
            max_retries: 3,
            connect_timeout: Duration::from_secs(10),
            request_timeout: Duration::from_secs(30),
            allowed_domains: vec![
                "huggingface.co".to_string(),
                "cdn-lfs.huggingface.co".to_string(),
            ],
            max_download_size: 100 * 1024 * 1024, // 100MB
        }
    }
}

impl Default for CacheConfig {
    fn default() -> Self {
        let mut cache_path = dirs::cache_dir().unwrap_or_else(|| PathBuf::from("/tmp/neopilot"));
        cache_path.push("cache");
        
        Self {
            enabled: true,
            ttl: Duration::from_secs(24 * 60 * 60), // 24 hours
            max_size: 1024 * 1024 * 1024, // 1GB
            path: cache_path,
        }
    }
}

impl Default for PerformanceConfig {
    fn default() -> Self {
        Self {
            worker_threads: num_cpus::get().max(1),
            channel_capacity: 1000,
            debounce_ms: 100,
            max_memory_mb: 4096,
        }
    }
}

impl Default for LoggingConfig {
    fn default() -> Self {
        let mut log_path = dirs::cache_dir().unwrap_or_else(|| PathBuf::from("/tmp/neopilot"));
        log_path.push("neopilot.log");
        
        Self {
            level: "info".to_string(),
            file: Some(log_path),
            max_files: 5,
            max_size_mb: 50,
        }
    }
}

impl Config {
    /// Create a new configuration with default values
    pub fn new() -> Result<Self, ConfigError> {
        let mut config = Self::default();
        
        // Load from file if exists
        if let Some(config_path) = ConfigLoader::find_config_file()? {
            config.merge_from_file(&config_path)?;
        }
        
        // Apply environment variable overrides
        config.apply_env_overrides()?;
        
        // Validate the configuration
        validate_config(&config)?;
        
        Ok(config)
    }
    
    /// Merge configuration from a file
    pub fn merge_from_file(&mut self, path: &std::path::Path) -> Result<(), ConfigError> {
        let content = std::fs::read_to_string(path)
            .map_err(|e| ConfigError::IoError(e, path.to_path_buf()))?;
            
        let new_config: Self = toml::from_str(&content)
            .map_err(|e| ConfigError::TomlError(e, path.to_path_buf()))?;
            
        *self = new_config;
        Ok(())
    }
    
    /// Apply environment variable overrides
    pub fn apply_env_overrides(&mut self) -> Result<(), ConfigError> {
        for (key, value) in std::env::vars() {
            if let Some(rest) = key.strip_prefix("NEOPILOT_") {
                let path = rest.to_lowercase().replace("__", ".");
                self.set_from_str(&path, &value)?;
            }
        }
        Ok(())
    }
    
    /// Set a configuration value from a string path
    pub fn set_from_str(&mut self, path: &str, value: &str) -> Result<(), ConfigError> {
        // Store the raw value for later deserialization
        let mut current = toml::value::Table::new();
        let mut keys: Vec<&str> = path.split('.').collect();
        
        if keys.is_empty() {
            return Err(ConfigError::InvalidPath(path.to_string()));
        }
        
        let last_key = keys.pop().unwrap();
        let mut current_table = &mut current;
        
        for key in keys {
            let nested = toml::value::Table::new();
            current_table.insert(key.to_string(), toml::Value::Table(nested));
            current_table = match current_table.get_mut(key) {
                Some(toml::Value::Table(t)) => t,
                _ => return Err(ConfigError::InvalidPath(path.to_string())),
            };
        }
        
        // Try to parse the value as different types
        if let Ok(bool_val) = value.parse::<bool>() {
            current_table.insert(last_key.to_string(), toml::Value::Boolean(bool_val));
        } else if let Ok(int_val) = value.parse::<i64>() {
            current_table.insert(last_key.to_string(), toml::Value::Integer(int_val));
        } else if let Ok(float_val) = value.parse::<f64>() {
            current_table.insert(last_key.to_string(), toml::Value::Float(float_val));
        } else {
            // Default to string
            current_table.insert(last_key.to_string(), toml::Value::String(value.to_string()));
        }
        
        // Merge with existing config
        let new_config: Config = toml::Value::Table(current).try_into()
            .map_err(|e| ConfigError::InvalidValue(format!("Failed to convert TOML to config: {}", e)))?;
            
        *self = new_config;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::env;
    use std::fs;
    use tempfile::tempdir;
    
    #[test]
    fn test_default_config() {
        let config = Config::default();
        assert_eq!(config.tokenizer.model, "gpt-4o");
        assert_eq!(config.network.max_retries, 3);
        assert!(config.cache.enabled);
    }
    
    #[test]
    fn test_env_override() -> Result<(), Box<dyn std::error::Error>> {
        env::set_var("NEOPILOT_TOKENIZER_MODEL", "gpt-4");
        env::set_var("NEOPILOT_NETWORK__MAX_RETRIES", "5");
        
        let mut config = Config::default();
        config.apply_env_overrides()?;
        
        assert_eq!(config.tokenizer.model, "gpt-4");
        assert_eq!(config.network.max_retries, 5);
        
        env::remove_var("NEOPILOT_TOKENIZER_MODEL");
        env::remove_var("NEOPILOT_NETWORK__MAX_RETRIES");
        
        Ok(())
    }
    
    #[test]
    fn test_merge_from_file() -> Result<(), Box<dyn std::error::Error>> {
        let dir = tempdir()?;
        let file_path = dir.path().join("config.toml");
        
        let config_content = r#"
        [tokenizer]
        model = "custom-model"
        max_tokens = 2048
        
        [network]
        max_retries = 2
        "#;
        
        fs::write(&file_path, config_content)?;
        
        let mut config = Config::default();
        config.merge_from_file(&file_path)?;
        
        assert_eq!(config.tokenizer.model, "custom-model");
        assert_eq!(config.tokenizer.max_tokens, 2048);
        assert_eq!(config.network.max_retries, 2);
        
        Ok(())
    }
}
