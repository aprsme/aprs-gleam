import gleam/option.{type Option, None, Some}
import gleam/string

/// Transforms an Option value through a function that returns a Result,
/// returning None if the original was None or if the transformation fails.
/// This is useful for chaining optional values through fallible operations.
pub fn option_try_map(
  opt opt: Option(a),
  with f: fn(a) -> Result(b, e),
) -> Option(b) {
  case opt {
    Some(value) ->
      case f(value) {
        Ok(result) -> Some(result)
        Error(_) -> None
      }
    None -> None
  }
}

/// Chains two optional operations, useful for nested Option handling
pub fn option_then(
  opt opt: Option(a),
  with f: fn(a) -> Option(b),
) -> Option(b) {
  case opt {
    Some(value) -> f(value)
    None -> None
  }
}

/// Converts a Result to an Option, discarding the error
pub fn result_to_option(res res: Result(a, e)) -> Option(a) {
  case res {
    Ok(value) -> Some(value)
    Error(_) -> None
  }
}

/// Attempts to parse a string slice, returning None on any failure
pub fn try_parse_slice(
  text text: String,
  from start: Int,
  length length: Int,
  parser parser: fn(String) -> Result(a, e),
) -> Option(a) {
  text
  |> string.slice(start, length)
  |> parser
  |> result_to_option
}

/// Parses an optional string value through a parser, transformer, and constructor
pub fn parse_with_transformation(
  opt opt: Option(String),
  parser parser: fn(String) -> Result(a, e),
  transformer transformer: fn(a) -> b,
  constructor constructor: fn(b) -> Result(c, e),
) -> Option(c) {
  opt
  |> option_then(fn(s) { parser(s) |> result_to_option })
  |> option.map(transformer)
  |> option_then(fn(v) { constructor(v) |> result_to_option })
}

/// Simplified version for when no transformation is needed
pub fn parse_and_construct(
  opt opt: Option(String),
  parser parser: fn(String) -> Result(a, e),
  constructor constructor: fn(a) -> Result(b, e),
) -> Option(b) {
  parse_with_transformation(opt, parser, fn(x) { x }, constructor)
}