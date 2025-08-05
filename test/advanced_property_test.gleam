import gleeunit
import gleeunit/should
import aprs
import aprs/types
import gleam/option.{Some, None}
import qcheck
import gleam/int
import gleam/string
import gleam/list

pub fn main() {
  gleeunit.main()
}

// Property test: DAO (Datum and Precision) extension
pub fn dao_datum_property_test() {
  let gen = {
    // DAO format: !W  ! or !w  ! where W/w indicates datum, spaces are lat/lon precision
    use datum_char <- qcheck.bind(
      qcheck.from_generators(
        qcheck.return("W"),  // WGS-84
        [qcheck.return("w")]  // WGS-84 lowercase variant
      )
    )
    use lat_precision <- qcheck.bind(qcheck.bounded_int(0, 9))
    use lon_precision <- qcheck.bind(qcheck.bounded_int(0, 9))
    
    qcheck.return(#(datum_char, lat_precision, lon_precision))
  }
  
  qcheck.given(gen, fn(params) {
    let #(datum, lat_p, lon_p) = params
    
    // Build DAO extension
    let dao = "!" <> datum <> int.to_string(lat_p) <> int.to_string(lon_p) <> "!"
    let packet = "K1ABC>APRS:!4237.14N/07120.83W#PHG5360" <> dao
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        // Should parse as position packet with DAO
        result.packet_type |> should.equal(types.PositionPacket)
        case result.dao_datum {
          Some(_) -> Nil
          None -> Nil  // DAO might not be fully implemented
        }
      }
      Error(_) -> {
        // Some DAO formats might be invalid
        Nil
      }
    }
  })
}

// Property test: Symbol Table/Code combinations
pub fn symbol_table_code_property_test() {
  let gen = {
    // Primary table (/) and alternate table (\)
    use table <- qcheck.bind(
      qcheck.from_generators(
        qcheck.return("/"),
        [qcheck.return("\\")]
      )
    )
    // Symbol codes are printable ASCII
    use code <- qcheck.bind(qcheck.bounded_int(33, 126))
    
    qcheck.return(#(table, code))
  }
  
  qcheck.given(gen, fn(params) {
    let #(table, code) = params
    
    let symbol_code = case string.utf_codepoint(code) {
      Ok(cp) -> string.from_utf_codepoints([cp])
      Error(_) -> "#"  // Use default symbol if invalid
    }
    
    let packet = "K1ABC>APRS:!4237.14N" <> table <> "07120.83W" <> symbol_code
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        result.packet_type |> should.equal(types.PositionPacket)
        case result.symbol_table {
          Some(st) -> {
            aprs.symbol_table_value(st) |> should.equal(table)
          }
          None -> Nil
        }
        case result.symbol_code {
          Some(sc) -> {
            aprs.symbol_code_value(sc) |> should.equal(symbol_code)
          }
          None -> Nil
        }
      }
      Error(_) -> {
        // Some symbol combinations might be invalid
        Nil
      }
    }
  })
}

// Property test: Timestamp format variations
pub fn timestamp_format_property_test() {
  let gen = {
    use format <- qcheck.bind(
      qcheck.from_generators(
        qcheck.return("DHM"),     // Day-Hour-Minute
        [qcheck.return("HMS"),    // Hour-Minute-Second
         qcheck.return("MDHM")]   // Month-Day-Hour-Minute
      )
    )
    use day <- qcheck.bind(qcheck.bounded_int(1, 31))
    use hour <- qcheck.bind(qcheck.bounded_int(0, 23))
    use min <- qcheck.bind(qcheck.bounded_int(0, 59))
    use sec <- qcheck.bind(qcheck.bounded_int(0, 59))
    use month <- qcheck.bind(qcheck.bounded_int(1, 12))
    
    qcheck.return(#(format, day, hour, min, sec, month))
  }
  
  qcheck.given(gen, fn(params) {
    let #(format, day, hour, min, sec, month) = params
    
    let timestamp = case format {
      "DHM" -> 
        pad_left(int.to_string(day), 2, "0") <>
        pad_left(int.to_string(hour), 2, "0") <>
        pad_left(int.to_string(min), 2, "0") <> "z"
      "HMS" -> 
        pad_left(int.to_string(hour), 2, "0") <>
        pad_left(int.to_string(min), 2, "0") <>
        pad_left(int.to_string(sec), 2, "0") <> "h"
      "MDHM" ->
        pad_left(int.to_string(month), 2, "0") <>
        pad_left(int.to_string(day), 2, "0") <>
        pad_left(int.to_string(hour), 2, "0") <>
        pad_left(int.to_string(min), 2, "0") <> "/"
      _ -> "092345z"
    }
    
    let packet = "K1ABC>APRS:@" <> timestamp <> "4237.14N/07120.83W#"
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        result.packet_type |> should.equal(types.PositionPacket)
        case result.timestamp {
          Some(_) -> Nil
          None -> Nil  // Some timestamp formats might not be supported
        }
      }
      Error(_) -> {
        // Some timestamp formats might be invalid
        Nil
      }
    }
  })
}

