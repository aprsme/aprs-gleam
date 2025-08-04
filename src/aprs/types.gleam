import gleam/option.{type Option}
import gleam/string
import aprs/string_utils

pub opaque type Callsign {
  Callsign(String)
}

pub opaque type Ssid {
  Ssid(Int)
}

pub type StationId {
  StationId(callsign: Callsign, ssid: Option(Ssid))
}

pub opaque type Latitude {
  Latitude(Float)
}

pub opaque type Longitude {
  Longitude(Float)
}

pub opaque type Altitude {
  Altitude(Float)
}

pub opaque type Course {
  Course(Int)
}

pub opaque type Speed {
  Speed(Float)
}

pub opaque type Temperature {
  Temperature(Float)
}

pub opaque type WindDirection {
  WindDirection(Int)
}

pub opaque type WindSpeed {
  WindSpeed(Float)
}

pub opaque type Humidity {
  Humidity(Int)
}

pub opaque type Pressure {
  Pressure(Float)
}

pub opaque type RainAmount {
  RainAmount(Float)
}

pub opaque type PhgValue {
  PhgValue(Int)
}

pub opaque type Range {
  Range(Float)
}

pub opaque type Timestamp {
  Timestamp(Int)
}

pub opaque type SymbolTable {
  SymbolTable(String)
}

pub opaque type SymbolCode {
  SymbolCode(String)
}

pub opaque type ObjectName {
  ObjectName(String)
}

pub opaque type Addressee {
  Addressee(String)
}

pub opaque type MessageId {
  MessageId(String)
}

pub opaque type DaoDatum {
  DaoDatum(String)
}

pub fn make_callsign(s: String) -> Result(Callsign, String) {
  let upper = string.uppercase(s)
  let len = string.length(upper)
  case len >= 1 && len <= 9 && string_utils.is_alphanumeric(upper) {
    True -> Ok(Callsign(upper))
    False -> Error("Invalid callsign: must be 1-9 alphanumeric characters")
  }
}

pub fn make_ssid(n: Int) -> Result(Ssid, String) {
  case n >= 0 && n <= 15 {
    True -> Ok(Ssid(n))
    False -> Error("Invalid SSID: must be 0-15")
  }
}

pub fn make_latitude(f: Float) -> Result(Latitude, String) {
  case f >=. -90.0 && f <=. 90.0 {
    True -> Ok(Latitude(f))
    False -> Error("Invalid latitude: must be -90.0 to 90.0")
  }
}

pub fn make_longitude(f: Float) -> Result(Longitude, String) {
  case f >=. -180.0 && f <=. 180.0 {
    True -> Ok(Longitude(f))
    False -> Error("Invalid longitude: must be -180.0 to 180.0")
  }
}

pub fn make_altitude(f: Float) -> Result(Altitude, String) {
  Ok(Altitude(f))
}

pub fn make_course(n: Int) -> Result(Course, String) {
  case n >= 0 && n <= 359 {
    True -> Ok(Course(n))
    False -> Error("Invalid course: must be 0-359")
  }
}

pub fn make_speed(f: Float) -> Result(Speed, String) {
  case f >=. 0.0 {
    True -> Ok(Speed(f))
    False -> Error("Invalid speed: must be non-negative")
  }
}

pub fn make_temperature(f: Float) -> Result(Temperature, String) {
  Ok(Temperature(f))
}

pub fn make_wind_direction(n: Int) -> Result(WindDirection, String) {
  case n >= 0 && n <= 359 {
    True -> Ok(WindDirection(n))
    False -> Error("Invalid wind direction: must be 0-359")
  }
}

pub fn make_wind_speed(f: Float) -> Result(WindSpeed, String) {
  case f >=. 0.0 {
    True -> Ok(WindSpeed(f))
    False -> Error("Invalid wind speed: must be non-negative")
  }
}

pub fn make_humidity(n: Int) -> Result(Humidity, String) {
  case n >= 0 && n <= 100 {
    True -> Ok(Humidity(n))
    False -> Error("Invalid humidity: must be 0-100")
  }
}

pub fn make_pressure(f: Float) -> Result(Pressure, String) {
  case f >. 0.0 {
    True -> Ok(Pressure(f))
    False -> Error("Invalid pressure: must be positive")
  }
}

pub fn make_rain_amount(f: Float) -> Result(RainAmount, String) {
  case f >=. 0.0 {
    True -> Ok(RainAmount(f))
    False -> Error("Invalid rain amount: must be non-negative")
  }
}

