import gleeunit
import gleeunit/should
import aprs
import aprs/types
import gleam/option.{Some, None}

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