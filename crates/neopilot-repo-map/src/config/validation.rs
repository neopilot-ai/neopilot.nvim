//! Configuration validation

use super::{Config, ConfigError};
use std::path::Path;

/// Validate the configuration
pub fn validate_config(config: &Config) -> Result<(), ConfigError> {
    validate_tokenizer_config(&config.tokenizer)?;
    validate_network_config(&config.network)?;
    validate_cache_config(&config.cache)?;
    validate_performance_config(&config.performance)?;
    validate_logging_config(&config.logging)?;
    
    Ok(())
}

/// Validate tokenizer configuration
fn validate_tokenizer_config(config: &super::TokenizerConfig) -> Result<(), ConfigError> {
    if config.max_tokens == 0 {
        return Err(ConfigError::ValidationError(
            "tokenizer.max_tokens must be greater than 0".to_string(),
        ));
    }
    
    if config.chunk_size == 0 {
        return Err(ConfigError::ValidationError(
            "tokenizer.chunk_size must be greater than 0".to_string(),
        ));
    }
    
    if config.batch_size == 0 {
        return Err(ConfigError::ValidationError(
            "tokenizer.batch_size must be greater than 0".to_string(),
        ));
    }
    
    if config.timeout.as_secs() == 0 {
        return Err(ConfigError::ValidationError(
            "tokenizer.timeout must be greater than 0".to_string(),
        ));
    }
    
    Ok(())
}

/// Validate network configuration
fn validate_network_config(config: &super::NetworkConfig) -> Result<(), ConfigError> {
    if config.max_retries > 10 {
        return Err(ConfigError::ValidationError(
            "network.max_retries cannot exceed 10".to_string(),
        ));
    }
    
    if config.connect_timeout.as_secs() == 0 {
        return Err(ConfigError::ValidationError(
            "network.connect_timeout must be greater than 0".to_string(),
        ));
    }
    
    if config.request_timeout.as_secs() == 0 {
        return Err(ConfigError::ValidationError(
            "network.request_timeout must be greater than 0".to_string(),
        ));
    }
    
    if config.max_download_size > 1024 * 1024 * 1024 {
        return Err(ConfigError::ValidationError(
            "network.max_download_size cannot exceed 1GB".to_string(),
        ));
    }
    
    Ok(())
}

/// Validate cache configuration
fn validate_cache_config(config: &super::CacheConfig) -> Result<(), ConfigError> {
    if config.enabled {
        if config.ttl.as_secs() == 0 {
            return Err(ConfigError::ValidationError(
                "cache.ttl must be greater than 0 when caching is enabled".to_string(),
            ));
        }
        
        if config.max_size == 0 {
            return Err(ConfigError::ValidationError(
                "cache.max_size must be greater than 0 when caching is enabled".to_string(),
            ));
        }
        
        // Check if cache directory is writable
        if let Some(parent) = config.path.parent() {
            if !parent.exists() {
                std::fs::create_dir_all(parent).map_err(|e| {
                    ConfigError::ValidationError(format!(
                        "Failed to create cache directory {}: {}",
                        parent.display(),
                        e
                    ))
                })?;
            }
            
            // Check if directory is writable
            let test_file = parent.join(".neopilot_test");
            std::fs::write(&test_file, "test").map_err(|e| {
                ConfigError::ValidationError(format!(
                    "Cache directory {} is not writable: {}",
                    parent.display(),
                    e
                ))
            })?;
            std::fs::remove_file(&test_file).ok();
        }
    }
    
    Ok(())
}

