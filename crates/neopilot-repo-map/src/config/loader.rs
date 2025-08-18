//! Configuration loading and merging functionality

use std::path::{Path, PathBuf};
use std::env;
use std::collections::HashMap;

use crate::config::{Config, ConfigError};

/// Loads and merges configuration from multiple sources
pub struct ConfigLoader {
    config_path: Option<PathBuf>,
    env_prefix: String,
    overrides: HashMap<String, String>,
}

impl Default for ConfigLoader {
    fn default() -> Self {
        Self::new()
    }
}

impl ConfigLoader {
    /// Create a new ConfigLoader with default settings
    pub fn new() -> Self {
        Self {
            config_path: None,
            env_prefix: "NEOPILOT_".to_string(),
            overrides: HashMap::new(),
        }
    }
    
    /// Set a custom path to the configuration file
    pub fn with_config_path<P: AsRef<Path>>(mut self, path: P) -> Self {
        self.config_path = Some(path.as_ref().to_path_buf());
        self
    }
    
    /// Set a custom environment variable prefix
    pub fn with_env_prefix<S: Into<String>>(mut self, prefix: S) -> Self {
        self.env_prefix = prefix.into();
        self
    }
    
    /// Add a manual configuration override
    pub fn with_override<K: Into<String>, V: Into<String>>(mut self, key: K, value: V) -> Self {
        self.overrides.insert(key.into(), value.into());
        self
    }
    
    /// Load and merge configurations from all sources
    pub fn load(self) -> Result<Config, ConfigError> {
        let mut config = Config::default();
        
        // Load from file if specified or find default config file
        if let Some(path) = self.get_config_path()? {
            config.merge_from_file(&path)?;
        }
        
        // Apply environment variable overrides
        self.apply_env_overrides(&mut config)?;
        
        // Apply manual overrides
        self.apply_manual_overrides(&mut config)?;
        
        // Validate the final configuration
        crate::config::validation::validate_config(&config)?;
        
        Ok(config)
    }
    
    /// Get the configuration file path, either from the specified path or by searching default locations
    fn get_config_path(&self) -> Result<Option<PathBuf>, ConfigError> {
        if let Some(ref path) = self.config_path {
            if path.exists() {
                return Ok(Some(path.clone()));
            }
            return Err(ConfigError::IoError(
                std::io::Error::new(
                    std::io::ErrorKind::NotFound,
                    format!("Configuration file not found: {}", path.display())
                ),
                path.clone(),
            ));
        }
        
        Self::find_config_file()
    }
    
    /// Find the configuration file in default locations
    pub fn find_config_file() -> Result<Option<PathBuf>, ConfigError> {
        let possible_paths = [
            // Current directory
            std::env::current_dir()?.join("neopilot.toml"),
            // XDG config directory
            dirs::config_dir()
                .ok_or(ConfigError::NoConfigDir)?
                .join("neopilot")
                .join("config.toml"),
            // Home directory
            dirs::home_dir()
                .ok_or(ConfigError::NoConfigDir)?
                .join(".config")
                .join("neopilot.toml"),
            // System-wide configuration
            PathBuf::from("/etc/neopilot/config.toml"),
        ];
        
        for path in &possible_paths {
            if path.exists() {
                return Ok(Some(path.clone()));
            }
        }
        
        Ok(None)
    }
    
    /// Apply environment variable overrides to the configuration
    fn apply_env_overrides(&self, config: &mut Config) -> Result<(), ConfigError> {
        for (key, value) in env::vars() {
            if let Some(rest) = key.strip_prefix(&self.env_prefix) {
                // Convert NEOPILOT_TOKENIZER_MODEL to tokenizer.model
                let path = rest
                    .to_lowercase()
                    .replace("__", ".");
                config.set_from_str(&path, &value)?;
            }
        }
        
        Ok(())
    }
    
    /// Apply manual configuration overrides
    fn apply_manual_overrides(&self, config: &mut Config) -> Result<(), ConfigError> {
        for (key, value) in &self.overrides {
            config.set_from_str(key, value)?;
        }
        
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs::File;
    use std::io::Write;
    use tempfile::tempdir;
    
    #[test]
    fn test_find_config_file() -> Result<(), Box<dyn std::error::Error>> {
        let dir = tempdir()?;
        let config_path = dir.path().join("neopilot.toml");
        let mut file = File::create(&config_path)?;
        writeln!(file, "[tokenizer]\nmodel = \"test-model\"")?;
        
        env::set_current_dir(dir.path())?;
        
        let found_path = ConfigLoader::find_config_file()?;
        assert!(found_path.is_some());
        assert_eq!(found_path.unwrap(), config_path);
        
        Ok(())
    }
    
    #[test]
    fn test_load_with_overrides() -> Result<(), Box<dyn std::error::Error>> {
        let loader = ConfigLoader::new()
            .with_override("tokenizer.model", "overridden-model")
            .with_override("network.max_retries", "10");
            
        let config = loader.load()?;
        
        assert_eq!(config.tokenizer.model, "overridden-model");
        assert_eq!(config.network.max_retries, 10);
        
        Ok(())
    }
    
    #[test]
    fn test_env_overrides() -> Result<(), Box<dyn std::error::Error>> {
        env::set_var("NEOPILOT_TOKENIZER_MODEL", "env-model");
        env::set_var("NEOPILOT_NETWORK__MAX_RETRIES", "5");
        
        let loader = ConfigLoader::new();
        let config = loader.load()?;
        
        assert_eq!(config.tokenizer.model, "env-model");
        assert_eq!(config.network.max_retries, 5);
        
        env::remove_var("NEOPILOT_TOKENIZER_MODEL");
        env::remove_var("NEOPILOT_NETWORK__MAX_RETRIES");
        
        Ok(())
    }
}
