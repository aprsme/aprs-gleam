import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam/dict
import aprs/types.{
  type MiceLatitude,
  MiceInformation, MiceLatitude,
}

// MIC-E destination field characters for latitude encoding
fn get_mice_lat_digit_map() {
  dict.from_list([
    // South digits
    #("0", #(0, False)), #("1", #(1, False)), #("2", #(2, False)),
    #("3", #(3, False)), #("4", #(4, False)), #("5", #(5, False)),
    #("6", #(6, False)), #("7", #(7, False)), #("8", #(8, False)),
    #("9", #(9, False)), #("L", #(0, False)),  // Space becomes L
    // North digits with message bit
    #("P", #(0, True)), #("Q", #(1, True)), #("R", #(2, True)),
    #("S", #(3, True)), #("T", #(4, True)), #("U", #(5, True)),
    #("V", #(6, True)), #("W", #(7, True)), #("X", #(8, True)),
    #("Y", #(9, True)), #("Z", #(0, True)),   // Space becomes Z
  ])
}

// Characters that indicate longitude offset 0 and west direction
const mice_special_chars = "PQRSTUVWXYZ"

// Decode MIC-E latitude digit
fn decode_mice_lat_digit(c: String) -> Result(#(Int, Bool), String) {
  dict.get(get_mice_lat_digit_map(), c)
  |> result.replace_error("Invalid MIC-E latitude character")
}

// Decode MIC-E longitude offset
fn decode_mice_lon_offset(c: String) -> Int {
  case string.contains(mice_special_chars, c) {
    True -> 0
    False -> 100
  }
}

// Decode MIC-E longitude direction
fn decode_mice_lon_dir(c: String) -> String {
  case string.contains(mice_special_chars, c) {
    True -> "W"
    False -> "E"
  }
}

fn extract_latitude_components(values: List(#(Int, Bool))) -> #(Int, Int, Int, Bool) {
  let assert [#(d1, _), #(d2, _), #(d3, _), #(d4, n4), #(d5, _), #(d6, _)] = values
  #(d1 * 10 + d2, d3 * 10 + d4, d5 * 10 + d6, n4)
}

fn calculate_latitude(deg: Int, min: Int, min_frac: Int) -> Float {
  int.to_float(deg) +. { int.to_float(min) +. int.to_float(min_frac) /. 100.0 } /. 60.0
}

fn extract_longitude_info(lat_chars: List(String)) -> #(Int, String) {
  let lon_offset = 
    list.drop(lat_chars, 4)
    |> list.first()
    |> result.map(decode_mice_lon_offset)
    |> result.unwrap(0)
  
  let east_west = 
    list.drop(lat_chars, 5)
    |> list.first()
    |> result.map(decode_mice_lon_dir)
    |> result.unwrap("E")
  
  #(lon_offset, east_west)
}

pub fn decode_mice_destination(dest: String) -> Result(MiceLatitude, String) {
  let chars = string.to_graphemes(dest)
  
  use lat_chars <- result.try(
    case list.length(chars) >= 6 {
      True -> Ok(list.take(chars, 6))
      False -> Error("MIC-E destination too short")
    }
  )
  
  use values <- result.try(
    list.try_map(lat_chars, decode_mice_lat_digit)
    |> result.map_error(fn(_) { "Invalid MIC-E latitude encoding" })
  )
  
  let #(lat_deg, lat_min, lat_min_frac, n4) = extract_latitude_components(values)
  
  let latitude = calculate_latitude(lat_deg, lat_min, lat_min_frac)
  let north_south = case n4 { True -> "N" False -> "S" }
  let #(_lon_offset, east_west) = extract_longitude_info(lat_chars)
  
  Ok(MiceLatitude(
    latitude: latitude,
    ambiguity: 0,
    north_south: north_south,
    east_west: east_west,
  ))
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