pub fn make_phg_value(n: Int) -> Result(PhgValue, String) {
  case n >= 0 && n <= 9 {
    True -> Ok(PhgValue(n))
    False -> Error("Invalid PHG value: must be 0-9")
  }
}

pub fn make_range(f: Float) -> Result(Range, String) {
  case f >=. 0.0 {
    True -> Ok(Range(f))
    False -> Error("Invalid range: must be non-negative")
  }
}

pub fn make_timestamp(n: Int) -> Result(Timestamp, String) {
  case n >= 0 {
    True -> Ok(Timestamp(n))
    False -> Error("Invalid timestamp: must be non-negative")
  }
}

pub fn make_symbol_table(s: String) -> Result(SymbolTable, String) {
  case string.length(s) == 1 {
    True -> Ok(SymbolTable(s))
    False -> Error("Invalid symbol table: must be single character")
  }
}

pub fn make_symbol_code(s: String) -> Result(SymbolCode, String) {
  case string.length(s) == 1 {
    True -> Ok(SymbolCode(s))
    False -> Error("Invalid symbol code: must be single character")
  }
}

pub fn make_object_name(s: String) -> Result(ObjectName, String) {
  let len = string.length(s)
  case len >= 3 && len <= 9 {
    True -> Ok(ObjectName(s))
    False -> Error("Invalid object name: must be 3-9 characters")
  }
}

pub fn make_addressee(s: String) -> Result(Addressee, String) {
  case string.length(s) == 9 {
    True -> Ok(Addressee(s))
    False -> Error("Invalid addressee: must be exactly 9 characters")
  }
}

pub fn make_message_id(s: String) -> Result(MessageId, String) {
  let len = string.length(s)
  case len >= 1 && len <= 5 && string_utils.is_alphanumeric(s) {
    True -> Ok(MessageId(s))
    False -> Error("Invalid message ID: must be 1-5 alphanumeric characters")
  }
}

pub fn make_dao_datum(s: String) -> Result(DaoDatum, String) {
  case string.length(s) == 1 {
    True -> Ok(DaoDatum(s))
    False -> Error("Invalid DAO datum: must be single character")
  }
}

pub fn callsign_value(c: Callsign) -> String {
  let Callsign(s) = c
  s
}

pub fn ssid_value(s: Ssid) -> Int {
  let Ssid(n) = s
  n
}

pub fn latitude_value(l: Latitude) -> Float {
  let Latitude(f) = l
  f
}

pub fn longitude_value(l: Longitude) -> Float {
  let Longitude(f) = l
  f
}

pub fn altitude_value(a: Altitude) -> Float {
  let Altitude(f) = a
  f
}

pub fn course_value(c: Course) -> Int {
  let Course(n) = c
  n
}

pub fn speed_value(s: Speed) -> Float {
  let Speed(f) = s
  f
}

pub fn temperature_value(t: Temperature) -> Float {
  let Temperature(f) = t
  f
}

pub fn wind_direction_value(w: WindDirection) -> Int {
  let WindDirection(n) = w
  n
}

pub fn wind_speed_value(w: WindSpeed) -> Float {
  let WindSpeed(f) = w
  f
}

pub fn humidity_value(h: Humidity) -> Int {
  let Humidity(n) = h
  n
}

pub fn pressure_value(p: Pressure) -> Float {
  let Pressure(f) = p
  f
}

pub fn rain_amount_value(r: RainAmount) -> Float {
  let RainAmount(f) = r
  f
}

pub fn phg_value_value(p: PhgValue) -> Int {
  let PhgValue(n) = p
  n
}

pub fn range_value(r: Range) -> Float {
  let Range(f) = r
  f
}

pub fn timestamp_value(t: Timestamp) -> Int {
  let Timestamp(n) = t
  n
}

pub fn symbol_table_value(st: SymbolTable) -> String {
  let SymbolTable(s) = st
  s
}

pub fn symbol_code_value(sc: SymbolCode) -> String {
  let SymbolCode(s) = sc
  s
}

pub fn object_name_value(o: ObjectName) -> String {
  let ObjectName(s) = o
  s
}

pub fn addressee_value(a: Addressee) -> String {
  let Addressee(s) = a
  s
}

pub fn message_id_value(m: MessageId) -> String {
  let MessageId(s) = m
  s
}

pub fn dao_datum_value(d: DaoDatum) -> String {
  let DaoDatum(s) = d
  s
}

pub type StrictPosition {
  StrictPosition(
    latitude: Latitude,
    longitude: Longitude,
    ambiguity: Int,
    altitude: Option(Altitude),
  )
}

