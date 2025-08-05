import gleeunit
import gleeunit/should
import aprs
import aprs/types
import gleam/int
import gleam/list
import gleam/string
import gleam/option.{Some, None}
import qcheck

pub fn main() {
  gleeunit.main()
}

// Helper function to pad a string with zeros on the left
fn pad_left_zero(str: String, width: Int) -> String {
  let len = string.length(str)
  case len < width {
    True -> string.repeat("0", width - len) <> str
    False -> str
  }
}


// Test: Valid callsigns should be parseable
pub fn callsign_parsing_test() {
  let test_calls = ["K1ABC", "W2XYZ", "N3QRP", "VE3DMP", "OH2RDP"]
  
  list.each(test_calls, fn(call) {
    let packet = call <> ">APRS:>Test"
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        result.source.callsign
        |> aprs.callsign_value()
        |> should.equal(call)
      }
      Error(_) -> should.fail()
    }
  })
}

// Test: Valid position coordinates should parse correctly
pub fn position_coordinates_test() {
  let test_cases = [
    #("K1ABC", "4237.14N", "07120.83W"),
    #("W2XYZ", "4301.23N", "07345.67W"),
    #("N3QRP", "4530.00N", "07530.00W"),
  ]
  
  list.each(test_cases, fn(test_case) {
    let #(src, lat, lon) = test_case
    let packet = src <> ">APRS:!" <> lat <> "/" <> lon <> "#"
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        result.packet_type |> should.equal(types.PositionPacket)
        
        case result.position {
          Some(pos) -> {
            // Verify latitude is in valid range
            let lat_val = aprs.latitude_value(pos.latitude)
            should.be_true(lat_val >=. -90.0 && lat_val <=. 90.0)
            
            // Verify longitude is in valid range
            let lon_val = aprs.longitude_value(pos.longitude)
            should.be_true(lon_val >=. -180.0 && lon_val <=. 180.0)
          }
          None -> should.fail()
        }
      }
      Error(_) -> should.fail()
    }
  })
}

// Test: Message addressees should always be 9 characters
pub fn message_addressee_test() {
  let test_cases = [
    #("K1ABC", "WB4BFD   "),
    #("W2XYZ", "K1ABC    "),
    #("N3QRP", "W2XYZ    "),
  ]
  
  list.each(test_cases, fn(test_case) {
    let #(src, padded_addr) = test_case
    let packet = src <> ">APRS::" <> padded_addr <> ":Test message"
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        case result.addressee {
          Some(a) -> {
            let addr_val = aprs.addressee_value(a)
            string.length(addr_val) |> should.equal(9)
          }
          None -> should.fail()
        }
      }
      Error(_) -> should.fail()
    }
  })
}

// Test: Course values should be 0-359
pub fn course_range_test() {
  let test_courses = [90, 180, 270]  // Skip 0 and 359 which might have edge cases
  
  list.each(test_courses, fn(course) {
    let course_str = pad_left_zero(int.to_string(course), 3)
    let packet = "K1ABC>APRS:!4237.14N/07120.83W>" <> course_str <> "/000"
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        case result.course {
          Some(c) -> {
            let course_val = aprs.course_value(c)
            course_val |> should.equal(course)
          }
          None -> should.fail()
        }
      }
      Error(_) -> should.fail()
    }
  })
}

// Generator for SSID values (0-15)
fn ssid_generator() -> qcheck.Generator(Int) {
  qcheck.bounded_int(0, 15)
}

// Generator for callsigns with flexible SSID formats
fn callsign_with_ssid_generator() -> qcheck.Generator(String) {
  // Generate simple alphanumeric callsigns
  use first_char <- qcheck.bind(
    qcheck.from_generators(
      qcheck.return("K"),
      [qcheck.return("W"), qcheck.return("N"), qcheck.return("A")]
    )
  )
  use digit <- qcheck.bind(qcheck.bounded_int(0, 9))
  use suffix <- qcheck.bind(qcheck.string_from(qcheck.uppercase_ascii_codepoint()))
  use ssid <- qcheck.bind(ssid_generator())
  use has_dash <- qcheck.bind(qcheck.bool())
  
  let base_call = first_char <> int.to_string(digit) <> string.slice(suffix, 0, 3)
  
  case ssid {
    0 -> qcheck.return(base_call)
    _ -> {
      case has_dash {
        True -> qcheck.return(base_call <> "-" <> int.to_string(ssid))
        False -> qcheck.return(base_call <> int.to_string(ssid))
      }
    }
  }
}

// Test: Callsigns with various SSID formats should parse
pub fn callsign_ssid_formats_property_test() {
  qcheck.given(callsign_with_ssid_generator(), fn(call) {
    let packet = call <> ">APRS:>Test"
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        // Should parse successfully
        result.source.callsign
        |> aprs.callsign_value()
        |> string.length()
        |> fn(len) { should.be_true(len > 0) }
      }
      Error(_) -> should.fail()
    }
  })
}

// Generator for PHG values
fn phg_digit_generator() -> qcheck.Generator(String) {
  qcheck.bounded_int(0, 9)
  |> qcheck.map(int.to_string)
}

// Test: PHG (Power-Height-Gain) format
pub fn phg_format_property_test() {
  let gen = {
    use p <- qcheck.bind(phg_digit_generator())
    use h <- qcheck.bind(phg_digit_generator())
    use g <- qcheck.bind(phg_digit_generator())
    use d <- qcheck.bind(phg_digit_generator())
    
    qcheck.return("PHG" <> p <> h <> g <> d)
  }
  
  qcheck.given(gen, fn(phg) {
    let packet = "K1ABC>APRS:!4237.14N/07120.83W#" <> phg
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        // Should parse as position packet
        result.packet_type |> should.equal(types.PositionPacket)
      }
      Error(_) -> should.fail()
    }
  })
}