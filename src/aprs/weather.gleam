import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/string
import aprs/types.{
  type Humidity, type Pressure, type RainAmount, type StrictWeatherData,
  type Temperature, type WindDirection, type WindSpeed,
  StrictWeatherData, make_humidity, make_pressure, make_rain_amount,
  make_temperature, make_wind_direction, make_wind_speed,
}

pub fn parse_weather_elements(data: String) -> StrictWeatherData {
  let #(wind_dir, rest1) = parse_weather_field(data, "c", 3)
  let #(wind_speed, rest2) = parse_weather_field(rest1, "s", 3)
  let #(wind_gust, rest3) = parse_weather_field(rest2, "g", 3)
  let #(temp, rest4) = parse_weather_field(rest3, "t", 3)
  let #(rain_1h, rest5) = parse_weather_field(rest4, "r", 3)
  let #(rain_24h, rest6) = parse_weather_field(rest5, "p", 3)
  let #(rain_midnight, rest7) = parse_weather_field(rest6, "P", 3)
  let #(humidity, rest8) = parse_weather_field(rest7, "h", 2)
  let #(pressure, _rest9) = parse_weather_field(rest8, "b", 5)
  
  StrictWeatherData(
    wind_direction: parse_wind_direction(wind_dir),
    wind_speed: parse_wind_speed(wind_speed),
    wind_gust: parse_wind_speed(wind_gust),
    temperature: parse_temperature(temp),
    rain_1h: parse_rain(rain_1h),
    rain_24h: parse_rain(rain_24h),
    rain_since_midnight: parse_rain(rain_midnight),
    humidity: parse_humidity(humidity),
    barometric_pressure: parse_pressure(pressure),
  )
}

fn parse_wind_direction(dir_opt: Option(String)) -> Option(WindDirection) {
  case dir_opt {
    None -> None
    Some(d) -> case int.parse(d) {
      Ok(dir) if dir >= 0 && dir <= 360 -> 
        case make_wind_direction(dir) {
          Ok(wd) -> Some(wd)
          Error(_) -> None
        }
      _ -> None
    }
  }
}

fn parse_wind_speed(speed_opt: Option(String)) -> Option(WindSpeed) {
  case speed_opt {
    None -> None
    Some(s) -> case int.parse(s) {
      Ok(speed) -> 
        case make_wind_speed(int.to_float(speed) *. 1.60934) {
          Ok(ws) -> Some(ws)
          Error(_) -> None
        }
      _ -> None
    }
  }
}

fn parse_temperature(temp_opt: Option(String)) -> Option(Temperature) {
  case temp_opt {
    None -> None
    Some(t) -> case int.parse(t) {
      Ok(temp_f) -> {
        let temp_c = { int.to_float(temp_f) -. 32.0 } *. 5.0 /. 9.0
        case make_temperature(temp_c) {
          Ok(temp_val) -> Some(temp_val)
          Error(_) -> None
        }
      }
      _ -> None
    }
  }
}

fn parse_rain(rain_opt: Option(String)) -> Option(RainAmount) {
  case rain_opt {
    None -> None
    Some(r) -> case int.parse(r) {
      Ok(rain) -> 
        case make_rain_amount(int.to_float(rain) *. 0.254) {
          Ok(r_val) -> Some(r_val)
          Error(_) -> None
        }
      _ -> None
    }
  }
}

fn parse_humidity(hum_opt: Option(String)) -> Option(Humidity) {
  case hum_opt {
    None -> None
    Some(h) -> case int.parse(h) {
      Ok(hum) if hum >= 0 && hum <= 100 -> 
        case make_humidity(hum) {
          Ok(hum_val) -> Some(hum_val)
          Error(_) -> None
        }
      _ -> None
    }
  }
}

fn parse_pressure(pres_opt: Option(String)) -> Option(Pressure) {
  case pres_opt {
    None -> None
    Some(p) -> case int.parse(p) {
      Ok(pres) -> 
        case make_pressure(int.to_float(pres) /. 10.0) {
          Ok(pres_val) -> Some(pres_val)
          Error(_) -> None
        }
      _ -> None
    }
  }
}

pub fn parse_weather_field(data: String, prefix: String, length: Int) -> #(Option(String), String) {
  case string.starts_with(data, prefix) && string.length(data) > length {
    True -> {
      let value = string.slice(data, 1, length)
      let rest = string.slice(data, 1 + length, string.length(data) - 1 - length)
      #(Some(value), rest)
    }
    False -> #(None, data)
  }
}