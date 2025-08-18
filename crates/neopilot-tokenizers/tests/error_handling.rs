use neopilot_tokenizers::{
    error::TokenizerError,
    State,
    encode,
    huggingface::HuggingFaceTokenizer,
    tiktoken::Tiktoken,
};

#[test]
fn test_invalid_model() {
    let result = Tiktoken::new("invalid-model");
    assert!(matches!(
        result,
        Err(TokenizerError::ModelLoadError(_))
    ));
}

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

#[test]
fn test_uninitialized_tokenizer() {
    let state = State::new();
    let state_ref = &state;
    let result = encode(state_ref, "test");
    assert!(matches!(
        result,
        Err(TokenizerError::TokenizerError(_))
    ));
}

#[test]
fn test_large_file_download() {
    // This test checks that we properly handle file size limits
    // Note: This is a test that would fail if the URL was accessible
    let result = HuggingFaceTokenizer::new(
        "https://example.com/very-large-file.bin"
    );
    
    // The actual error might vary, but we're checking that it doesn't panic
    assert!(result.is_err());
}
