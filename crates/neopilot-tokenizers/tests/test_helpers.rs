// tests/test_helpers.rs
use neopilot_tokenizers::{State, from_pretrained, encode};
use std::sync::Arc;

pub fn setup_test_environment() -> Arc<State> {
    let state = Arc::new(State::new());
    from_pretrained(&state, "gpt-4o").expect("Failed to initialize test tokenizer");
    state
}

pub fn assert_tokenizer_behavior<F>(test_fn: F) 
where
    F: FnOnce(Arc<State>) -> (),
{
    let state = setup_test_environment();
    test_fn(state);
}

#[macro_export]
macro_rules! test_with_models {
    ($($model:expr),+ => $test:expr) => {
        $(
            paste::item! {
                #[test]
                fn [<test_ $model>]() {
                    let state = Arc::new(State::new());
                    from_pretrained(&state, $model).expect(&format!("Failed to load model: {}", $model));
                    $test(state);
                }
            }
        )+
    };
}