// Re-export types and functions from the modularized code
import aprs/types
import aprs/parser
import aprs/math

// Re-export parse function
pub fn parse_aprs(packet: String) {
  parser.parse_aprs(packet)
}

// Re-export type constructors
pub fn make_callsign(s: String) {
  types.make_callsign(s)
}

pub fn make_ssid(n: Int) {
  types.make_ssid(n)
}

pub fn make_latitude(f: Float) {
  types.make_latitude(f)
}

pub fn make_longitude(f: Float) {
  types.make_longitude(f)
}

pub fn make_altitude(f: Float) {
  types.make_altitude(f)
}

pub fn make_course(n: Int) {
  types.make_course(n)
}

pub fn make_speed(f: Float) {
  types.make_speed(f)
}

pub fn make_temperature(f: Float) {
  types.make_temperature(f)
}

pub fn make_wind_direction(n: Int) {
  types.make_wind_direction(n)
}

pub fn make_wind_speed(f: Float) {
  types.make_wind_speed(f)
}

pub fn make_humidity(n: Int) {
  types.make_humidity(n)
}

pub fn make_pressure(f: Float) {
  types.make_pressure(f)
}

pub fn make_rain_amount(f: Float) {
  types.make_rain_amount(f)
}

pub fn make_phg_value(n: Int) {
  types.make_phg_value(n)
}

pub fn make_range(f: Float) {
  types.make_range(f)
}

pub fn make_timestamp(n: Int) {
  types.make_timestamp(n)
}

pub fn make_symbol_table(s: String) {
  types.make_symbol_table(s)
}

pub fn make_symbol_code(s: String) {
  types.make_symbol_code(s)
}

pub fn make_object_name(s: String) {
  types.make_object_name(s)
}

pub fn make_addressee(s: String) {
  types.make_addressee(s)
}

pub fn make_message_id(s: String) {
  types.make_message_id(s)
}

pub fn make_dao_datum(s: String) {
  types.make_dao_datum(s)
}

// Re-export accessor functions
pub fn callsign_value(c: types.Callsign) {
  types.callsign_value(c)
}

pub fn ssid_value(s: types.Ssid) {
  types.ssid_value(s)
}

pub fn latitude_value(l: types.Latitude) {
  types.latitude_value(l)
}

pub fn longitude_value(l: types.Longitude) {
  types.longitude_value(l)
}

pub fn altitude_value(a: types.Altitude) {
  types.altitude_value(a)
}

pub fn course_value(c: types.Course) {
  types.course_value(c)
}

pub fn speed_value(s: types.Speed) {
  types.speed_value(s)
}

pub fn temperature_value(t: types.Temperature) {
  types.temperature_value(t)
}

pub fn wind_direction_value(w: types.WindDirection) {
  types.wind_direction_value(w)
}

pub fn wind_speed_value(w: types.WindSpeed) {
  types.wind_speed_value(w)
}

pub fn humidity_value(h: types.Humidity) {
  types.humidity_value(h)
}

pub fn pressure_value(p: types.Pressure) {
  types.pressure_value(p)
}

pub fn rain_amount_value(r: types.RainAmount) {
  types.rain_amount_value(r)
}

pub fn phg_value_value(p: types.PhgValue) {
  types.phg_value_value(p)
}

pub fn range_value(r: types.Range) {
  types.range_value(r)
}

pub fn timestamp_value(t: types.Timestamp) {
  types.timestamp_value(t)
}

pub fn symbol_table_value(st: types.SymbolTable) {
  types.symbol_table_value(st)
}

pub fn symbol_code_value(sc: types.SymbolCode) {
  types.symbol_code_value(sc)
}

pub fn object_name_value(o: types.ObjectName) {
  types.object_name_value(o)
}

pub fn addressee_value(a: types.Addressee) {
  types.addressee_value(a)
}

pub fn message_id_value(m: types.MessageId) {
  types.message_id_value(m)
}

pub fn dao_datum_value(d: types.DaoDatum) {
  types.dao_datum_value(d)
}

// Re-export math functions
pub fn sin(x: Float) {
  math.sin(x)
}

pub fn cos(x: Float) {
  math.cos(x)
}

pub fn atan2(y: Float, x: Float) {
  math.atan2(y, x)
}

pub fn atan(x: Float) {
  math.atan(x)
}

// Re-export types
pub type Callsign = types.Callsign
pub type Ssid = types.Ssid
pub type StationId = types.StationId
pub type Latitude = types.Latitude
pub type Longitude = types.Longitude
pub type Altitude = types.Altitude
pub type Course = types.Course
pub type Speed = types.Speed
pub type Temperature = types.Temperature
pub type WindDirection = types.WindDirection
pub type WindSpeed = types.WindSpeed
pub type Humidity = types.Humidity
pub type Pressure = types.Pressure
pub type RainAmount = types.RainAmount
pub type PhgValue = types.PhgValue
pub type Range = types.Range
pub type Timestamp = types.Timestamp
pub type SymbolTable = types.SymbolTable
pub type SymbolCode = types.SymbolCode
pub type ObjectName = types.ObjectName
pub type Addressee = types.Addressee
pub type MessageId = types.MessageId
pub type DaoDatum = types.DaoDatum
pub type StrictPosition = types.StrictPosition
pub type StrictWeatherData = types.StrictWeatherData
pub type StrictTelemetryData = types.StrictTelemetryData
pub type StrictPhgData = types.StrictPhgData
pub type ParseResult = types.ParseResult
pub type ParseError = types.ParseError
pub type PacketType = types.PacketType
pub type MiceMessage = types.MiceMessage
pub type BodyParseResult = types.BodyParseResult
pub type PositionExtensions = types.PositionExtensions
pub type PositionInfo = types.PositionInfo
pub type MiceLatitude = types.MiceLatitude
pub type MiceInformation = types.MiceInformation
pub type MessageContent = types.MessageContent
pub type SymbolInfo = types.SymbolInfo

