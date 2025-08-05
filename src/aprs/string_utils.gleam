import gleam/list
import gleam/string

const valid_alphanumeric_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

fn char_is_in_set(char: String, valid_set: String) -> Bool {
  string.contains(valid_set, char)
}

/// Check if a string contains only uppercase A-Z and digits 0-9
pub fn is_alphanumeric(s: String) -> Bool {
  case string.is_empty(s) {
    True -> False
    False -> {
      string.to_graphemes(s)
      |> list.all(fn(char) { char_is_in_set(char, valid_alphanumeric_chars) })
    }
  }
}

const valid_digits = "0123456789"

pub fn is_digit(char: String) -> Bool {
  char_is_in_set(char, valid_digits)
}

pub fn is_all_digits(s: String) -> Bool {
  string.to_graphemes(s)
  |> list.all(is_digit)
}