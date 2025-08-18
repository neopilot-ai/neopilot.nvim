#![allow(clippy::unnecessary_map_or)]

// Re-export the Config type for easy access
pub mod config;
pub use config::{Config, ConfigLoader};

use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::BTreeMap;
use tree_sitter::{Node, Parser, Query, QueryCursor};
use tree_sitter_language::LanguageFn;

/// Represents a function or method definition.
#[derive(Debug, Clone)]
pub struct Func {
    pub name: String,
    pub params: String,
    pub return_type: String,
    pub accessibility_modifier: Option<String>,
}

/// Represents a class or module definition.
#[derive(Debug, Clone)]
pub struct Class {
    pub type_name: String,
    pub name: String,
    pub methods: Vec<Func>,
    pub properties: Vec<Variable>,
    pub visibility_modifier: Option<String>,
}

/// Represents an enum definition.
#[derive(Debug, Clone)]
pub struct Enum {
    pub name: String,
    pub items: Vec<Variable>,
}

/// Represents a union definition.
#[derive(Debug, Clone)]
pub struct Union {
    pub name: String,
    pub items: Vec<Variable>,
}

/// Represents a variable definition.
#[derive(Debug, Clone)]
pub struct Variable {
    pub name: String,
    pub value_type: String,
}

/// Represents a top-level code definition (function, class, module, etc.).
#[derive(Debug, Clone)]
pub enum Definition {
    Func(Func),
    Class(Class),
    Module(Class),
    Enum(Enum),
    Variable(Variable),
    Union(Union),
    // TODO: Namespace support
}

fn get_ts_language(language: &str) -> Option<LanguageFn> {
    match language {
        "rust" => Some(tree_sitter_rust::LANGUAGE),
        "python" => Some(tree_sitter_python::LANGUAGE),
        "php" => Some(tree_sitter_php::LANGUAGE_PHP),
        "java" => Some(tree_sitter_java::LANGUAGE),
        "javascript" => Some(tree_sitter_javascript::LANGUAGE),
        "typescript" => Some(tree_sitter_typescript::LANGUAGE_TSX),
        "go" => Some(tree_sitter_go::LANGUAGE),
        "c" => Some(tree_sitter_c::LANGUAGE),
        "cpp" => Some(tree_sitter_cpp::LANGUAGE),
        "lua" => Some(tree_sitter_lua::LANGUAGE),
        "ruby" => Some(tree_sitter_ruby::LANGUAGE),
        "zig" => Some(tree_sitter_zig::LANGUAGE),
        "scala" => Some(tree_sitter_scala::LANGUAGE),
        "swift" => Some(tree_sitter_swift::LANGUAGE),
        "elixir" => Some(tree_sitter_elixir::LANGUAGE),
        "csharp" => Some(tree_sitter_c_sharp::LANGUAGE),
        _ => None,
    }
}

const C_QUERY: &str = include_str!("../queries/tree-sitter-c-defs.scm");
const CPP_QUERY: &str = include_str!("../queries/tree-sitter-cpp-defs.scm");
const GO_QUERY: &str = include_str!("../queries/tree-sitter-go-defs.scm");
const JAVA_QUERY: &str = include_str!("../queries/tree-sitter-java-defs.scm");
const JAVASCRIPT_QUERY: &str = include_str!("../queries/tree-sitter-javascript-defs.scm");
const LUA_QUERY: &str = include_str!("../queries/tree-sitter-lua-defs.scm");
const PYTHON_QUERY: &str = include_str!("../queries/tree-sitter-python-defs.scm");
const PHP_QUERY: &str = include_str!("../queries/tree-sitter-php-defs.scm");
const RUST_QUERY: &str = include_str!("../queries/tree-sitter-rust-defs.scm");
const ZIG_QUERY: &str = include_str!("../queries/tree-sitter-zig-defs.scm");
const TYPESCRIPT_QUERY: &str = include_str!("../queries/tree-sitter-typescript-defs.scm");
const RUBY_QUERY: &str = include_str!("../queries/tree-sitter-ruby-defs.scm");
const SCALA_QUERY: &str = include_str!("../queries/tree-sitter-scala-defs.scm");
const SWIFT_QUERY: &str = include_str!("../queries/tree-sitter-swift-defs.scm");
const ELIXIR_QUERY: &str = include_str!("../queries/tree-sitter-elixir-defs.scm");
const CSHARP_QUERY: &str = include_str!("../queries/tree-sitter-c-sharp-defs.scm");

