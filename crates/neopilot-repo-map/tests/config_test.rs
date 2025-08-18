//! Tests for the configuration system

use neopilot_repo_map::config::{Config, ConfigLoader};
use std::env;
use std::fs;
use std::path::Path;
use tempfile::tempdir;

#[test]
fn test_load_default_config() {
    let config = Config::default();
    assert_eq!(config.tokenizer.model, "gpt-4o");
    assert_eq!(config.network.max_retries, 3);
    assert!(config.cache.enabled);
}

#[test]
fn test_load_from_file() -> anyhow::Result<()> {
    // Create a temporary directory for our test
    let dir = tempdir()?;
    let config_path = dir.path().join("config.toml");
    
    // Write a test configuration file
    let config_content = r#"
    [tokenizer]
    model = "test-model"
    max_tokens = 2048
    
    [network]
    max_retries = 5
    
    [cache]
    enabled = false
    "#;
    
    fs::write(&config_path, config_content)?;
    
    // Load the configuration
    let config = ConfigLoader::new()
        .with_config_path(&config_path)
        .load()?;
    
    // Verify the loaded values
    assert_eq!(config.tokenizer.model, "test-model");
    assert_eq!(config.tokenizer.max_tokens, 2048);
    assert_eq!(config.network.max_retries, 5);
    assert!(!config.cache.enabled);
    
    Ok(())
}

#[test]
fn test_env_overrides() -> anyhow::Result<()> {
    // Set some environment variables
    env::set_var("NEOPILOT_TOKENIZER_MODEL", "env-model");
    env::set_var("NEOPILOT_NETWORK__MAX_RETRIES", "7");
    env::set_var("NEOPILOT_CACHE__ENABLED", "false");
    
    // Load configuration with env overrides
    let config = ConfigLoader::new().load()?;
    
    // Verify the overridden values
    assert_eq!(config.tokenizer.model, "env-model");
    assert_eq!(config.network.max_retries, 7);
    assert!(!config.cache.enabled);
    
    // Clean up
    env::remove_var("NEOPILOT_TOKENIZER_MODEL");
    env::remove_var("NEOPILOT_NETWORK__MAX_RETRIES");
    env::remove_var("NEOPILOT_CACHE__ENABLED");
    
    Ok(())
}

#[test]
fn test_validation() -> anyhow::Result<()> {
    // Test with invalid configuration
    let mut config = Config::default();
    config.tokenizer.max_tokens = 0; // Invalid value
    
    let result = ConfigLoader::new()
        .with_override("tokenizer.max_tokens", "0")
        .load();
    
    assert!(result.is_err());
    
    Ok(())
}

#[test]
fn test_manual_overrides() -> anyhow::Result<()> {
    let config = ConfigLoader::new()
        .with_override("tokenizer.model", "manual-override")
        .with_override("network.max_retries", "9")
        .load()?;
    
    assert_eq!(config.tokenizer.model, "manual-override");
    assert_eq!(config.network.max_retries, 9);
    
    Ok(())
}

#[test]
fn test_find_config_file() -> anyhow::Result<()> {
    // Create a temporary directory for our test
    let dir = tempdir()?;
    let config_path = dir.path().join("neopilot.toml");
    fs::write(&config_path, "[tokenizer]\nmodel = \"test\"")?;
    
    // Change to the temporary directory
    let original_dir = env::current_dir()?;
    env::set_current_dir(&dir)?;
    
    // Test finding the config file
    let found_path = neopilot_repo_map::config::loader::ConfigLoader::find_config_file()?;
    assert!(found_path.is_some());
    assert_eq!(found_path.unwrap().canonicalize()?, config_path.canonicalize()?);
    
    // Change back to the original directory
    env::set_current_dir(original_dir)?;
    
    Ok(())
}
