import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/dict
import aprs/string_utils
import aprs/types.{
  type Altitude, type BodyParseResult, type Course, type ParseError,
  type PhgValue, type PositionInfo, type Range, type Speed,
  type StrictPhgData,
  InvalidPosition, PositionInfo, PositionPacket,
  StrictPhgData, StrictPosition, make_altitude, make_course, make_latitude,
  make_longitude, make_phg_value, make_range, make_speed, make_symbol_code,
  make_symbol_table,
}
import aprs/result_utils.{
  empty_body_result, set_altitude, set_comment, set_course, set_packet_type,
  set_phg, set_position, set_rng, set_speed, set_symbol_code, set_symbol_table,
}

pub fn parse_position_packet(
  body: String,
) -> Result(BodyParseResult, ParseError) {
  case string.length(body) < 2 {
    True -> Error(InvalidPosition)
    False -> {
      let _data_type = string.slice(body, 0, 1)
      let rest = string.slice(body, 1, string.length(body) - 1)
      
      // Try to parse as uncompressed first, then compressed if that fails
      case parse_uncompressed_position_packet(rest) {
        Ok(result) -> Ok(result)
        Error(_) -> parse_compressed_position_packet(rest)
      }
    }
  }
}

fn parse_compressed_position_packet(
  data: String,
) -> Result(BodyParseResult, ParseError) {
  case string.length(data) >= 13 {
    False -> Error(InvalidPosition)
    True -> {
      let symbol_table = string.slice(data, 0, 1)
      let lat_chars = string.slice(data, 1, 4)
      let lon_chars = string.slice(data, 5, 4)
      let symbol_code = string.slice(data, 9, 1)
      let cs_chars = string.slice(data, 10, 2)
      let t_char = string.slice(data, 12, 1)
      let remaining = string.slice(data, 13, string.length(data) - 13)
      
      use lat <- result.try(decode_compressed_latitude(lat_chars))
      use lon <- result.try(decode_compressed_longitude(lon_chars))
      use #(course, speed, altitude) <- result.try(decode_compressed_cs_t(cs_chars, t_char))
      
      use latitude <- result.try(
        make_latitude(lat)
        |> result.map_error(fn(_) { InvalidPosition }),
      )
      use longitude <- result.try(
        make_longitude(lon)
        |> result.map_error(fn(_) { InvalidPosition }),
      )
      use symbol_table_val <- result.try(
        make_symbol_table(symbol_table)
        |> result.map_error(fn(_) { InvalidPosition }),
      )
      use symbol_code_val <- result.try(
        make_symbol_code(symbol_code)
        |> result.map_error(fn(_) { InvalidPosition }),
      )
      
      let position = StrictPosition(
        latitude: latitude,
        longitude: longitude,
        ambiguity: 0,
        altitude: altitude,
      )
      
      let comment = case string.is_empty(remaining) {
        True -> None
        False -> Some(string.trim(remaining))
      }
      
      Ok(
        empty_body_result()
        |> set_packet_type(PositionPacket)
        |> set_position(Some(position))
        |> set_symbol_table(Some(symbol_table_val))
        |> set_symbol_code(Some(symbol_code_val))
        |> set_comment(comment)
        |> set_course(course)
        |> set_speed(speed),
      )
    }
  }
}

fn decode_compressed_latitude(chars: String) -> Result(Float, ParseError) {
  case decode_base91_chars(chars) {
    Ok(val) -> {
      // Debug: print the value
      let lat = 90.0 -. int.to_float(val) /. 380926.0
      case lat >=. -90.0 && lat <=. 90.0 {
        True -> Ok(lat)
        False -> Error(InvalidPosition)
      }
    }
    Error(_) -> Error(InvalidPosition)
  }
}

fn decode_compressed_longitude(chars: String) -> Result(Float, ParseError) {
  case decode_base91_chars(chars) {
    Ok(val) -> Ok(-180.0 +. int.to_float(val) /. 190463.0)
    Error(_) -> Error(InvalidPosition)
  }
}

