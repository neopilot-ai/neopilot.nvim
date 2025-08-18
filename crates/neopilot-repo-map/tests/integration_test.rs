//! Integration tests for the neopilot-repo-map crate

use neopilot_repo_map::config::{Config, ConfigLoader};
use std::env;
use std::fs;
use std::path::Path;
use tempfile::tempdir;

#[test]
fn test_config_integration() -> anyhow::Result<()> {
    // Create a temporary directory for our test
    let dir = tempdir()?;
    let config_path = dir.path().join("config.toml");
    
    // Write a test configuration file
    let config_content = r#"
    [tokenizer]
    model = "test-model"
    max_tokens = 2048
    chunk_size = 500
    
    [network]
    max_retries = 5
    connect_timeout = 15
    
    [cache]
    enabled = false
    ttl = 3600
    
    [performance]
    worker_threads = 2
    channel_capacity = 100
    
    [logging]
    level = "debug"
    file = "test.log"
    "#;
    
    fs::write(&config_path, config_content)?;
    
    // Set some environment variables to override the config
    env::set_var("NEOPILOT_TOKENIZER_MODEL", "env-override-model");
    env::set_var("NEOPILOT_NETWORK__MAX_RETRIES", "3");
    
    // Load the configuration
    let config = ConfigLoader::new()
        .with_config_path(&config_path)
        .with_override("performance.worker_threads", "4")
        .load()?;
    
    // Verify the configuration was loaded correctly
    assert_eq!(config.tokenizer.model, "env-override-model"); // From env var
    assert_eq!(config.tokenizer.max_tokens, 2048); // From file
    assert_eq!(config.tokenizer.chunk_size, 500); // From file
    assert_eq!(config.network.max_retries, 3); // From env var (overrides file)
    assert_eq!(config.network.connect_timeout.as_secs(), 15); // From file
    assert!(!config.cache.enabled); // From file
    assert_eq!(config.performance.worker_threads, 4); // From manual override
    assert_eq!(config.performance.channel_capacity, 100); // From file
    assert_eq!(config.logging.level, "debug"); // From file
    
    // Clean up
    env::remove_var("NEOPILOT_TOKENIZER_MODEL");
    env::remove_var("NEOPILOT_NETWORK__MAX_RETRIES");
    
    Ok(())
}

#[test]
fn test_default_config() {
    let config = Config::default();
    
    // Verify some default values
    assert_eq!(config.tokenizer.model, "gpt-4o");
    assert!(config.cache.enabled);
    assert!(config.performance.worker_threads > 0);
    assert_eq!(config.logging.level, "info");
}

#[test]
fn test_config_validation() {
    let mut config = Config::default();
    
    // Test invalid tokenizer configuration
    config.tokenizer.max_tokens = 0;
    assert!(config.validate().is_err());
    
    // Reset to valid value
    config.tokenizer.max_tokens = 4096;
    
    // Test invalid network configuration
    config.network.max_retries = 11;
    assert!(config.validate().is_err());
}
