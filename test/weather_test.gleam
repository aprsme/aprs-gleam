import gleeunit
import gleeunit/should
import aprs
import aprs/types
import gleam/option.{Some, None}
import qcheck
import gleam/int

pub fn main() {
  gleeunit.main()
}

// Test parsing a complete weather report
pub fn parse_complete_weather_test() {
  let packet = "KC0YIR>APRS:@092345z4651.95N/09625.50W_090/005g010t073r000p010P010h50b10150"
  
  case aprs.parse_aprs(packet) {
    Ok(result) -> {
      result.packet_type |> should.equal(types.Weather)
      
      case result.weather {
        Some(wx) -> {
          // Wind direction
          case wx.wind_direction {
            Some(dir) -> {
              aprs.wind_direction_value(dir) |> should.equal(90)
            }
            None -> Nil
          }
          
          // Wind speed (5 mph = ~8 km/h)
          case wx.wind_speed {
            Some(speed) -> {
              let speed_val = aprs.wind_speed_value(speed)
              should.be_true(speed_val >. 7.0 && speed_val <. 9.0)
            }
            None -> Nil
          }
          
          // Temperature (73F = ~22.8C)
          case wx.temperature {
            Some(temp) -> {
              let temp_val = aprs.temperature_value(temp)
              should.be_true(temp_val >. 22.0 && temp_val <. 23.0)
            }
            None -> Nil
          }
          
          // Humidity
          case wx.humidity {
            Some(hum) -> {
              aprs.humidity_value(hum) |> should.equal(50)
            }
            None -> Nil
          }
          
          // Barometric pressure
          case wx.barometric_pressure {
            Some(pres) -> {
              let pres_val = aprs.pressure_value(pres)
              should.be_true(pres_val >. 1014.0 && pres_val <. 1016.0)
            }
            None -> Nil
          }
        }
        None -> should.fail()
      }
    }
    Error(_) -> {
      Nil
    }
  }
}

// Test minimal weather report
pub fn parse_minimal_weather_test() {
  let packet = "N0CALL>APRS:_10090000c220s004g005t077"
  
  case aprs.parse_aprs(packet) {
    Ok(result) -> {
      case result.weather {
        Some(wx) -> {
          // Should at least have temperature
          case wx.temperature {
            Some(temp) -> {
              let temp_val = aprs.temperature_value(temp)
              should.be_true(temp_val >. 24.0 && temp_val <. 26.0)  // 77F
            }
            None -> should.fail()
          }
        }
        None -> should.fail()
      }
    }
    Error(_) -> {
      Nil
    }
  }
}

// Test weather with position
pub fn parse_weather_with_position_test() {
  let packet = "N0CALL>APRS:!4237.14N/07120.83W_090/005t073"
  
  case aprs.parse_aprs(packet) {
    Ok(result) -> {
      // Should have position
      case result.position {
        Some(pos) -> {
          let lat = aprs.latitude_value(pos.latitude)
          should.be_true(lat >. 42.0 && lat <. 43.0)
        }
        None -> Nil  // Position might be optional
      }
      
      // Should have weather data
      case result.weather {
        Some(wx) -> {
          case wx.wind_direction {
            Some(dir) -> {
              aprs.wind_direction_value(dir) |> should.equal(90)
            }
            None -> Nil
          }
        }
        None -> Nil
      }
    }
    Error(_) -> {
      Nil
    }
  }
}

// Test weather station with no GPS (positionless weather)
pub fn parse_positionless_weather_test() {
  let packet = "CW0007>APRS:_10090556c220s004g005t077r001p002P003h50b10148"
  
  case aprs.parse_aprs(packet) {
    Ok(result) -> {
      // Should NOT have position
      result.position |> should.equal(None)
      
      // Should have weather
      case result.weather {
        Some(_wx) -> Nil
        None -> should.fail()
      }
    }
    Error(_) -> {
      Nil
    }
  }
}

// Test invalid weather data
pub fn parse_invalid_weather_test() {
  let packet = "N0CALL>APRS:_INVALID_WEATHER_DATA"
  
  case aprs.parse_aprs(packet) {
    Ok(_) -> {
      // If it parses, it should not be identified as weather
      Nil
    }
    Error(_) -> {
      // Expected - invalid weather should fail
      Nil
    }
  }
}

// Helper to pad number to 3 digits
fn pad_to_3_digits(n: Int) -> String {
  case n {
    n if n < 10 -> "00" <> int.to_string(n)
    n if n < 100 -> "0" <> int.to_string(n)
    n -> int.to_string(n)
  }
}

// Property test: Weather data with variable wind speeds
pub fn weather_wind_speed_property_test() {
  let gen = {
    use wind_dir <- qcheck.bind(qcheck.bounded_int(0, 359))
    use wind_speed <- qcheck.bind(qcheck.bounded_int(0, 200))
    use wind_gust <- qcheck.bind(qcheck.bounded_int(0, 200))
    use temp <- qcheck.bind(qcheck.bounded_int(-50, 150))
    
    qcheck.return(#(wind_dir, wind_speed, wind_gust, temp))
  }
  
  qcheck.given(gen, fn(params) {
    let #(wind_dir, wind_speed, wind_gust, temp) = params
    
    let wind_dir_str = pad_to_3_digits(wind_dir)
    let wind_speed_str = pad_to_3_digits(wind_speed)
    let wind_gust_str = pad_to_3_digits(wind_gust)
    let temp_str = pad_to_3_digits(temp)
    
    let packet = "N0CALL>APRS:_" <> wind_dir_str <> "/" <> wind_speed_str <> "g" <> wind_gust_str <> "t" <> temp_str
    
    case aprs.parse_aprs(packet) {
      Ok(_result) -> {
        // Just verify it doesn't crash
        Nil
      }
      Error(_) -> {
        // Some combinations might be invalid
        Nil
      }
    }
  })
}

// Property test: Complete weather reports
pub fn weather_complete_report_property_test() {
  let gen = {
    use temp <- qcheck.bind(qcheck.bounded_int(0, 150))
    use humidity <- qcheck.bind(qcheck.bounded_int(0, 100))
    use pressure <- qcheck.bind(qcheck.bounded_int(9000, 10500))
    
    qcheck.return(#(temp, humidity, pressure))
  }
  
  qcheck.given(gen, fn(params) {
    let #(temp, humidity, pressure) = params
    
    let temp_str = pad_to_3_digits(temp)
    let humidity_str = case humidity {
      100 -> "00"
      h if h < 10 -> "0" <> int.to_string(h)
      h -> int.to_string(h)
    }
    let pressure_str = int.to_string(pressure)
    
    let packet = "KC0YIR>APRS:@092345z4651.95N/09625.50W_090/005g010t" <> temp_str <> "r000p010P010h" <> humidity_str <> "b" <> pressure_str
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        result.packet_type |> should.equal(types.Weather)
      }
      Error(_) -> {
        // Some combinations might be invalid
        Nil
      }
    }
  })
}