fn decode_compressed_cs_t(cs: String, t: String) -> Result(#(Option(Course), Option(Speed), Option(Altitude)), ParseError) {
  // Get the first byte of the t string
  case string.first(t) {
    Ok(t_char) -> {
      // Convert character to int value
      let t_val = char_to_base91_value(t_char)
      
      case t_val {
        Ok(t_v) if t_v >= 0 && t_v <= 89 -> {
          // Course/Speed
          case decode_base91_chars(cs) {
            Ok(cs_val) -> {
              let course_val = cs_val / 4
              let speed_val = int.to_float({ cs_val % 4 } * 91 + t_v) *. 1.852 // knots to km/h
              
              use course <- result.try(
                case course_val {
                  0 -> Ok(None)
                  c if c >= 1 && c <= 360 -> {
                    let normalized_course = case c == 360 { True -> 0 False -> c }
                    let assert Ok(course) = make_course(normalized_course)
                    Ok(Some(course))
                  }
                  _ -> Error(InvalidPosition)
                }
              )
              
              use speed <- result.try(
                case speed_val >. 0.0 {
                  True -> 
                    make_speed(speed_val)
                    |> result.map(Some)
                    |> result.map_error(fn(_) { InvalidPosition })
                  False -> Ok(None)
                }
              )
              
              Ok(#(course, speed, None))
            }
            Error(_) -> Error(InvalidPosition)
          }
        }
        _ -> {
          // No course/speed data
          Ok(#(None, None, None))
        }
      }
    }
    Error(_) -> Error(InvalidPosition)
  }
}

fn generate_base91_chars() -> String {
  // Base-91 character set in order (ASCII 32-126, excluding 96)
  " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
}

fn int_to_char(code: Int) -> String {
  // Convert an ASCII code to a single character string
  // This is a workaround since Gleam doesn't have a direct int-to-char function
  let all_chars = generate_base91_chars()
  case code >= 32 && code <= 126 && code != 96 {
    True -> {
      let index = case code > 96 { 
        True -> code - 33 
        False -> code - 32 
      }
      string.slice(all_chars, index, 1)
    }
    False -> ""
  }
}

fn generate_ascii_range(start: Int, end: Int, acc: List(Int)) -> List(Int) {
  case start > end {
    True -> list.reverse(acc)
    False -> generate_ascii_range(start + 1, end, [start, ..acc])
  }
}

fn get_base91_map() {
  // Generate all ASCII codes from 32 to 126, excluding 96
  let ascii_codes = 
    list.append(
      generate_ascii_range(32, 95, []),
      generate_ascii_range(97, 126, [])
    )
  
  // Create the mapping
  ascii_codes
  |> list.map(fn(code) { #(int_to_char(code), code) })
  |> list.filter(fn(pair) { pair.0 != "" })
  |> dict.from_list
}

fn char_to_base91_value(char: String) -> Result(Int, ParseError) {
  case string.to_graphemes(char) {
    [c] -> {
      case dict.get(get_base91_map(), c) {
        Ok(byte) if byte >= 33 && byte <= 126 && byte != 96 -> 
          Ok(byte - 33)
        _ -> 
          Error(InvalidPosition)
      }
    }
    _ -> Error(InvalidPosition)
  }
}

fn decode_base91_chars(chars: String) -> Result(Int, ParseError) {
  let graphemes = string.to_graphemes(chars)
  list.try_fold(graphemes, 0, fn(acc, char) {
    case char_to_base91_value(char) {
      Ok(code) -> Ok(acc * 91 + code)
      Error(_) -> Error(InvalidPosition)
    }
  })
}

fn parse_uncompressed_position_packet(
  data: String,
) -> Result(BodyParseResult, ParseError) {
  case string.length(data) < 19 {
    True -> Error(InvalidPosition)
    False -> {
      let position_data = string.slice(data, 0, 19)
      let remaining = string.slice(data, 19, string.length(data) - 19)

      use position <- result.try(parse_uncompressed_position(position_data))
      use extensions <- result.try(parse_position_extensions(remaining))

      Ok(
        empty_body_result()
        |> set_packet_type(PositionPacket)
        |> set_position(Some(position.position))
        |> set_symbol_table(Some(position.symbol_table))
        |> set_symbol_code(Some(position.symbol_code))
        |> set_comment(extensions.comment)
        |> set_course(extensions.course)
        |> set_speed(extensions.speed)
        |> set_altitude(extensions.altitude)
        |> set_phg(extensions.phg)
        |> set_rng(extensions.rng),
      )
    }
  }
}

pub fn parse_uncompressed_position(
  pos_data: String,
) -> Result(PositionInfo, ParseError) {
  case string.length(pos_data) == 19 {
    False -> Error(InvalidPosition)
    True -> {
      let lat_str = string.slice(pos_data, 0, 8)
      let symbol_table_str = string.slice(pos_data, 8, 1)
      let lon_str = string.slice(pos_data, 9, 9)
      let symbol_code_str = string.slice(pos_data, 18, 1)

      use latitude_deg <- result.try(parse_latitude(lat_str))
      use longitude_deg <- result.try(parse_longitude(lon_str))

      use latitude <- result.try(
        make_latitude(latitude_deg)
        |> result.map_error(fn(_) { InvalidPosition }),
      )
      use longitude <- result.try(
        make_longitude(longitude_deg)
        |> result.map_error(fn(_) { InvalidPosition }),
      )
      use symbol_table <- result.try(
        make_symbol_table(symbol_table_str)
        |> result.map_error(fn(_) { InvalidPosition }),
      )
      use symbol_code <- result.try(
        make_symbol_code(symbol_code_str)
        |> result.map_error(fn(_) { InvalidPosition }),
      )

      Ok(PositionInfo(
        position: StrictPosition(
          latitude: latitude,
          longitude: longitude,
          ambiguity: 0,
          altitude: None,
        ),
        symbol_table: symbol_table,
        symbol_code: symbol_code,
      ))
    }
  }
}

pub fn parse_latitude(lat_str: String) -> Result(Float, ParseError) {
  case string.length(lat_str) == 8 {
    False -> Error(InvalidPosition)
    True -> {
      let degrees_str = string.slice(lat_str, 0, 2)
      let minutes_str = string.slice(lat_str, 2, 5)  // This gets "28.51" from "6028.51N"
      let ns = string.slice(lat_str, 7, 1)

      use degrees <- result.try(
        int.parse(degrees_str) |> result.map_error(fn(_) { InvalidPosition }),
      )
      use minutes <- result.try(
        float.parse(minutes_str) |> result.map_error(fn(_) { InvalidPosition }),
      )

      case degrees >= 0 && degrees <= 90 && minutes >=. 0.0 && minutes <. 60.0 {
        False -> Error(InvalidPosition)
        True -> {
          let decimal_degrees = int.to_float(degrees) +. minutes /. 60.0
          case ns {
            "N" -> Ok(decimal_degrees)
            "S" -> Ok(0.0 -. decimal_degrees)
            _ -> Error(InvalidPosition)
          }
        }
      }
    }
  }
}

pub fn parse_longitude(lon_str: String) -> Result(Float, ParseError) {
  case string.length(lon_str) == 9 {
    False -> Error(InvalidPosition)
    True -> {
      let degrees_str = string.slice(lon_str, 0, 3)
      let minutes_str = string.slice(lon_str, 3, 5)  // This gets "05.68" from "02505.68E"
      let ew = string.slice(lon_str, 8, 1)

      use degrees <- result.try(
        int.parse(degrees_str) |> result.map_error(fn(_) { InvalidPosition }),
      )
      use minutes <- result.try(
        float.parse(minutes_str) |> result.map_error(fn(_) { InvalidPosition }),
      )

      case
        degrees >= 0 && degrees <= 180 && minutes >=. 0.0 && minutes <. 60.0
      {
        False -> Error(InvalidPosition)
        True -> {
          let decimal_degrees = int.to_float(degrees) +. minutes /. 60.0
          case ew {
            "E" -> Ok(decimal_degrees)
            "W" -> Ok(0.0 -. decimal_degrees)
            _ -> Error(InvalidPosition)
          }
        }
      }
    }
  }
}

pub type PositionExtensions {
  PositionExtensions(
    course: Option(Course),
    speed: Option(Speed),
    altitude: Option(Altitude),
    phg: Option(StrictPhgData),
    rng: Option(Range),
    comment: Option(String),
  )
}

pub fn parse_position_extensions(
  data: String,
) -> Result(PositionExtensions, ParseError) {
  case string.is_empty(data) {
    True ->
      Ok(PositionExtensions(
        course: None,
        speed: None,
        altitude: None,
        phg: None,
        rng: None,
        comment: None,
      ))
    False -> parse_extensions_internal(data)
  }
}

fn parse_extensions_internal(
  data: String,
) -> Result(PositionExtensions, ParseError) {
  let position_data = data

  let #(course, speed, remaining1) = parse_course_speed(position_data)
  let #(phg, remaining2) = parse_phg_data(remaining1)
  let #(rng, remaining3) = parse_rng_data(remaining2)
  let #(altitude, remaining4) = parse_altitude_data(remaining3)
  let #(_dao_data, remaining5) = parse_dao_extension(remaining4)

  let final_comment = case string.is_empty(remaining5) {
    True -> None
    False -> Some(string.trim(remaining5))
  }

  Ok(PositionExtensions(
    course: course,
    speed: speed,
    altitude: altitude,
    phg: phg,
    rng: rng,
    comment: final_comment,
  ))
}

fn parse_course_speed(data: String) -> #(Option(Course), Option(Speed), String) {
  case string.length(data) >= 7 {
    False -> #(None, None, data)
    True -> {
      let prefix = string.slice(data, 0, 7)
      case
        string_utils.is_all_digits(string.slice(prefix, 0, 3))
        && string.slice(prefix, 3, 1) == "/"
        && string_utils.is_all_digits(string.slice(prefix, 4, 3))
      {
        True -> {
          let course_str = string.slice(prefix, 0, 3)
          let speed_str = string.slice(prefix, 4, 3)
          let remaining = string.slice(data, 7, string.length(data) - 7)

          let course = case int.parse(course_str) {
            Ok(c) if c >= 1 && c <= 360 ->
              case make_course(case c == 360 { True -> 0 False -> c }) {
                Ok(course) -> Some(course)
                Error(_) -> None
              }
            _ -> None
          }

          let speed = case int.parse(speed_str) {
            Ok(s) -> 
              case make_speed(int.to_float(s) *. 1.852) {
                Ok(speed) -> Some(speed)
                Error(_) -> None
              }
            _ -> None
          }

          #(course, speed, remaining)
        }
        False -> #(None, None, data)
      }
    }
  }
}

fn parse_phg_data(data: String) -> #(Option(StrictPhgData), String) {
  case string.starts_with(data, "PHG") && string.length(data) >= 7 {
    True -> {
      let phg_str = string.slice(data, 3, 4)
      let remaining = string.slice(data, 7, string.length(data) - 7)
      
      case parse_phg_digits(phg_str) {
        Ok(phg) -> #(Some(phg), remaining)
        Error(_) -> #(None, data)
      }
    }
    False -> #(None, data)
  }
}

fn parse_phg_digits(
  phg_str: String,
) -> Result(StrictPhgData, ParseError) {
  case string.length(phg_str) == 4 {
    False -> Error(InvalidPosition)
    True -> {
      let chars = string.to_graphemes(phg_str)
      case chars {
        [p, h, g, d] -> {
          use power <- result.try(parse_phg_value(p))
          use height <- result.try(parse_phg_value(h))
          use gain <- result.try(parse_phg_value(g))
          use directivity <- result.try(parse_phg_value(d))
          
          Ok(StrictPhgData(
            power: power,
            height: height,
            gain: gain,
            directivity: directivity,
          ))
        }
        _ -> Error(InvalidPosition)
      }
    }
  }
}

fn parse_phg_value(char: String) -> Result(PhgValue, ParseError) {
  case int.parse(char) {
    Ok(n) if n >= 0 && n <= 9 -> {
      let assert Ok(phg) = make_phg_value(n)
      Ok(phg)
    }
    _ -> Error(InvalidPosition)
  }
}

fn parse_rng_data(data: String) -> #(Option(Range), String) {
  case string.starts_with(data, "RNG") && string.length(data) >= 7 {
    True -> {
      let range_str = string.slice(data, 3, 4)
      let remaining = string.slice(data, 7, string.length(data) - 7)
      
      case int.parse(range_str) {
        Ok(r) -> {
          let range_km = int.to_float(r) *. 1.60934
          case make_range(range_km) {
            Ok(range) -> #(Some(range), remaining)
            Error(_) -> #(None, data)
          }
        }
        Error(_) -> #(None, data)
      }
    }
    False -> #(None, data)
  }
}

fn parse_altitude_data(data: String) -> #(Option(Altitude), String) {
  case string.starts_with(data, "/A=") && string.length(data) >= 9 {
    True -> {
      let alt_str = string.slice(data, 3, 6)
      let remaining = string.slice(data, 9, string.length(data) - 9)
      
      case int.parse(alt_str) {
        Ok(alt_feet) -> {
          let alt_meters = int.to_float(alt_feet) *. 0.3048
          case make_altitude(alt_meters) {
            Ok(altitude) -> #(Some(altitude), remaining)
            Error(_) -> #(None, data)
          }
        }
        Error(_) -> #(None, data)
      }
    }
    False -> #(None, data)
  }
}

fn parse_dao_extension(data: String) -> #(Option(String), String) {
  case string.starts_with(data, "!DAO!") && string.length(data) >= 5 {
    True -> {
      let dao_info = string.slice(data, 0, 5)
      let remaining = string.slice(data, 5, string.length(data) - 5)
      #(Some(dao_info), remaining)
    }
    False -> #(None, data)
  }
}