fn get_definitions_query(language: &str) -> Result<Query, String> {
    let ts_language =
        get_ts_language(language).ok_or_else(|| format!("Unsupported language: {language}"))?;
    let contents = match language {
        "c" => C_QUERY,
        "cpp" => CPP_QUERY,
        "go" => GO_QUERY,
        "java" => JAVA_QUERY,
        "javascript" => JAVASCRIPT_QUERY,
        "lua" => LUA_QUERY,
        "php" => PHP_QUERY,
        "python" => PYTHON_QUERY,
        "rust" => RUST_QUERY,
        "zig" => ZIG_QUERY,
        "typescript" => TYPESCRIPT_QUERY,
        "ruby" => RUBY_QUERY,
        "scala" => SCALA_QUERY,
        "swift" => SWIFT_QUERY,
        "elixir" => ELIXIR_QUERY,
        "csharp" => CSHARP_QUERY,
        _ => return Err(format!("Unsupported language: {language}")),
    };
    Query::new(&ts_language.into(), contents)
        .map_err(|e| format!("Failed to parse query for {language}: {e}"))
}

#[allow(dead_code)]
fn get_closest_ancestor_name(node: &Node, source: &str) -> String {
    let mut parent = node.parent();
    while let Some(parent_node) = parent {
        let name_node = parent_node.child_by_field_name("name");
        if let Some(name_node) = name_node {
            return get_node_text(&name_node, source.as_bytes()).to_string();
        }
        parent = parent_node.parent();
    }
    String::new()
}

#[allow(dead_code)]
fn find_ancestor_by_type<'a>(node: &'a Node, parent_type: &str) -> Option<Node<'a>> {
    let mut parent = node.parent();
    while let Some(parent_node) = parent {
        if parent_node.kind() == parent_type {
            return Some(parent_node);
        }
        parent = parent_node.parent();
    }
    None
}

#[allow(dead_code)]
fn find_first_ancestor_by_types<'a>(
    node: &'a Node,
    possible_parent_types: &[&str],
) -> Option<Node<'a>> {
    let mut parent = node.parent();
    while let Some(parent_node) = parent {
        if possible_parent_types.contains(&parent_node.kind()) {
            return Some(parent_node);
        }
        parent = parent_node.parent();
    }
    None
}

fn find_descendant_by_type<'a>(node: &'a Node, child_type: &str) -> Option<Node<'a>> {
    let mut cursor = node.walk();
    for i in 0..node.descendant_count() {
        cursor.goto_descendant(i);
        let node = cursor.node();
        if node.kind() == child_type {
            return Some(node);
        }
    }
    None
}

#[allow(dead_code)]
fn ruby_method_is_private<'a>(node: &'a Node, source: &'a [u8]) -> bool {
    let mut prev_sibling = node.prev_sibling();
    while let Some(prev_sibling_node) = prev_sibling {
        if prev_sibling_node.kind() == "identifier" {
            let text = prev_sibling_node.utf8_text(source).unwrap_or_default();
            if text == "private" {
                return true;
            } else if text == "public" || text == "protected" {
                return false;
            }
        } else if prev_sibling_node.kind() == "class" || prev_sibling_node.kind() == "module" {
            return false;
        }
        prev_sibling = prev_sibling_node.prev_sibling();
    }
    false
}

fn find_child_by_type<'a>(node: &'a Node, child_type: &str) -> Option<Node<'a>> {
    node.children(&mut node.walk())
        .find(|child| child.kind() == child_type)
}

