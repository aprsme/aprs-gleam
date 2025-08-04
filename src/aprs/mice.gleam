import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import aprs/types.{
  type MiceLatitude,
  MiceInformation, MiceLatitude,
}

// MIC-E destination field characters for latitude encoding

// Decode MIC-E latitude digit
fn decode_mice_lat_digit(c: String) -> Result(#(Int, Bool), String) {
  case c {
    "0" -> Ok(#(0, False))  // South
    "1" -> Ok(#(1, False))
    "2" -> Ok(#(2, False))
    "3" -> Ok(#(3, False))
    "4" -> Ok(#(4, False))
    "5" -> Ok(#(5, False))
    "6" -> Ok(#(6, False))
    "7" -> Ok(#(7, False))
    "8" -> Ok(#(8, False))
    "9" -> Ok(#(9, False))
    "L" -> Ok(#(0, False))  // Space becomes L
    "P" -> Ok(#(0, True))   // North, Message Bit
    "Q" -> Ok(#(1, True))
    "R" -> Ok(#(2, True))
    "S" -> Ok(#(3, True))
    "T" -> Ok(#(4, True))
    "U" -> Ok(#(5, True))
    "V" -> Ok(#(6, True))
    "W" -> Ok(#(7, True))
    "X" -> Ok(#(8, True))
    "Y" -> Ok(#(9, True))
    "Z" -> Ok(#(0, True))   // Space becomes Z
    _ -> Error("Invalid MIC-E latitude character")
  }
}

// Decode MIC-E longitude offset
fn decode_mice_lon_offset(c: String) -> Int {
  case c {
    "P" | "Q" | "R" | "S" | "T" | "U" | "V" | "W" | "X" | "Y" | "Z" -> 0
    _ -> 100
  }
}

// Decode MIC-E longitude direction
fn decode_mice_lon_dir(c: String) -> String {
  case c {
    "P" | "Q" | "R" | "S" | "T" | "U" | "V" | "W" | "X" | "Y" | "Z" -> "W"
    _ -> "E"
  }
}

pub fn decode_mice_destination(dest: String) -> Result(MiceLatitude, String) {
  let chars = string.to_graphemes(dest)
  
  case list.length(chars) >= 6 {
    False -> Error("MIC-E destination too short")
    True -> {
      let lat_chars = list.take(chars, 6)
      
      // Decode each character
      let decoded = list.map(lat_chars, decode_mice_lat_digit)
      
      case list.all(decoded, result.is_ok) {
        False -> Error("Invalid MIC-E latitude encoding")
        True -> {
          let values = list.map(decoded, fn(r) {
            case r {
            Ok(v) -> v
            Error(_) -> #(0, False)  // Should not happen due to list.all check
          }
          })
          
          // Extract latitude digits and north/south
          case values {
            [#(d1, _), #(d2, _), #(d3, _), #(d4, n4), #(d5, _n5), #(d6, _n6)] -> {
              let lat_deg = d1 * 10 + d2
              let lat_min = d3 * 10 + d4
              let lat_min_frac = d5 * 10 + d6
              
              let latitude = int.to_float(lat_deg) +. { int.to_float(lat_min) +. int.to_float(lat_min_frac) /. 100.0 } /. 60.0
              
              // Determine N/S from 4th, 5th, 6th characters
              let north_south = case n4 {
                True -> "N"
                False -> "S"
              }
              
              // Longitude offset from 5th character
              let _lon_offset = case list.drop(lat_chars, 4) |> list.first() {
                Ok(c) -> decode_mice_lon_offset(c)
                Error(_) -> 0
              }
              
              // E/W from 6th character
              let east_west = case list.drop(lat_chars, 5) |> list.first() {
                Ok(c) -> decode_mice_lon_dir(c)
                Error(_) -> "E"
              }
              
              Ok(MiceLatitude(
                latitude: latitude,
                ambiguity: 0,
                north_south: north_south,
                east_west: east_west,
              ))
            }
            _ -> Error("Invalid MIC-E latitude format")
          }
        }
      }
    }
  }
}

pub fn decode_mice_data(body: String) -> Result(types.MiceInformation, String) {
  // MIC-E data format: 'llllllssiccccccc... where:
  // ' = back-tick (0x60)
  // llllll = longitude (6 bytes)
  // ss = speed and course
  // i = symbol table and info byte
  // ccccccc = comment text
  
  case string.length(body) < 9 {
    True -> Error("MIC-E data too short")
    False -> {
      case string.slice(body, 0, 1) == "`" {
        False -> Error("Invalid MIC-E data marker")
        True -> {
          // Extract the encoded bytes
          let _data_bytes = string.slice(body, 1, string.length(body) - 1)
          
          // For now, return a simple result
          // Full MIC-E decoding is complex and requires byte-level operations
          Ok(MiceInformation(
            longitude: 0.0,
            course: None,
            speed: None,
            symbol_table: "/",
            symbol_code: ">",
            altitude: None,
            comment: Some("MIC-E packet"),
          ))
        }
      }
    }
  }
}

