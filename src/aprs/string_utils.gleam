import gleam/list
import gleam/string

/// Check if a string contains only uppercase A-Z and digits 0-9
pub fn is_alphanumeric(s: String) -> Bool {
  case string.is_empty(s) {
    True -> False
    False -> {
      string.to_graphemes(s)
      |> list.all(fn(char) {
        case char {
          "A" | "B" | "C" | "D" | "E" | "F" | "G" | "H" | "I" | "J" | "K" 
          | "L" | "M" | "N" | "O" | "P" | "Q" | "R" | "S" | "T" | "U" 
          | "V" | "W" | "X" | "Y" | "Z" | "0" | "1" | "2" | "3" | "4" 
          | "5" | "6" | "7" | "8" | "9" -> True
          _ -> False
        }
      })
    }
  }
}

pub fn is_digit(char: String) -> Bool {
  case char {
    "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> True
    _ -> False
  }
}

pub fn is_all_digits(s: String) -> Bool {
  string.to_graphemes(s)
  |> list.all(is_digit)
}