// Zig-specific function to find the parent variable declaration
#[allow(dead_code)]
fn zig_find_parent_variable_declaration_name<'a>(
    node: &'a Node,
    source: &'a [u8],
) -> Option<String> {
    let vardec = find_ancestor_by_type(node, "variable_declaration");
    if let Some(vardec) = vardec {
        // Find the identifier child node, which represents the class name
        let identifier_node = find_child_by_type(&vardec, "identifier");
        if let Some(identifier_node) = identifier_node {
            return Some(get_node_text(&identifier_node, source));
        }
    }
    None
}

#[allow(dead_code)]
fn zig_is_declaration_public<'a>(node: &'a Node, declaration_type: &str, source: &'a [u8]) -> bool {
    let declaration = find_ancestor_by_type(node, declaration_type);
    if let Some(declaration) = declaration {
        let declaration_text = get_node_text(&declaration, source);
        return declaration_text.starts_with("pub");
    }
    false
}

#[allow(dead_code)]
fn zig_is_variable_declaration_public<'a>(node: &'a Node, source: &'a [u8]) -> bool {
    zig_is_declaration_public(node, "variable_declaration", source)
}

#[allow(dead_code)]
fn zig_is_function_declaration_public<'a>(node: &'a Node, source: &'a [u8]) -> bool {
    zig_is_declaration_public(node, "function_declaration", source)
}

#[allow(dead_code)]
fn zig_find_type_in_parent<'a>(node: &'a Node, source: &'a [u8]) -> Option<String> {
    // First go to the parent and then get the child_by_field_name "type"
    if let Some(parent) = node.parent() {
        if let Some(type_node) = parent.child_by_field_name("type") {
            return Some(get_node_text(&type_node, source));
        }
    }
    None
}

fn csharp_is_primary_constructor(node: &Node) -> bool {
    node.kind() == "parameter_list"
        && node.parent().map_or(false, |n| {
            n.kind() == "class_declaration" || n.kind() == "record_declaration"
        })
}

#[allow(dead_code)]
fn csharp_find_parent_type_node<'a>(node: &'a Node) -> Option<Node<'a>> {
    find_first_ancestor_by_types(node, &["class_declaration", "record_declaration"])
}

#[allow(dead_code)]
fn ex_find_parent_module_declaration_name<'a>(node: &'a Node, source: &'a [u8]) -> Option<String> {
    let mut parent = node.parent();
    while let Some(parent_node) = parent {
        if parent_node.kind() == "call" {
            let text = get_node_text(&parent_node, source);
            if text.starts_with("defmodule ") {
                let arguments_node = find_child_by_type(&parent_node, "arguments");
                if let Some(arguments_node) = arguments_node {
                    return Some(get_node_text(&arguments_node, source));
                }
            }
        }
        parent = parent_node.parent();
    }
    None
}

fn ruby_find_parent_module_declaration_name<'a>(
    node: &'a Node,
    source: &'a [u8],
) -> Option<String> {
    let mut path_parts = Vec::new();
    let mut current = Some(*node);

    while let Some(current_node) = current {
        if current_node.kind() == "module" || current_node.kind() == "class" {
            if let Some(name_node) = current_node.child_by_field_name("name") {
                path_parts.push(get_node_text(&name_node, source));
            }
        }
        current = current_node.parent();
    }

    if path_parts.is_empty() {
        None
    } else {
        path_parts.reverse();
        Some(path_parts.join("::"))
    }
}

fn get_node_text<'a>(node: &'a Node, source: &'a [u8]) -> String {
    node.utf8_text(source).unwrap_or_default().to_string()
}

#[allow(dead_code)]
fn get_node_type<'a>(node: &'a Node, source: &'a [u8]) -> String {
    let predefined_type_node = find_descendant_by_type(node, "predefined_type");
    if let Some(type_node) = predefined_type_node {
        return type_node.utf8_text(source).unwrap().to_string();
    }
    let value_type_node = node.child_by_field_name("type");
    value_type_node
        .map(|n| n.utf8_text(source).unwrap().to_string())
        .unwrap_or_default()
}

fn is_first_letter_uppercase(name: &str) -> bool {
    if name.is_empty() {
        return false;
    }
    name.chars().next().unwrap().is_uppercase()
}

