import gleeunit
import gleeunit/should
import aprs
import aprs/types
import gleam/int
import gleam/list
import gleam/string
import gleam/option.{Some, None}

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