/// Validate performance configuration
fn validate_performance_config(config: &super::PerformanceConfig) -> Result<(), ConfigError> {
    if config.worker_threads == 0 {
        return Err(ConfigError::ValidationError(
            "performance.worker_threads must be greater than 0".to_string(),
        ));
    }
    
    if config.channel_capacity == 0 {
        return Err(ConfigError::ValidationError(
            "performance.channel_capacity must be greater than 0".to_string(),
        ));
    }
    
    if config.debounce_ms == 0 {
        return Err(ConfigError::ValidationError(
            "performance.debounce_ms must be greater than 0".to_string(),
        ));
    }
    
    if config.max_memory_mb == 0 {
        return Err(ConfigError::ValidationError(
            "performance.max_memory_mb must be greater than 0".to_string(),
        ));
    }
    
    Ok(())
}

/// Validate logging configuration
fn validate_logging_config(config: &super::LoggingConfig) -> Result<(), ConfigError> {
    // Validate log level
    let valid_levels = ["error", "warn", "info", "debug", "trace"];
    if !valid_levels.contains(&config.level.to_lowercase().as_str()) {
        return Err(ConfigError::ValidationError(format!(
            "Invalid log level '{}'. Must be one of: {}",
            config.level,
            valid_levels.join(", ")
        )));
    }
    
    // Validate log file configuration if logging to file is enabled
    if let Some(log_file) = &config.file {
        if let Some(parent) = log_file.parent() {
            if !parent.exists() {
                std::fs::create_dir_all(parent).map_err(|e| {
                    ConfigError::ValidationError(format!(
                        "Failed to create log directory {}: {}",
                        parent.display(),
                        e
                    ))
                })?;
            }
            
            // Check if directory is writable
            let test_file = parent.join(".neopilot_log_test");
            std::fs::write(&test_file, "test").map_err(|e| {
                ConfigError::ValidationError(format!(
                    "Log directory {} is not writable: {}",
                    parent.display(),
                    e
                ))
            })?;
            std::fs::remove_file(&test_file).ok();
        }
    }
    
    if config.max_files == 0 {
        return Err(ConfigError::ValidationError(
            "logging.max_files must be greater than 0".to_string(),
        ));
    }
    
    if config.max_size_mb == 0 {
        return Err(ConfigError::ValidationError(
            "logging.max_size_mb must be greater than 0".to_string(),
        ));
    }
    
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use super::super::*;
    use std::time::Duration;
    
    #[test]
    fn test_validate_tokenizer_config() {
        let mut config = TokenizerConfig::default();
        
        // Valid config
        assert!(validate_tokenizer_config(&config).is_ok());
        
        // Invalid max_tokens
        config.max_tokens = 0;
        assert!(validate_tokenizer_config(&config).is_err());
        config.max_tokens = 4096;
        
        // Invalid chunk_size
        config.chunk_size = 0;
        assert!(validate_tokenizer_config(&config).is_err());
        config.chunk_size = 1000;
        
        // Invalid batch_size
        config.batch_size = 0;
        assert!(validate_tokenizer_config(&config).is_err());
    }
    
    #[test]
    fn test_validate_network_config() {
        let mut config = NetworkConfig::default();
        
        // Valid config
        assert!(validate_network_config(&config).is_ok());
        
        // Invalid max_retries
        config.max_retries = 11;
        assert!(validate_network_config(&config).is_err());
        config.max_retries = 3;
        
        // Invalid connect_timeout
        config.connect_timeout = Duration::from_secs(0);
        assert!(validate_network_config(&config).is_err());
        config.connect_timeout = Duration::from_secs(10);
        
        // Invalid max_download_size
        config.max_download_size = 2 * 1024 * 1024 * 1024; // 2GB
        assert!(validate_network_config(&config).is_err());
    }
    
    #[test]
    fn test_validate_logging_config() {
        let mut config = LoggingConfig::default();
        
        // Valid config
        assert!(validate_logging_config(&config).is_ok());
        
        // Invalid log level
        config.level = "invalid".to_string();
        assert!(validate_logging_config(&config).is_err());
        config.level = "info".to_string();
        
        // Test with invalid file path (should fail on non-existent parent)
        config.file = Some(Path::new("/nonexistent/path/to/logfile.log").to_path_buf());
        assert!(validate_logging_config(&config).is_err());
    }
}