// Given a language, parse the given source code and return exported definitions.
fn extract_definitions(language: &str, source: &str) -> Result<Vec<Definition>, String> {
    let ts_language = get_ts_language(language);
    if ts_language.is_none() {
        return Ok(vec![]);
    }
    let ts_language = ts_language.unwrap();

    let mut parser = Parser::new();
    parser
        .set_language(&ts_language.into())
        .unwrap_or_else(|_| panic!("Failed to set language for {language}"));
    let tree = parser
        .parse(source, None)
        .unwrap_or_else(|| panic!("Failed to parse source code for {language}"));
    let root_node = tree.root_node();

    let query = get_definitions_query(language)?;
    let mut query_cursor = QueryCursor::new();
    let captures = query_cursor.captures(&query, root_node, source.as_bytes());
    let mut definitions = Vec::new();
    let mut class_def_map: BTreeMap<String, RefCell<Class>> = BTreeMap::new();
    let enum_def_map: BTreeMap<String, RefCell<Enum>> = BTreeMap::new();
    let union_def_map: BTreeMap<String, RefCell<Union>> = BTreeMap::new();

    let ensure_class_def =
        |language: &str, name: &str, class_def_map: &mut BTreeMap<String, RefCell<Class>>| {
            let mut type_name = "class";
            if language == "elixir" {
                type_name = "module";
            }
            class_def_map.entry(name.to_string()).or_insert_with(|| {
                RefCell::new(Class {
                    type_name: type_name.to_string(),
                    name: name.to_string(),
                    methods: vec![],
                    properties: vec![],
                    visibility_modifier: None,
                })
            });
        };

    let ensure_module_def = |name: &str, class_def_map: &mut BTreeMap<String, RefCell<Class>>| {
        class_def_map.entry(name.to_string()).or_insert_with(|| {
            RefCell::new(Class {
                name: name.to_string(),
                type_name: "module".to_string(),
                methods: vec![],
                properties: vec![],
                visibility_modifier: None,
            })
        });
    };

    // Sometimes, multiple queries capture the same node with the same capture name.
    // We need to ensure that we only add the node to the definition map once.
    let mut captured_nodes: BTreeMap<String, Vec<usize>> = BTreeMap::new();

    for (m, _) in captures {
        for capture in m.captures {
            let capture_name = &query.capture_names()[capture.index as usize];
            let node = capture.node;
            let node_text = node.utf8_text(source.as_bytes()).unwrap();

            let node_id = node.id();
            if captured_nodes
                .get(*capture_name)
                .map_or(false, |v| v.contains(&node_id))
            {
                continue;
            }
            captured_nodes
                .entry(String::from(*capture_name))
                .or_default()
                .push(node_id);

            let name = match language {
                "cpp" => {
                    if *capture_name == "class" {
                        node.child_by_field_name("name")
                            .map(|n| n.utf8_text(source.as_bytes()).unwrap())
                            .unwrap_or(node_text)
                            .to_string()
                    } else {
                        let ident = find_descendant_by_type(&node, "field_identifier")
                            .or_else(|| find_descendant_by_type(&node, "operator_name"))
                            .or_else(|| find_descendant_by_type(&node, "identifier"))
                            .map(|n| n.utf8_text(source.as_bytes()).unwrap());
                        if let Some(ident) = ident {
                            let scope = node
                                .child_by_field_name("declarator")
                                .and_then(|n| n.child_by_field_name("declarator"))
                                .and_then(|n| n.child_by_field_name("scope"));
                            if let Some(scope_node) = scope {
                                format!(
                                    "{}::{}",
                                    scope_node.utf8_text(source.as_bytes()).unwrap(),
                                    ident
                                )
                            } else {
                                ident.to_string()
                            }
                        } else {
                            node_text.to_string()
                        }
                    }
                }
                "scala" => node
                    .child_by_field_name("name")
                    .or_else(|| node.child_by_field_name("pattern"))
                    .map(|n| n.utf8_text(source.as_bytes()).unwrap())
                    .unwrap_or(node_text)
                    .to_string(),
                "csharp" => {
                    let mut identifier = node;
                    // Handle primary constructors (they are direct children of *_declaration)
                    if *capture_name == "method" && csharp_is_primary_constructor(&node) {
                        identifier = node.parent().unwrap_or(node);
                    } else if *capture_name == "class_variable" {
                        identifier =
                            find_descendant_by_type(&node, "variable_declarator").unwrap_or(node);
                    }

                    identifier
                        .child_by_field_name("name")
                        .map(|n| n.utf8_text(source.as_bytes()).unwrap())
                        .unwrap_or(node_text)
                        .to_string()
                }
                "ruby" => {
                    let name = node
                        .child_by_field_name("name")
                        .map(|n| n.utf8_text(source.as_bytes()).unwrap())
                        .unwrap_or(node_text)
                        .to_string();
                    if *capture_name == "class" || *capture_name == "module" {
                        ruby_find_parent_module_declaration_name(&node, source.as_bytes())
                            .unwrap_or(name)
                    } else {
                        name
                    }
                }
                _ => node
                    .child_by_field_name("name")
                    .map(|n| n.utf8_text(source.as_bytes()).unwrap())
                    .unwrap_or(node_text)
                    .to_string(),
            };

            match *capture_name {
                "class" => {
                    if !name.is_empty() {
                        if language == "go" && !is_first_letter_uppercase(&name) {
                            continue;
                        }
                        ensure_class_def(language, &name, &mut class_def_map);
                        let visibility_modifier_node =
                            find_child_by_type(&node, "visibility_modifier");
                        let visibility_modifier = visibility_modifier_node
                            .map(|n| n.utf8_text(source.as_bytes()).unwrap())
                            .unwrap_or("");
                        let class_def = class_def_map.get_mut(&name).unwrap();
                        class_def.borrow_mut().visibility_modifier =
                            if visibility_modifier.is_empty() {
                                None
                            } else {
                                Some(visibility_modifier.to_string())
                            };
                    }
                }
                "module" => {
                    if !name.is_empty() {
                        ensure_module_def(&name, &mut class_def_map);
                    }
                }
                _ => {
                    // Handle other capture types (functions, variables, etc.) as needed
                    // This is a simplified version - you'd need to add more cases here
                }
            }
        }
    }

    for (_, def) in class_def_map {
        let class_def = def.into_inner();
        if language == "rust" {
            if let Some(visibility_modifier) = &class_def.visibility_modifier {
                if visibility_modifier.contains("pub") {
                    definitions.push(Definition::Class(class_def));
                }
            }
        } else {
            definitions.push(Definition::Class(class_def));
        }
    }

    for (_, def) in enum_def_map {
        definitions.push(Definition::Enum(def.into_inner()));
    }
    for (_, def) in union_def_map {
        definitions.push(Definition::Union(def.into_inner()));
    }

    Ok(definitions)
}

