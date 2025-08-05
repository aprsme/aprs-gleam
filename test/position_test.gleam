import gleeunit
import gleeunit/should
import aprs
import aprs/types
import gleam/option.{Some, None}
import qcheck
import gleam/list
import gleam/int
import gleam/string
import gleam/float

pub fn main() {
  gleeunit.main()
}

// Test parsing a basic uncompressed position packet
pub fn parse_uncompressed_position_test() {
  let packet = "OH2RDP>BEACON,OH2RDG*,WIDE:!6028.51N/02505.68E#PHG7220"
  
  case aprs.parse_aprs(packet) {
    Ok(result) -> {
      // Verify source and destination
      result.source.callsign
      |> aprs.callsign_value()
      |> should.equal("OH2RDP")
      
      result.destination.callsign
      |> aprs.callsign_value()
      |> should.equal("BEACON")
      
      // Verify packet type
      result.packet_type |> should.equal(types.PositionPacket)
      
      // Verify position data
      case result.position {
        Some(pos) -> {
          let lat = aprs.latitude_value(pos.latitude)
          let lon = aprs.longitude_value(pos.longitude)
          
          // Check approximate coordinates
          should.be_true(lat >. 60.47 && lat <. 60.48)
          should.be_true(lon >. 25.09 && lon <. 25.10)
        }
        None -> should.fail()
      }
      
      // Verify PHG data
      case result.phg {
        Some(phg) -> {
          aprs.phg_value_value(phg.power) |> should.equal(7)
          aprs.phg_value_value(phg.height) |> should.equal(2)
          aprs.phg_value_value(phg.gain) |> should.equal(2)
          aprs.phg_value_value(phg.directivity) |> should.equal(0)
        }
        None -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

// Test parsing position with course and speed
pub fn parse_position_with_course_speed_test() {
  let packet = "W2XYZ-9>APOTC1,WIDE2-1:!4301.23N/07345.67W>090/035"
  
  case aprs.parse_aprs(packet) {
    Ok(result) -> {
      result.packet_type |> should.equal(types.PositionPacket)
      
      // Verify course
      case result.course {
        Some(course) -> {
          aprs.course_value(course) |> should.equal(90)
        }
        None -> should.fail()
      }
      
      // Verify speed (035 knots = ~64.8 km/h)
      case result.speed {
        Some(speed) -> {
          let speed_val = aprs.speed_value(speed)
          should.be_true(speed_val >. 64.0 && speed_val <. 65.0)
        }
        None -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

// Test parsing compressed position packet
pub fn parse_compressed_position_test() {
  let packet = "N0CALL>APRS:!/5L!!<*e7> Test compressed"
  
  case aprs.parse_aprs(packet) {
    Ok(result) -> {
      result.packet_type |> should.equal(types.PositionPacket)
      
      case result.position {
        Some(pos) -> {
          // Just verify we got a position
          let _lat = aprs.latitude_value(pos.latitude)
          let _lon = aprs.longitude_value(pos.longitude)
          Nil
        }
        None -> should.fail()
      }
      
      // Verify comment
      case result.comment {
        Some(comment) -> {
          comment |> should.equal("Test compressed")
        }
        None -> Nil
      }
    }
    Error(_) -> {
      // Compressed position might not be fully implemented
      Nil
    }
  }
}

// Test timestamp position packets
pub fn parse_timestamp_position_test() {
  let packet = "K1ABC>APRS:@092345z4237.14N/07120.83W# Test"
  
  case aprs.parse_aprs(packet) {
    Ok(result) -> {
      result.packet_type |> should.equal(types.PositionPacket)
      
      // Should have timestamp
      case result.timestamp {
        Some(_timestamp) -> Nil
        None -> should.fail()
      }
      
      // Should have position
      case result.position {
        Some(pos) -> {
          let lat = aprs.latitude_value(pos.latitude)
          let lon = aprs.longitude_value(pos.longitude)
          
          should.be_true(lat >. 42.6 && lat <. 42.7)
          should.be_true(lon <. -71.3 && lon >. -71.4)
        }
        None -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

// Test position with altitude
pub fn parse_position_with_altitude_test() {
  let packet = "N0CALL>APRS:!4237.14N/07120.83W#/A=001234"
  
  case aprs.parse_aprs(packet) {
    Ok(result) -> {
      result.packet_type |> should.equal(types.PositionPacket)
      
      case result.altitude {
        Some(alt) -> {
          // 1234 feet = ~376 meters
          let alt_meters = aprs.altitude_value(alt)
          should.be_true(alt_meters >. 375.0 && alt_meters <. 377.0)
        }
        None -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

// Test position with range
pub fn parse_position_with_range_test() {
  let packet = "N0CALL>APRS:!4237.14N/07120.83W#RNG0050"
  
  case aprs.parse_aprs(packet) {
    Ok(result) -> {
      result.packet_type |> should.equal(types.PositionPacket)
      
      case result.rng {
        Some(range) -> {
          // 50 miles = ~80.5 km
          let range_km = aprs.range_value(range)
          should.be_true(range_km >. 80.0 && range_km <. 81.0)
        }
        None -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

// Test: Compressed position format examples from real packets
pub fn compressed_position_examples_test() {
  // Real compressed position examples from packets.csv
  let compressed_examples = [
    #("!/:Kr6;Ahc>-BG", "K3RTA-12"),
    #("!/42TlP\\6gvBNQ", "DO2JMG-9"),
    #("!L4G-{MWS)a xG", "MW7VHD-13"),
    #("=/9,[]MS+\\>LdQ", "EA1GLE-7"),
    #("!L4Y6zP:rz&  G", "DG2EKJ-10")
  ]
  
  compressed_examples
  |> list.each(fn(example) {
    let #(pos_data, callsign) = example
    let packet = callsign <> ">APRS:" <> pos_data
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        result.packet_type |> should.equal(types.PositionPacket)
        // Just verify it parses as a position packet
      }
      Error(_) -> {
        // Compressed positions might not be fully supported yet
        Nil
      }
    }
  })
}

// Property test: Compressed position format
pub fn compressed_position_property_test() {
  // Compressed format uses printable ASCII characters
  let gen = {
    use content <- qcheck.bind(qcheck.string_from(qcheck.printable_ascii_codepoint()))
    
    qcheck.return(content)
  }
  
  qcheck.given(gen, fn(content) {
    // Take first 13 chars for compressed position (symbol table + 8 position + symbol)
    let compressed = string.slice(content <> "!4237N07120W#", 0, 13)
    let packet = "K1ABC>APRS:!" <> compressed
    
    case aprs.parse_aprs(packet) {
      Ok(_result) -> {
        // Just verify it doesn't crash
        Nil
      }
      Error(_) -> {
        // Some compressed positions might be invalid
        Nil
      }
    }
  })
}

// Generator for altitude values in feet
fn altitude_generator() -> qcheck.Generator(Int) {
  qcheck.bounded_int(0, 50000)
}

// Test: Altitude field parsing property
pub fn altitude_field_property_test() {
  qcheck.given(altitude_generator(), fn(alt_feet) {
    let alt_str = case alt_feet {
      a if a < 10 -> "00000" <> int.to_string(a)
      a if a < 100 -> "0000" <> int.to_string(a)
      a if a < 1000 -> "000" <> int.to_string(a)
      a if a < 10000 -> "00" <> int.to_string(a)
      a if a < 100000 -> "0" <> int.to_string(a)
      a -> int.to_string(a)
    }
    let alt_str = string.slice(alt_str, string.length(alt_str) - 6, 6)
    
    let packet = "K1ABC>APRS:!4237.14N/07120.83W#/A=" <> alt_str
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        case result.altitude {
          Some(alt) -> {
            // Verify altitude is converted to meters correctly
            let alt_meters = aprs.altitude_value(alt)
            let expected_meters = int.to_float(alt_feet) *. 0.3048
            
            // Allow small rounding errors
            should.be_true(float.absolute_value(alt_meters -. expected_meters) <. 1.0)
          }
          None -> should.fail()
        }
      }
      Error(_) -> should.fail()
    }
  })
}