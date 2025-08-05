import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import aprs/constants
import aprs/utils
import aprs/position
import aprs/weather
import aprs/mice
import aprs/result_utils.{
  empty_body_result, set_addressee, set_comment, set_course, set_item_alive,
  set_item_name, set_message, set_message_ack, set_message_id, set_message_reject,
  set_object_alive, set_object_name, set_packet_type, set_position, set_speed,
  set_symbol_code, set_symbol_table, set_telemetry, set_weather,
}
import aprs/string_utils
import aprs/types.{
  type BodyParseResult, type ParseError, type ParseResult, type StationId,
  type Timestamp, type MessageId, type StrictPosition, type SymbolTable, type SymbolCode,
  type MiceLatitude, type MiceInformation,
  InvalidDigipeaterCall, InvalidPosition, InvalidSourceCall, 
  InvalidMessage, InvalidTimestamp, Message, NoBody, NoPacketGiven, PacketTooShort, ParseResult, 
  StationId, Status, TooManyDigipeaters, UnknownPacket, UnsupportedFormat,
  Item, MicE, Object, StrictPosition, StrictTelemetryData, Telemetry, Weather, InvalidMicE,
  make_addressee, make_altitude, make_callsign, make_course, make_latitude,
  make_longitude, make_message_id, make_object_name, make_speed, make_ssid,
  make_symbol_code, make_symbol_table, make_timestamp,
}

pub fn parse_aprs(packet: String) -> Result(ParseResult, ParseError) {
  case string.is_empty(packet) {
    True -> Error(NoPacketGiven)
    False -> parse_packet_internal(packet)
  }
}

