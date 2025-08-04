import gleam/option.{type Option, None}
import aprs/types.{
  type Addressee, type Altitude, type BodyParseResult, type Course, type MessageId,
  type ObjectName, type PacketType, type Range, type Speed, type StrictPhgData,
  type StrictPosition, type StrictTelemetryData, type StrictWeatherData, 
  type SymbolCode, type SymbolTable, type Timestamp,
  BodyParseResult, UnknownPacket,
}

// Empty body result constructor
pub fn empty_body_result() -> BodyParseResult {
  BodyParseResult(
    packet_type: UnknownPacket,
    position: None,
    message: None,
    symbol_table: None,
    symbol_code: None,
    timestamp: None,
    weather: None,
    telemetry: None,
    comment: None,
    course: None,
    speed: None,
    altitude: None,
    mic_e_message: None,
    dao_datum: None,
    dao_precision: None,
    phg: None,
    rng: None,
    object_name: None,
    object_alive: None,
    item_name: None,
    item_alive: None,
    addressee: None,
    message_id: None,
    message_ack: None,
    message_reject: None,
    status: None,
  )
}

// Setter functions for BodyParseResult
pub fn set_packet_type(
  result: BodyParseResult,
  packet_type: PacketType,
) -> BodyParseResult {
  BodyParseResult(..result, packet_type: packet_type)
}

pub fn set_comment(
  result: BodyParseResult,
  comment: Option(String),
) -> BodyParseResult {
  BodyParseResult(..result, comment: comment)
}

pub fn set_position(
  result: BodyParseResult,
  position: Option(StrictPosition),
) -> BodyParseResult {
  BodyParseResult(..result, position: position)
}

pub fn set_symbol_table(
  result: BodyParseResult,
  symbol_table: Option(SymbolTable),
) -> BodyParseResult {
  BodyParseResult(..result, symbol_table: symbol_table)
}

pub fn set_symbol_code(
  result: BodyParseResult,
  symbol_code: Option(SymbolCode),
) -> BodyParseResult {
  BodyParseResult(..result, symbol_code: symbol_code)
}

pub fn set_course(
  result: BodyParseResult,
  course: Option(Course),
) -> BodyParseResult {
  BodyParseResult(..result, course: course)
}

pub fn set_speed(
  result: BodyParseResult,
  speed: Option(Speed),
) -> BodyParseResult {
  BodyParseResult(..result, speed: speed)
}

pub fn set_altitude(
  result: BodyParseResult,
  altitude: Option(Altitude),
) -> BodyParseResult {
  BodyParseResult(..result, altitude: altitude)
}

pub fn set_phg(
  result: BodyParseResult,
  phg: Option(StrictPhgData),
) -> BodyParseResult {
  BodyParseResult(..result, phg: phg)
}

pub fn set_rng(
  result: BodyParseResult,
  rng: Option(Range),
) -> BodyParseResult {
  BodyParseResult(..result, rng: rng)
}

pub fn set_timestamp(
  result: BodyParseResult,
  timestamp: Option(Timestamp),
) -> BodyParseResult {
  BodyParseResult(..result, timestamp: timestamp)
}

pub fn set_message(
  result: BodyParseResult,
  message: Option(String),
) -> BodyParseResult {
  BodyParseResult(..result, message: message)
}

pub fn set_addressee(
  result: BodyParseResult,
  addressee: Option(Addressee),
) -> BodyParseResult {
  BodyParseResult(..result, addressee: addressee)
}

pub fn set_message_id(
  result: BodyParseResult,
  message_id: Option(MessageId),
) -> BodyParseResult {
  BodyParseResult(..result, message_id: message_id)
}

pub fn set_message_ack(
  result: BodyParseResult,
  message_ack: Option(MessageId),
) -> BodyParseResult {
  BodyParseResult(..result, message_ack: message_ack)
}

pub fn set_message_reject(
  result: BodyParseResult,
  message_reject: Option(MessageId),
) -> BodyParseResult {
  BodyParseResult(..result, message_reject: message_reject)
}

pub fn set_weather(
  result: BodyParseResult,
  weather: Option(StrictWeatherData),
) -> BodyParseResult {
  BodyParseResult(..result, weather: weather)
}

pub fn set_object_name(
  result: BodyParseResult,
  object_name: Option(ObjectName),
) -> BodyParseResult {
  BodyParseResult(..result, object_name: object_name)
}

pub fn set_object_alive(
  result: BodyParseResult,
  object_alive: Option(Bool),
) -> BodyParseResult {
  BodyParseResult(..result, object_alive: object_alive)
}

pub fn set_item_name(
  result: BodyParseResult,
  item_name: Option(ObjectName),
) -> BodyParseResult {
  BodyParseResult(..result, item_name: item_name)
}

pub fn set_item_alive(
  result: BodyParseResult,
  item_alive: Option(Bool),
) -> BodyParseResult {
  BodyParseResult(..result, item_alive: item_alive)
}

pub fn set_telemetry(
  result: BodyParseResult,
  telemetry: Option(StrictTelemetryData),
) -> BodyParseResult {
  BodyParseResult(..result, telemetry: telemetry)
}