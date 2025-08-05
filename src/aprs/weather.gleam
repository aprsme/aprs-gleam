import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/string
import gleam/list
import aprs/utils
import aprs/types.{
  type Humidity, type Pressure, type RainAmount, type StrictWeatherData,
  type Temperature, type WindDirection, type WindSpeed,
  StrictWeatherData, make_humidity, make_pressure, make_rain_amount,
  make_temperature, make_wind_direction, make_wind_speed,
}

type WeatherParser {
  WeatherParser(
    prefix: String,
    length: Int,
    field_name: String,
  )
}

type WeatherParseState {
  WeatherParseState(
    remaining_data: String,
    parsed_values: List(#(String, Option(String))),
  )
}

fn weather_parsers() -> List(WeatherParser) {
  [
    WeatherParser("c", 3, "wind_direction"),
    WeatherParser("s", 3, "wind_speed"),
    WeatherParser("g", 3, "wind_gust"),
    WeatherParser("t", 3, "temperature"),
    WeatherParser("r", 3, "rain_1h"),
    WeatherParser("p", 3, "rain_24h"),
    WeatherParser("P", 3, "rain_midnight"),
    WeatherParser("h", 2, "humidity"),
    WeatherParser("b", 5, "pressure"),
  ]
}

fn apply_parser(
  state state: WeatherParseState,
  parser parser: WeatherParser,
) -> WeatherParseState {
  let #(value, rest) = parse_weather_field(
    state.remaining_data,
    parser.prefix,
    parser.length,
  )
  
  WeatherParseState(
    remaining_data: rest,
    parsed_values: list.append(state.parsed_values, [#(parser.field_name, value)]),
  )
}

fn find_parsed_value(
  values values: List(#(String, Option(String))),
  field field: String,
) -> Option(String) {
  case list.find(values, fn(pair) { pair.0 == field }) {
    Ok(#(_, value)) -> value
    Error(_) -> None
  }
}

pub fn parse_weather_elements(data: String) -> StrictWeatherData {
  let initial_state = WeatherParseState(data, [])
  
  let final_state = 
    list.fold(weather_parsers(), initial_state, apply_parser)
  
  let values = final_state.parsed_values
  
  StrictWeatherData(
    wind_direction: find_parsed_value(values, "wind_direction") |> parse_wind_direction,
    wind_speed: find_parsed_value(values, "wind_speed") |> parse_wind_speed,
    wind_gust: find_parsed_value(values, "wind_gust") |> parse_wind_speed,
    temperature: find_parsed_value(values, "temperature") |> parse_temperature,
    rain_1h: find_parsed_value(values, "rain_1h") |> parse_rain,
    rain_24h: find_parsed_value(values, "rain_24h") |> parse_rain,
    rain_since_midnight: find_parsed_value(values, "rain_midnight") |> parse_rain,
    humidity: find_parsed_value(values, "humidity") |> parse_humidity,
    barometric_pressure: find_parsed_value(values, "pressure") |> parse_pressure,
  )
}

fn parse_wind_direction(dir_opt: Option(String)) -> Option(WindDirection) {
  dir_opt
  |> utils.option_then(fn(s) {
    case int.parse(s) {
      Ok(dir) if dir >= 0 && dir <= 360 -> Some(dir)
      _ -> None
    }
  })
  |> utils.option_try_map(make_wind_direction)
}

fn parse_wind_speed(speed_opt: Option(String)) -> Option(WindSpeed) {
  speed_opt
  |> utils.option_then(fn(s) { int.parse(s) |> utils.result_to_option })
  |> option.map(fn(speed) { int.to_float(speed) *. 1.60934 })
  |> utils.option_try_map(make_wind_speed)
}

fn parse_temperature(temp_opt: Option(String)) -> Option(Temperature) {
  temp_opt
  |> utils.option_then(fn(s) { int.parse(s) |> utils.result_to_option })
  |> option.map(fn(temp_f) { { int.to_float(temp_f) -. 32.0 } *. 5.0 /. 9.0 })
  |> utils.option_try_map(make_temperature)
}

fn parse_rain(rain_opt: Option(String)) -> Option(RainAmount) {
  rain_opt
  |> utils.option_then(fn(s) { int.parse(s) |> utils.result_to_option })
  |> option.map(fn(rain) { int.to_float(rain) *. 0.254 })
  |> utils.option_try_map(make_rain_amount)
}

fn parse_humidity(hum_opt: Option(String)) -> Option(Humidity) {
  hum_opt
  |> utils.option_then(fn(s) {
    case int.parse(s) {
      Ok(hum) if hum >= 0 && hum <= 100 -> Some(hum)
      _ -> None
    }
  })
  |> utils.option_try_map(make_humidity)
}

fn parse_pressure(pres_opt: Option(String)) -> Option(Pressure) {
  pres_opt
  |> utils.option_then(fn(s) { int.parse(s) |> utils.result_to_option })
  |> option.map(fn(pres) { int.to_float(pres) /. 10.0 })
  |> utils.option_try_map(make_pressure)
}

pub fn parse_weather_field(data data: String, prefix prefix: String, length length: Int) -> #(Option(String), String) {
  case string.starts_with(data, prefix) && string.length(data) > length {
    True -> {
      let value = string.slice(data, 1, length)
      let rest = string.slice(data, 1 + length, string.length(data) - 1 - length)
      #(Some(value), rest)
    }
    False -> #(None, data)
  }
}