fn stringify_function(func: &Func) -> String {
    let mut res = format!("func {}", func.name);
    if func.params.is_empty() {
        res = format!("{res}()");
    } else {
        res = format!("{res}{}", func.params);
    }
    if !func.return_type.is_empty() {
        res = format!("{res} -> {}", func.return_type);
    }
    if let Some(modifier) = &func.accessibility_modifier {
        res = format!("{modifier} {res}");
    }
    format!("{res};")
}

fn stringify_variable(variable: &Variable) -> String {
    let mut res = format!("var {}", variable.name);
    if !variable.value_type.is_empty() {
        res = format!("{res}:{}", variable.value_type);
    }
    format!("{res};")
}

fn stringify_enum_item(item: &Variable) -> String {
    let mut res = item.name.clone();
    if !item.value_type.is_empty() {
        res = format!("{res}:{}", item.value_type);
    }
    format!("{res};")
}

fn stringify_union_item(item: &Variable) -> String {
    let mut res = item.name.clone();
    if !item.value_type.is_empty() {
        res = format!("{res}:{}", item.value_type);
    }
    format!("{res};")
}

fn stringify_class(class: &Class) -> String {
    let mut res = format!("{} {}{{", class.type_name, class.name);
    for method in &class.methods {
        let method_str = stringify_function(method);
        res = format!("{res}{method_str}");
    }
    for property in &class.properties {
        let property_str = stringify_variable(property);
        res = format!("{res}{property_str}");
    }
    format!("{res}}};")
}