fn parse_packet_internal(packet: String) -> Result(ParseResult, ParseError) {
  case string.length(packet) < constants.min_packet_length {
    True -> Error(PacketTooShort)
    False ->
      string.split_once(packet, ":")
      |> result.replace_error(NoBody)
      |> result.try(fn(split) {
        let #(header, body) = split
        case string.is_empty(body) {
          True -> Error(NoBody)
          False -> Ok(#(header, body))
        }
      })
      |> result.try(fn(parts) {
        let #(header, body) = parts
        parse_header_and_body(header, body)
      })
  }
}

fn parse_header_and_body(
  header header: String,
  body body: String,
) -> Result(ParseResult, ParseError) {
  use header_parts <- result.try(parse_header(header))
  let #(source, destination, digipeaters) = header_parts

  use packet_info <- result.try(parse_body_with_context(
    body,
    source,
    destination,
  ))

  use source_station <- result.try(parse_station_id(source))
  use dest_station <- result.try(parse_station_id(destination))
  use digi_stations <- result.try(list.try_map(digipeaters, parse_station_id))

  Ok(ParseResult(
    source: source_station,
    destination: dest_station,
    digipeaters: digi_stations,
    packet_type: packet_info.packet_type,
    position: packet_info.position,
    message: packet_info.message,
    symbol_table: packet_info.symbol_table,
    symbol_code: packet_info.symbol_code,
    timestamp: packet_info.timestamp,
    weather: packet_info.weather,
    telemetry: packet_info.telemetry,
    comment: packet_info.comment,
    course: packet_info.course,
    speed: packet_info.speed,
    altitude: packet_info.altitude,
    mic_e_message: packet_info.mic_e_message,
    dao_datum: packet_info.dao_datum,
    dao_precision: packet_info.dao_precision,
    phg: packet_info.phg,
    rng: packet_info.rng,
    object_name: packet_info.object_name,
    object_alive: packet_info.object_alive,
    item_name: packet_info.item_name,
    item_alive: packet_info.item_alive,
    addressee: packet_info.addressee,
    message_id: packet_info.message_id,
    message_ack: packet_info.message_ack,
    message_reject: packet_info.message_reject,
    status: packet_info.status,
  ))
}

pub fn parse_header(
  header header: String,
) -> Result(#(String, String, List(String)), ParseError) {
  let clean_header = string.trim(header) |> string.uppercase

  case string.split_once(clean_header, ">") {
    Ok(#(source, rest)) -> {
      use _ <- result.try(validate_ax25_call(source))

      case string.split_once(rest, ",") {
        Ok(#(destination, digi_path)) -> {
          use _ <- result.try(validate_ax25_call(destination))
          let digipeaters = parse_digipeater_path(digi_path)
          use validated_digis <- result.try(validate_digipeaters(digipeaters))
          Ok(#(source, destination, validated_digis))
        }
        Error(_) -> {
          use _ <- result.try(validate_ax25_call(rest))
          Ok(#(source, rest, []))
        }
      }
    }
    Error(_) -> Error(InvalidSourceCall)
  }
}

fn validate_ax25_call(call: String) -> Result(String, ParseError) {
  let clean_call = string.replace(call, "*", "")

  case string.length(clean_call) {
    len if len < 1 || len > 9 -> Error(InvalidSourceCall)
    _ -> {
      case string.split_once(clean_call, "-") {
        Ok(#(base_call, ssid)) -> {
          use _ <- result.try(validate_base_call(base_call))
          use _ <- result.try(validate_ssid(ssid))
          Ok(call)
        }
        Error(_) -> validate_base_call(clean_call) |> result.map(fn(_) { call })
      }
    }
  }
}

fn validate_base_call(call: String) -> Result(String, ParseError) {
  let len = string.length(call)
  // Limit length to prevent excessive processing
  case len >= 1 && len <= 9 && string_utils.is_alphanumeric(call) {
    True -> Ok(call)
    False -> Error(InvalidSourceCall)
  }
}

fn validate_ssid(ssid: String) -> Result(String, ParseError) {
  // Check for numeric SSID (0-15)
  case int.parse(ssid) {
    Ok(n) if n >= 0 && n <= 15 -> Ok(ssid)
    _ -> {
      // Allow letter SSIDs for D-Star stations (e.g., -B, -BS, -RP)
      case string.length(ssid) <= 3 && string_utils.is_alphanumeric(ssid) {
        True -> Ok(ssid)
        False -> Error(InvalidSourceCall)
      }
    }
  }
}

fn parse_digipeater_path(path: String) -> List(String) {
  string.split(path, ",")
  |> list.map(string.trim)
  |> list.filter(fn(s) { !string.is_empty(s) })
}

fn validate_digipeaters(
  digis: List(String),
) -> Result(List(String), ParseError) {
  case list.length(digis) > 8 {
    True -> Error(TooManyDigipeaters)
    False -> {
      list.try_map(digis, fn(digi) {
        validate_ax25_call(digi)
        |> result.map_error(fn(_) { InvalidDigipeaterCall })
      })
    }
  }
}

pub fn parse_station_id(callsign_str: String) -> Result(StationId, ParseError) {
  let clean_call = string.trim(callsign_str) |> string.replace("*", "")

  case string.split_once(clean_call, "-") {
    Ok(#(base_call, ssid_str)) -> {
      use callsign <- result.try(
        make_callsign(base_call)
        |> result.map_error(fn(_) { InvalidSourceCall }),
      )
      use ssid_int <- result.try(
        int.parse(ssid_str)
        |> result.map_error(fn(_) { InvalidSourceCall }),
      )
      use ssid <- result.try(
        make_ssid(ssid_int)
        |> result.map_error(fn(_) { InvalidSourceCall }),
      )
      Ok(StationId(callsign: callsign, ssid: Some(ssid)))
    }
    Error(_) -> {
      use callsign <- result.try(
        make_callsign(clean_call)
        |> result.map_error(fn(_) { InvalidSourceCall }),
      )
      Ok(StationId(callsign: callsign, ssid: None))
    }
  }
}

type PacketParser =
  fn(String, String, String) -> Result(BodyParseResult, ParseError)

fn get_simple_parser(
  parser: fn(String) -> Result(BodyParseResult, ParseError),
) -> PacketParser {
  fn(body, _source, _destination) { parser(body) }
}

fn get_parser_for_prefix(prefix: String) -> Option(PacketParser) {
  case prefix {
    "!" | "=" -> Some(get_simple_parser(parse_position_packet))
    "@" | "/" -> Some(get_simple_parser(parse_timestamp_position_packet))
    "'" | "`" -> Some(parse_mice_packet_with_context)
    ";" -> Some(get_simple_parser(parse_object_packet))
    ")" -> Some(get_simple_parser(parse_item_packet))
    ":" -> Some(get_simple_parser(parse_message_packet))
    "T" -> Some(get_simple_parser(parse_telemetry_packet))
    "_" -> Some(get_simple_parser(parse_weather_packet))
    "$" -> Some(get_simple_parser(parse_nmea_packet))
    ">" -> Some(get_simple_parser(parse_status_packet))
    _ -> None
  }
}

fn parse_unknown_or_dx(
  body body: String,
  source source: String,
) -> Result(BodyParseResult, ParseError) {
  parse_dx_spot(body, source)
  |> result.lazy_unwrap(fn() {
    empty_body_result()
    |> set_packet_type(UnknownPacket)
    |> set_comment(Some(body))
  })
  |> Ok
}

pub fn parse_body_with_context(
  body body: String,
  source source: String,
  destination destination: String,
) -> Result(BodyParseResult, ParseError) {
  string.first(body)
  |> result.unwrap("")
  |> get_parser_for_prefix
  |> option.map(fn(parser) { parser(body, source, destination) })
  |> option.lazy_unwrap(fn() { parse_unknown_or_dx(body, source) })
}

// Delegate to position module
fn parse_position_packet(body: String) -> Result(BodyParseResult, ParseError) {
  position.parse_position_packet(body)
}

fn extract_timestamp_components(body: String) -> Result(#(String, String, String), ParseError) {
  case string.length(body) < constants.timestamp_packet_min_length {
    True -> Error(InvalidPosition)
    False -> {
      let timestamp_str = string.slice(body, 1, 6)
      let tz = string.slice(body, 7, 1)
      let remaining = string.slice(body, 8, string.length(body) - 8)
      Ok(#(timestamp_str, tz, remaining))
    }
  }
}

fn split_weather_data(data: String) -> Result(#(String, String), ParseError) {
  case string.split(data, "_") {
    [pos_part, weather_part] -> Ok(#(pos_part, weather_part))
    _ -> Error(InvalidPosition)
  }
}

fn combine_position_and_weather(
  position_part pos_part: String,
  weather_part weather_part: String,
  timestamp timestamp: Timestamp,
) -> Result(BodyParseResult, ParseError) {
  use pos_result <- result.try(position.parse_position_packet("!" <> pos_part))
  use weather_result <- result.try(parse_weather_data("_" <> weather_part))
  
  Ok(
    pos_result
    |> result_utils.set_timestamp(Some(timestamp))
    |> set_packet_type(Weather)
    |> set_weather(weather_result.weather)
    |> set_comment(weather_result.comment)
  )
}

fn parse_position_only(
  data data: String,
  timestamp timestamp: Timestamp,
) -> Result(BodyParseResult, ParseError) {
  use result <- result.try(position.parse_position_packet("!" <> data))
  Ok(result |> result_utils.set_timestamp(Some(timestamp)))
}

fn parse_timestamp_position_packet(
  body: String,
) -> Result(BodyParseResult, ParseError) {
  use #(timestamp_str, tz, remaining) <- result.try(extract_timestamp_components(body))
  use timestamp <- result.try(parse_timestamp(timestamp_str, tz))
  
  case string.contains(remaining, "_") {
    True -> {
      case split_weather_data(remaining) {
        Ok(#(pos_part, weather_part)) -> 
          combine_position_and_weather(pos_part, weather_part, timestamp)
        Error(_) -> 
          parse_position_only(remaining, timestamp)
      }
    }
    False -> parse_position_only(remaining, timestamp)
  }
}

fn is_valid_timestamp(day: Int, hour: Int, min: Int) -> Bool {
  day >= 1 && day <= 31 && hour >= 0 && hour <= 23 && min >= 0 && min <= 59
}

fn parse_timestamp(time_str: String, _tz: String) -> Result(Timestamp, ParseError) {
  case string.length(time_str) == constants.timestamp_field_length {
    False -> Error(InvalidTimestamp)
    True -> {
      let day_str = string.slice(time_str, 0, 2)
      let hour_str = string.slice(time_str, 2, 2)
      let min_str = string.slice(time_str, 4, 2)
      
      use day <- result.try(
        int.parse(day_str) |> result.map_error(fn(_) { InvalidTimestamp })
      )
      use hour <- result.try(
        int.parse(hour_str) |> result.map_error(fn(_) { InvalidTimestamp })
      )
      use min <- result.try(
        int.parse(min_str) |> result.map_error(fn(_) { InvalidTimestamp })
      )
      
      case is_valid_timestamp(day, hour, min) {
        False -> Error(InvalidTimestamp)
        True -> {
          // Convert to seconds since start of month
          let timestamp_val = { day - 1 } * constants.seconds_per_day + hour * constants.seconds_per_hour + min * constants.seconds_per_minute
          make_timestamp(timestamp_val)
          |> result.map_error(fn(_) { InvalidTimestamp })
        }
      }
    }
  }
}

fn apply_hemisphere_sign(value value: Float, direction direction: String, positive positive: String) -> Float {
  case direction {
    d if d == positive -> value
    _ -> 0.0 -. value
  }
}

fn decode_mice_position(
  mice_lat mice_lat: MiceLatitude,
  mice_info mice_info: MiceInformation,
) -> Result(StrictPosition, ParseError) {
  let lat_val = apply_hemisphere_sign(mice_lat.latitude, mice_lat.north_south, "N")
  let lon_val = apply_hemisphere_sign(mice_info.longitude, mice_lat.east_west, "E")
  
  use latitude <- result.try(
    make_latitude(lat_val)
    |> result.map_error(fn(_) { InvalidMicE })
  )
  
  use longitude <- result.try(
    make_longitude(lon_val)
    |> result.map_error(fn(_) { InvalidMicE })
  )
  
  let altitude = utils.option_try_map(mice_info.altitude, make_altitude)
  
  Ok(StrictPosition(
    latitude: latitude,
    longitude: longitude,
    ambiguity: mice_lat.ambiguity,
    altitude: altitude,
  ))
}

fn decode_mice_symbols(
  mice_info mice_info: MiceInformation,
) -> Result(#(SymbolTable, SymbolCode), ParseError) {
  use symbol_table <- result.try(
    make_symbol_table(mice_info.symbol_table)
    |> result.map_error(fn(_) { InvalidMicE })
  )
  
  use symbol_code <- result.try(
    make_symbol_code(mice_info.symbol_code)
    |> result.map_error(fn(_) { InvalidMicE })
  )
  
  Ok(#(symbol_table, symbol_code))
}

fn build_mice_result(
  position position: StrictPosition,
  symbols symbols: #(SymbolTable, SymbolCode),
  mice_info mice_info: MiceInformation,
) -> BodyParseResult {
  let #(symbol_table, symbol_code) = symbols
  let course = utils.option_try_map(mice_info.course, make_course)
  let speed = utils.option_try_map(mice_info.speed, make_speed)
  
  empty_body_result()
  |> set_packet_type(MicE)
  |> set_position(Some(position))
  |> set_symbol_table(Some(symbol_table))
  |> set_symbol_code(Some(symbol_code))
  |> set_comment(mice_info.comment)
  |> set_course(course)
  |> set_speed(speed)
}

fn parse_mice_packet_with_context(
  body body: String,
  source _source: String,
  destination destination: String,
) -> Result(BodyParseResult, ParseError) {
  use mice_lat <- result.try(
    mice.decode_mice_destination(destination)
    |> result.map_error(fn(_) { InvalidMicE })
  )
  
  use mice_info <- result.try(
    mice.decode_mice_data(body)
    |> result.map_error(fn(_) { InvalidMicE })
  )
  
  use position <- result.try(decode_mice_position(mice_lat, mice_info))
  use symbols <- result.try(decode_mice_symbols(mice_info))
  
  Ok(build_mice_result(position, symbols, mice_info))
}

fn parse_object_packet(body: String) -> Result(BodyParseResult, ParseError) {
  // Object format: ;OBJNAME  *DDHHMMzDDMM.HH[NS]DDDMM.HH[EW]ICON...
  // Object name is 9 chars padded with spaces
  case string.length(body) < 37 {
    True -> Error(UnsupportedFormat)
    False -> {
      let obj_name = string.slice(body, 1, 9)
      let alive_dead = string.slice(body, 10, 1)
      let _timestamp = string.slice(body, 11, 7)
      let position_and_data = string.slice(body, 18, string.length(body) - 18)
      
      // Determine if object is alive (*) or dead (_)
      let is_alive = case alive_dead {
        "*" -> Some(True)
        "_" -> Some(False)
        _ -> None
      }
      
      // Create object name
      use object_name <- result.try(
        make_object_name(string.trim(obj_name))
        |> result.map_error(fn(_) { UnsupportedFormat })
      )
      
      // Parse the position part - similar to regular position
      use pos_result <- result.try(
        position.parse_position_packet("!" <> position_and_data)
      )
      
      Ok(
        pos_result
        |> set_packet_type(Object)
        |> set_object_name(Some(object_name))
        |> set_object_alive(is_alive)
      )
    }
  }
}

fn parse_item_packet(body: String) -> Result(BodyParseResult, ParseError) {
  // Item format: )ITEM!DDMM.HH[NS]IDDDMM.HH[EW]#...
  // Item name is 3-9 chars followed by ! or _
  case string.length(body) < 18 {
    True -> Error(UnsupportedFormat)
    False -> {
      // Find the ! or _ that marks the end of the item name
      let item_end = find_item_name_end(body, 1)
      
      case item_end {
        None -> Error(UnsupportedFormat)
        Some(end_pos) -> {
          let item_name_str = string.slice(body, 1, end_pos - 1)
          let alive_dead = string.slice(body, end_pos, 1)
          let position_and_data = string.slice(body, end_pos + 1, string.length(body) - end_pos - 1)
          
          // Determine if item is alive (!) or dead (_)
          let is_alive = case alive_dead {
            "!" -> Some(True)
            "_" -> Some(False)
            _ -> None
          }
          
          // Create item name (reuse object name type)
          use item_name <- result.try(
            make_object_name(item_name_str)
            |> result.map_error(fn(_) { UnsupportedFormat })
          )
          
          // Parse the position part
          use pos_result <- result.try(
            position.parse_position_packet("!" <> position_and_data)
          )
          
          Ok(
            pos_result
            |> set_packet_type(Item)
            |> set_item_name(Some(item_name))
            |> set_item_alive(is_alive)
          )
        }
      }
    }
  }
}

fn find_item_name_end(body: String, start: Int) -> Option(Int) {
  case start > 10 || start >= string.length(body) {
    True -> None
    False -> {
      let char = string.slice(body, start, 1)
      case char {
        "!" | "_" -> Some(start)
        _ -> find_item_name_end(body, start + 1)
      }
    }
  }
}

type MessageType {
  Acknowledgment(String)
  Rejection(String)
  RegularMessage(String, Option(MessageId))
}

fn detect_message_type(message_and_id: String) -> MessageType {
  case message_and_id {
    "ack" <> rest -> Acknowledgment(rest)
    "rej" <> rest -> Rejection(rest)
    _ -> {
      case string.split(message_and_id, "{") {
        [msg, id] -> 
          case make_message_id(id) {
            Ok(msg_id) -> RegularMessage(msg, Some(msg_id))
            Error(_) -> RegularMessage(message_and_id, None)
          }
        _ -> RegularMessage(message_and_id, None)
      }
    }
  }
}

fn validate_message_format(body: String) -> Result(#(String, String), ParseError) {
  case string.length(body) < 11 {
    True -> Error(InvalidMessage)
    False -> {
      let addressee_str = string.slice(body, 1, 9)
      let separator = string.slice(body, 10, 1)
      let message_part = string.slice(body, 11, string.length(body) - 11)
      
      case separator {
        ":" -> Ok(#(addressee_str, message_part))
        _ -> Error(InvalidMessage)
      }
    }
  }
}

fn build_message_result(
  addressee: types.Addressee,
  message_type: MessageType,
) -> Result(BodyParseResult, ParseError) {
  let base_result =
    empty_body_result()
    |> set_packet_type(Message)
    |> set_addressee(Some(addressee))
  
  case message_type {
    Acknowledgment(id) ->
      make_message_id(id)
      |> result.map(fn(ack) { set_message_ack(base_result, Some(ack)) })
      |> result.map_error(fn(_) { InvalidMessage })
    
    Rejection(id) ->
      make_message_id(id)
      |> result.map(fn(rej) { set_message_reject(base_result, Some(rej)) })
      |> result.map_error(fn(_) { InvalidMessage })
    
    RegularMessage(text, id) ->
      Ok(
        base_result
        |> set_message(Some(text))
        |> set_message_id(id)
      )
  }
}

fn parse_message_packet(body: String) -> Result(BodyParseResult, ParseError) {
  use #(addressee_str, message_part) <- result.try(validate_message_format(body))
  use addressee <- result.try(
    make_addressee(addressee_str)
    |> result.map_error(fn(_) { InvalidMessage })
  )
  
  let message_type = detect_message_type(message_part)
  build_message_result(addressee, message_type)
}

fn parse_telemetry_packet(body: String) -> Result(BodyParseResult, ParseError) {
  // Telemetry format: T#SEQ,A1,A2,A3,A4,A5,B1B2B3B4B5B6B7B8,COMMENT
  // Where SEQ is sequence number, A1-A5 are analog values, B1-B8 are digital bits
  case string.starts_with(body, "T#") && string.length(body) > 3 {
    False -> Error(UnsupportedFormat)
    True -> {
      let data = string.slice(body, 2, string.length(body) - 2)
      
      case string.split(data, ",") {
        [seq_str, a1, a2, a3, a4, a5, digital_and_comment, ..] -> {
          // Parse sequence number
          use sequence <- result.try(
            int.parse(seq_str)
            |> result.map_error(fn(_) { UnsupportedFormat })
          )
          
          // Parse analog values
          let analog_values = [a1, a2, a3, a4, a5]
          let analog_results = list.map(analog_values, fn(val) {
            case val {
              "" -> Ok(0.0)
              _ -> case int.parse(val) {
                Ok(i) -> Ok(int.to_float(i))
                Error(_) -> case float.parse(val) {
                  Ok(f) -> Ok(f)
                  Error(_) -> Ok(0.0)
                }
              }
            }
          })
          
          let analog = list.map(analog_results, fn(r) {
            case r {
              Ok(v) -> v
              Error(_) -> 0.0
            }
          })
          
          // Parse digital bits and comment
          let #(digital_bits, comment) = case string.length(digital_and_comment) >= 8 {
            True -> {
              let bits_str = string.slice(digital_and_comment, 0, 8)
              let comment_str = string.slice(digital_and_comment, 8, string.length(digital_and_comment) - 8)
              let bits = parse_digital_bits(bits_str)
              #(bits, case string.is_empty(comment_str) {
                True -> None
                False -> Some(string.trim(comment_str))
              })
            }
            False -> {
              #([], case string.is_empty(digital_and_comment) {
                True -> None
                False -> Some(string.trim(digital_and_comment))
              })
            }
          }
          
          let telemetry = StrictTelemetryData(
            sequence: sequence,
            analog: analog,
            digital: digital_bits,
          )
          
          Ok(
            empty_body_result()
            |> set_packet_type(Telemetry)
            |> set_telemetry(Some(telemetry))
            |> set_comment(comment)
          )
        }
        _ -> Error(UnsupportedFormat)
      }
    }
  }
}

fn parse_digital_bits(bits_str: String) -> List(Bool) {
  string.to_graphemes(bits_str)
  |> list.map(fn(char) {
    case char {
      "1" -> True
      _ -> False
    }
  })
}

fn parse_weather_packet(body: String) -> Result(BodyParseResult, ParseError) {
  // Weather format: _MMDDhhmm... or position with weather
  case string.slice(body, 0, 1) {
    "_" -> parse_positionless_weather(body)
    "@" | "/" -> parse_timestamp_position_with_weather(body)
    "!" | "=" -> parse_position_with_weather(body)
    _ -> Error(UnsupportedFormat)
  }
}

fn parse_positionless_weather(body: String) -> Result(BodyParseResult, ParseError) {
  // Format: _MMDDhhmmcDDDsDDDgDDDtTTT...
  case string.length(body) < 9 {
    True -> Error(UnsupportedFormat)
    False -> {
      let _timestamp = string.slice(body, 1, 8)
      let weather_data = string.slice(body, 9, string.length(body) - 9)
      parse_weather_data(weather_data)
      |> result.map(fn(result) {
        result |> set_packet_type(Weather)
      })
    }
  }
}

fn parse_timestamp_position_with_weather(body: String) -> Result(BodyParseResult, ParseError) {
  // Parse as timestamp position first, then extract weather
  case parse_timestamp_position_packet(body) {
    Ok(result) -> {
      // Check if there's weather data after position
      case result.comment {
        Some(comment) -> {
          case string.starts_with(comment, "_") || string.contains(comment, "c") {
            True -> {
              use weather_result <- result.try(parse_weather_data(comment))
              Ok(
                result
                |> set_packet_type(Weather)
                |> set_weather(weather_result.weather)
                |> set_comment(weather_result.comment)
              )
            }
            False -> Ok(result)
          }
        }
        None -> Ok(result)
      }
    }
    Error(e) -> Error(e)
  }
}

fn parse_position_with_weather(body: String) -> Result(BodyParseResult, ParseError) {
  // Find the underscore that marks weather data
  case string.contains(body, "_") {
    False -> Error(UnsupportedFormat)
    True -> {
      case string.split(body, "_") {
        [pos_part, weather_part] -> {
          // Parse position part
          use pos_result <- result.try(position.parse_position_packet(pos_part))
          // Parse weather part
          use weather_result <- result.try(parse_weather_data("_" <> weather_part))
          
          Ok(
            pos_result
            |> set_packet_type(Weather)
            |> set_weather(weather_result.weather)
            |> set_comment(weather_result.comment)
          )
        }
        _ -> Error(UnsupportedFormat)
      }
    }
  }
}

fn parse_weather_data(data: String) -> Result(BodyParseResult, ParseError) {
  // Parse weather elements: cDDDsDDDgDDDtTTTrRRRpPPPPbBBBBBhHH
  let weather_data = case string.starts_with(data, "_") {
    True -> string.slice(data, 1, string.length(data) - 1)
    False -> data
  }
  
  let weather = weather.parse_weather_elements(weather_data)
  
  Ok(
    empty_body_result()
    |> set_weather(Some(weather))
  )
}



fn parse_nmea_packet(body: String) -> Result(BodyParseResult, ParseError) {
  // NMEA format: $GPRMC,... or $GPGGA,... or $GPGLL,...
  case string.starts_with(body, "$") && string.length(body) > 6 {
    False -> Error(UnsupportedFormat)
    True -> {
      let nmea_sentence = string.slice(body, 1, string.length(body) - 1)
      case string.split_once(nmea_sentence, ",") {
        Ok(#(sentence_type, _data)) -> {
          let packet_type = case sentence_type {
            "GPRMC" -> types.NmeaGprmc
            "GPGGA" -> types.NmeaGpgga  
            "GPGLL" -> types.NmeaGpgll
            _ -> types.UnknownPacket
          }
          
          Ok(
            empty_body_result()
            |> set_packet_type(packet_type) 
            |> set_comment(Some(body))
          )
        }
        Error(_) -> Error(UnsupportedFormat)
      }
    }
  }
}

fn parse_status_packet(body: String) -> Result(BodyParseResult, ParseError) {
  Ok(
    empty_body_result()
    |> set_packet_type(Status)
    |> set_comment(Some(string.slice(body, 1, string.length(body) - 1))),
  )
}

fn parse_dx_spot(
  body: String,
  _source: String,
) -> Result(BodyParseResult, ParseError) {
  // DX spots typically have format: DX de CALL: FREQ DX CALL INFO
  // They can also be in formats like: "CALL: FREQ DX" or "FREQ CALL"
  case 
    string.contains(body, "DX de") || 
    string.contains(body, ":") && string.contains(body, ".")
  {
    False -> Error(UnsupportedFormat)
    True -> {
      // Basic DX spot detection - look for frequency patterns
      let words = string.split(body, " ")
      let has_freq = list.any(words, fn(word) {
        string.contains(word, ".") && {
          case string.replace(word, ".", "") |> string_utils.is_all_digits() {
            True -> string.length(word) >= 4 && string.length(word) <= 10
            False -> False
          }
        }
      })
      
      case has_freq {
        True -> Ok(
          empty_body_result()
          |> set_packet_type(types.DxSpot)
          |> set_comment(Some(body))
        )
        False -> Error(UnsupportedFormat)
      }
    }
  }
}