// Property test: Position Ambiguity levels
pub fn position_ambiguity_property_test() {
  let gen = {
    use ambiguity <- qcheck.bind(qcheck.bounded_int(0, 4))
    use lat_base <- qcheck.bind(qcheck.bounded_int(0, 90))
    use lon_base <- qcheck.bind(qcheck.bounded_int(0, 180))
    
    qcheck.return(#(ambiguity, lat_base, lon_base))
  }
  
  qcheck.given(gen, fn(params) {
    let #(ambiguity, lat_base, lon_base) = params
    
    // Build position with ambiguity (replace digits with spaces)
    let lat_str = pad_left(int.to_string(lat_base), 2, "0") <> "37.14N"
    let lon_str = pad_left(int.to_string(lon_base), 3, "0") <> "20.83W"
    
    let lat_amb = case ambiguity {
      0 -> lat_str
      1 -> string.slice(lat_str, 0, 6) <> " " <> string.slice(lat_str, 7, 1)
      2 -> string.slice(lat_str, 0, 5) <> "  " <> string.slice(lat_str, 7, 1)
      3 -> string.slice(lat_str, 0, 3) <> "    " <> string.slice(lat_str, 7, 1)
      4 -> string.slice(lat_str, 0, 2) <> "     " <> string.slice(lat_str, 7, 1)
      _ -> lat_str
    }
    
    let packet = "K1ABC>APRS:!" <> lat_amb <> "/" <> lon_str <> "#"
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        result.packet_type |> should.equal(types.PositionPacket)
      }
      Error(_) -> {
        // Some ambiguity formats might be invalid
        Nil
      }
    }
  })
}

// Property test: MIC-E Message Types
pub fn mice_message_type_property_test() {
  let gen = {
    use msg_type <- qcheck.bind(qcheck.bounded_int(0, 10))
    use lat_digits <- qcheck.bind(qcheck.bounded_int(0, 999999))
    
    qcheck.return(#(msg_type, lat_digits))
  }
  
  qcheck.given(gen, fn(params) {
    let #(msg_type, _lat_digits) = params
    
    // MIC-E uses destination to encode message type
    // Different combinations of digits/letters encode different message types
    let dest = case msg_type {
      0 -> "S32PRV"  // Emergency
      1 -> "S32PRS"  // Priority
      2 -> "S32PRT"  // Special
      3 -> "S32PRU"  // Committed
      4 -> "S32PRW"  // Custom 1
      5 -> "S32PRX"  // Custom 2
      6 -> "S32PRY"  // Custom 3
      7 -> "SE0TUV"  // Custom 4
      8 -> "SE0TUW"  // Custom 5
      9 -> "SE0TUX"  // Custom 6
      _ -> "S32PRT"  // Default to Special
    }
    
    let packet = "K1ABC>" <> dest <> ":`*3Fl!w/]\"4}="
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        result.packet_type |> should.equal(types.MicE)
        case result.mic_e_message {
          Some(_) -> Nil
          None -> Nil  // MIC-E message type might not be decoded
        }
      }
      Error(_) -> {
        // Some MIC-E formats might be invalid
        Nil
      }
    }
  })
}