fn stringify_enum(enum_def: &Enum) -> String {
    let mut res = format!("enum {}{{", enum_def.name);
    for item in &enum_def.items {
        let item_str = stringify_enum_item(item);
        res = format!("{res}{item_str}");
    }
    format!("{res}}};")
}

fn stringify_union(union_def: &Union) -> String {
    let mut res = format!("union {}{{", union_def.name);
    for item in &union_def.items {
        let item_str = stringify_union_item(item);
        res = format!("{res}{item_str}");
    }
    format!("{res}}};")
}

fn stringify_definitions(definitions: &Vec<Definition>) -> String {
    let mut res = String::new();
    for definition in definitions {
        match definition {
            Definition::Class(class) => res = format!("{res}{}", stringify_class(class)),
            Definition::Module(module) => res = format!("{res}{}", stringify_class(module)),
            Definition::Enum(enum_def) => res = format!("{res}{}", stringify_enum(enum_def)),
            Definition::Union(union_def) => res = format!("{res}{}", stringify_union(union_def)),
            Definition::Func(func) => res = format!("{res}{}", stringify_function(func)),
            Definition::Variable(variable) => {
                let variable_str = stringify_variable(variable);
                res = format!("{res}{variable_str}");
            }
        }
    }
    res
}

pub fn get_definitions_string(language: &str, source: &str) -> LuaResult<String> {
    let definitions =
        extract_definitions(language, source).map_err(|e| LuaError::RuntimeError(e.to_string()))?;
    let stringified = stringify_definitions(&definitions);
    Ok(stringified)
}

#[mlua::lua_module]
fn neopilot_repo_map(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    exports.set(
        "stringify_definitions",
        lua.create_function(move |_, (language, source): (String, String)| {
            get_definitions_string(language.as_str(), source.as_str())
        })?,
    )?;
    Ok(exports)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rust() {
        let source = r#"
        // This is a test comment
        pub const TEST_CONST: u32 = 1;
        pub static TEST_STATIC: u32 = 2;
        const INNER_TEST_CONST: u32 = 3;
        static INNER_TEST_STATIC: u32 = 4;
        pub(crate) struct TestStruct {
            pub test_field: String,
            inner_test_field: String,
        }
        impl TestStruct {
            pub fn test_method(&self, a: u32, b: u32) -> u32 {
                a + b
            }
            fn inner_test_method(&self, a: u32, b: u32) -> u32 {
                a + b
            }
        }
        struct InnerTestStruct {
            pub test_field: String,
            inner_test_field: String,
        }
        impl InnerTestStruct {
            pub fn test_method(&self, a: u32, b: u32) -> u32 {
                a + b
            }
            fn inner_test_method(&self, a: u32, b: u32) -> u32 {
                a + b
            }
        }
        pub enum TestEnum {
            TestEnumField1,
            TestEnumField2,
        }
        enum InnerTestEnum {
            InnerTestEnumField1,
            InnerTestEnumField2,
        }
        pub fn test_fn(a: u32, b: u32) -> u32 {
            let inner_var_in_func = 1;
            struct InnerStructInFunc {
                c: u32,
            }
            a + b + inner_var_in_func
        }
        fn inner_test_fn(a: u32, b: u32) -> u32 {
            a + b
        }
        "#;
        let definitions = extract_definitions("rust", source).unwrap();
        let stringified = stringify_definitions(&definitions);
        println!("{stringified}");
        // Basic test - just ensure it doesn't panic
        assert!(!stringified.is_empty());
    }

    #[test]
    fn test_unsupported_language() {
        let source = "print(\"Hello, world!\")";
        let definitions = extract_definitions("unknown", source).unwrap();

        let stringified = stringify_definitions(&definitions);
        println!("{stringified}");
        let expected = "";
        assert_eq!(stringified, expected);
    }
}