pub type StrictWeatherData {
  StrictWeatherData(
    wind_direction: Option(WindDirection),
    wind_speed: Option(WindSpeed),
    wind_gust: Option(WindSpeed),
    temperature: Option(Temperature),
    rain_1h: Option(RainAmount),
    rain_24h: Option(RainAmount),
    rain_since_midnight: Option(RainAmount),
    humidity: Option(Humidity),
    barometric_pressure: Option(Pressure),
  )
}

pub type StrictTelemetryData {
  StrictTelemetryData(sequence: Int, analog: List(Float), digital: List(Bool))
}

pub type StrictPhgData {
  StrictPhgData(
    power: PhgValue,
    height: PhgValue,
    gain: PhgValue,
    directivity: PhgValue,
  )
}

pub type ParseResult {
  ParseResult(
    source: StationId,
    destination: StationId,
    digipeaters: List(StationId),
    packet_type: PacketType,
    position: Option(StrictPosition),
    message: Option(String),
    symbol_table: Option(SymbolTable),
    symbol_code: Option(SymbolCode),
    timestamp: Option(Timestamp),
    weather: Option(StrictWeatherData),
    telemetry: Option(StrictTelemetryData),
    comment: Option(String),
    course: Option(Course),
    speed: Option(Speed),
    altitude: Option(Altitude),
    mic_e_message: Option(String),
    dao_datum: Option(DaoDatum),
    dao_precision: Option(#(Float, Float)),
    phg: Option(StrictPhgData),
    rng: Option(Range),
    object_name: Option(ObjectName),
    object_alive: Option(Bool),
    item_name: Option(ObjectName),
    item_alive: Option(Bool),
    addressee: Option(Addressee),
    message_id: Option(MessageId),
    message_ack: Option(MessageId),
    message_reject: Option(MessageId),
    status: Option(String),
  )
}

pub type PacketType {
  PositionPacket
  MicE
  Compressed
  Object
  Item
  Message
  Weather
  Telemetry
  Status
  NmeaGprmc
  NmeaGpgga
  NmeaGpgll
  DxSpot
  UnknownPacket
}

pub type MiceMessage {
  Emergency
  Priority
  Special
  Committed
  Custom1
  Custom2
  Custom3
  Custom4
  Custom5
  Custom6
  Unknown
}

pub type ParseError {
  PacketTooShort
  NoPacketGiven
  NoBody
  InvalidSourceCall
  InvalidDestinationCall
  InvalidDigipeaterCall
  InvalidTimestamp
  InvalidPosition
  InvalidCompressed
  InvalidMicE
  InvalidMessage
  UnsupportedFormat
  TooManyDigipeaters
}

pub type BodyParseResult {
  BodyParseResult(
    packet_type: PacketType,
    position: Option(StrictPosition),
    message: Option(String),
    symbol_table: Option(SymbolTable),
    symbol_code: Option(SymbolCode),
    timestamp: Option(Timestamp),
    weather: Option(StrictWeatherData),
    telemetry: Option(StrictTelemetryData),
    comment: Option(String),
    course: Option(Course),
    speed: Option(Speed),
    altitude: Option(Altitude),
    mic_e_message: Option(String),
    dao_datum: Option(DaoDatum),
    dao_precision: Option(#(Float, Float)),
    phg: Option(StrictPhgData),
    rng: Option(Range),
    object_name: Option(ObjectName),
    object_alive: Option(Bool),
    item_name: Option(ObjectName),
    item_alive: Option(Bool),
    addressee: Option(Addressee),
    message_id: Option(MessageId),
    message_ack: Option(MessageId),
    message_reject: Option(MessageId),
    status: Option(String),
  )
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

pub type PositionInfo {
  PositionInfo(
    position: StrictPosition,
    symbol_table: SymbolTable,
    symbol_code: SymbolCode,
  )
}

pub type MiceLatitude {
  MiceLatitude(
    latitude: Float,
    ambiguity: Int,
    north_south: String,
    east_west: String,
  )
}

pub type MiceInformation {
  MiceInformation(
    longitude: Float,
    course: Option(Int),
    speed: Option(Float),
    symbol_table: String,
    symbol_code: String,
    altitude: Option(Float),
    comment: Option(String),
  )
}

pub type MessageContent {
  MessageContent(
    message: String,
    message_id: Option(String),
    is_ack: Bool,
    is_reject: Bool,
  )
}

pub type SymbolInfo {
  SymbolInfo(symbol: String, description: String, category: String)
}