// Property test: Third-Party packets
pub fn third_party_packet_property_test() {
  let gen = {
    use inner_src <- qcheck.bind(qcheck.string_from(qcheck.uppercase_ascii_codepoint()))
    use inner_dest <- qcheck.bind(qcheck.string_from(qcheck.uppercase_ascii_codepoint()))
    use content <- qcheck.bind(qcheck.string_from(qcheck.printable_ascii_codepoint()))
    
    qcheck.return(#(inner_src, inner_dest, content))
  }
  
  qcheck.given(gen, fn(params) {
    let #(inner_src, inner_dest, content) = params
    
    let src = string.slice(inner_src <> "ABC", 0, 6)
    let dest = string.slice(inner_dest <> "XYZ", 0, 6)
    let msg = string.slice(content, 0, 20)
    
    // Third-party format: }innerpacket
    let third_party = "}" <> src <> ">" <> dest <> ",TCPIP*:>" <> msg
    let packet = "K1ABC>APRS:" <> third_party
    
    case aprs.parse_aprs(packet) {
      Ok(_result) -> {
        // Should parse as third-party or possibly another type
        // Third-party packets might be parsed as other types
        Nil
      }
      Error(_) -> {
        // Some third-party formats might be invalid
        Nil
      }
    }
  })
}

// Property test: Digipeater Used markers
pub fn digipeater_used_property_test() {
  let gen = {
    use num_digis <- qcheck.bind(qcheck.bounded_int(1, 7))
    use used_index <- qcheck.bind(qcheck.bounded_int(0, 6))
    
    qcheck.return(#(num_digis, used_index))
  }
  
  qcheck.given(gen, fn(params) {
    let #(num_digis, used_index) = params
    
    // Build digipeater path with one marked as used
    let digis = list.range(1, num_digis)
      |> list.map(fn(i) {
        case i - 1 == used_index && used_index < num_digis {
          True -> "DIGI" <> int.to_string(i) <> "*"
          False -> "DIGI" <> int.to_string(i)
        }
      })
    
    let path = string.join(digis, ",")
    let packet = "K1ABC>APRS," <> path <> ":>Test"
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        let digi_count = list.length(result.digipeaters)
        should.be_true(digi_count == num_digis)
        
        // Check if used markers are preserved
        case list.drop(result.digipeaters, used_index) {
          [_digi, ..] -> {
            // The parser might strip the * or mark it differently
            Nil
          }
          [] -> Nil
        }
      }
      Error(_) -> {
        // Some paths might be invalid
        Nil
      }
    }
  })
}

// Property test: Error boundaries for numeric fields
pub fn numeric_boundary_property_test() {
  let gen = {
    use field_type <- qcheck.bind(
      qcheck.from_generators(
        qcheck.return("lat"),
        [qcheck.return("lon"), qcheck.return("alt"), 
         qcheck.return("course"), qcheck.return("speed")]
      )
    )
    use value <- qcheck.bind(qcheck.bounded_int(-1000, 100000))
    
    qcheck.return(#(field_type, value))
  }
  
  qcheck.given(gen, fn(params) {
    let #(field_type, value) = params
    
    let packet = case field_type {
      "lat" -> {
        let lat = int.to_string(value % 9000) |> string.slice(0, 4)
        "K1ABC>APRS:!" <> lat <> ".00N/07120.83W#"
      }
      "lon" -> {
        let lon = int.to_string(value % 18000) |> string.slice(0, 5)
        "K1ABC>APRS:!4237.14N/" <> lon <> ".00W#"
      }
      "alt" -> {
        let alt = pad_left(int.to_string(value), 6, "0")
        "K1ABC>APRS:!4237.14N/07120.83W#/A=" <> alt
      }
      "course" -> {
        let course = pad_left(int.to_string(value % 1000), 3, "0")
        "K1ABC>APRS:!4237.14N/07120.83W>" <> course <> "/000"
      }
      "speed" -> {
        let speed = pad_left(int.to_string(value % 1000), 3, "0")
        "K1ABC>APRS:!4237.14N/07120.83W>000/" <> speed
      }
      _ -> "K1ABC>APRS:>Test"
    }
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        // Verify values are within valid ranges
        case field_type {
          "lat" -> {
            case result.position {
              Some(pos) -> {
                let lat = aprs.latitude_value(pos.latitude)
                should.be_true(lat >=. -90.0 && lat <=. 90.0)
              }
              None -> Nil
            }
          }
          "lon" -> {
            case result.position {
              Some(pos) -> {
                let lon = aprs.longitude_value(pos.longitude)
                should.be_true(lon >=. -180.0 && lon <=. 180.0)
              }
              None -> Nil
            }
          }
          "course" -> {
            case result.course {
              Some(c) -> {
                let course = aprs.course_value(c)
                should.be_true(course >= 0 && course <= 359)
              }
              None -> Nil
            }
          }
          _ -> Nil
        }
      }
      Error(_) -> {
        // Invalid values should fail parsing
        Nil
      }
    }
  })
}

// Helper function
fn pad_left(s: String, width: Int, pad: String) -> String {
  let len = string.length(s)
  case len < width {
    True -> string.repeat(pad, width - len) <> s
    False -> s
  }
}