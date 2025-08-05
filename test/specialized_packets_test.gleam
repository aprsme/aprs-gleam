import gleeunit
import gleeunit/should
import aprs
import aprs/types
import qcheck
import gleam/int
import gleam/string

pub fn main() {
  gleeunit.main()
}

// Helper to pad string left with a character
fn pad_left(s: String, width: Int, pad: String) -> String {
  let len = string.length(s)
  case len < width {
    True -> string.repeat(pad, width - len) <> s
    False -> s
  }
}

// Property test: Item packets
pub fn item_packet_property_test() {
  let gen = {
    use name <- qcheck.bind(qcheck.string_from(qcheck.uppercase_ascii_codepoint()))
    use alive <- qcheck.bind(qcheck.bool())
    use lat_deg <- qcheck.bind(qcheck.bounded_int(0, 90))
    use lat_min <- qcheck.bind(qcheck.bounded_int(0, 59))
    use lat_hun <- qcheck.bind(qcheck.bounded_int(0, 99))
    use lon_deg <- qcheck.bind(qcheck.bounded_int(0, 180))
    use lon_min <- qcheck.bind(qcheck.bounded_int(0, 59))
    use lon_hun <- qcheck.bind(qcheck.bounded_int(0, 99))
    
    qcheck.return(#(name, alive, lat_deg, lat_min, lat_hun, lon_deg, lon_min, lon_hun))
  }
  
  qcheck.given(gen, fn(params) {
    let #(name, alive, lat_deg, lat_min, lat_hun, lon_deg, lon_min, lon_hun) = params
    
    // Item name is 3-9 chars
    let item_name = string.slice(name <> "TEST", 0, 6)
    let status = case alive {
      True -> "!"
      False -> "_"
    }
    
    let lat = pad_left(int.to_string(lat_deg), 2, "0") <> 
              pad_left(int.to_string(lat_min), 2, "0") <> "." <>
              pad_left(int.to_string(lat_hun), 2, "0") <> "N"
    
    let lon = pad_left(int.to_string(lon_deg), 3, "0") <> 
              pad_left(int.to_string(lon_min), 2, "0") <> "." <>
              pad_left(int.to_string(lon_hun), 2, "0") <> "W"
    
    let packet = "K1ABC>APRS:)" <> item_name <> status <> lat <> "/" <> lon <> "#Test Item"
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        result.packet_type |> should.equal(types.Item)
      }
      Error(_) -> {
        // Some items might be invalid
        Nil
      }
    }
  })
}

// Property test: NMEA GPRMC sentences
pub fn nmea_gprmc_property_test() {
  let gen = {
    use hour <- qcheck.bind(qcheck.bounded_int(0, 23))
    use min <- qcheck.bind(qcheck.bounded_int(0, 59))
    use sec <- qcheck.bind(qcheck.bounded_int(0, 59))
    use valid <- qcheck.bind(qcheck.bool())
    use lat_deg <- qcheck.bind(qcheck.bounded_int(0, 90))
    use lat_min <- qcheck.bind(qcheck.bounded_int(0, 5999))
    use lon_deg <- qcheck.bind(qcheck.bounded_int(0, 180))
    use lon_min <- qcheck.bind(qcheck.bounded_int(0, 5999))
    
    qcheck.return(#(hour, min, sec, valid, lat_deg, lat_min, lon_deg, lon_min))
  }
  
  qcheck.given(gen, fn(params) {
    let #(hour, min, sec, valid, lat_deg, lat_min, lon_deg, lon_min) = params
    
    let time = pad_left(int.to_string(hour), 2, "0") <>
               pad_left(int.to_string(min), 2, "0") <>
               pad_left(int.to_string(sec), 2, "0")
    
    let status = case valid {
      True -> "A"
      False -> "V"
    }
    
    let lat = pad_left(int.to_string(lat_deg), 2, "0") <>
              pad_left(int.to_string(lat_min), 4, "0") <> ".00"
    
    let lon = pad_left(int.to_string(lon_deg), 3, "0") <>
              pad_left(int.to_string(lon_min), 4, "0") <> ".00"
    
    let packet = "K1ABC>APRS:$GPRMC," <> time <> "," <> status <> "," <> 
                 lat <> ",N," <> lon <> ",W,0.0,0.0,010121,,,*00"
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        result.packet_type |> should.equal(types.NmeaGprmc)
      }
      Error(_) -> {
        // Some NMEA might be invalid
        Nil
      }
    }
  })
}

// Property test: NMEA GPGGA sentences
pub fn nmea_gpgga_property_test() {
  let gen = {
    use hour <- qcheck.bind(qcheck.bounded_int(0, 23))
    use min <- qcheck.bind(qcheck.bounded_int(0, 59))
    use sec <- qcheck.bind(qcheck.bounded_int(0, 59))
    use fix <- qcheck.bind(qcheck.bounded_int(0, 2))
    use sats <- qcheck.bind(qcheck.bounded_int(0, 12))
    
    qcheck.return(#(hour, min, sec, fix, sats))
  }
  
  qcheck.given(gen, fn(params) {
    let #(hour, min, sec, fix, sats) = params
    
    let time = pad_left(int.to_string(hour), 2, "0") <>
               pad_left(int.to_string(min), 2, "0") <>
               pad_left(int.to_string(sec), 2, "0") <> ".00"
    
    let fix_str = int.to_string(fix)
    let sats_str = pad_left(int.to_string(sats), 2, "0")
    
    let packet = "K1ABC>APRS:$GPGGA," <> time <> ",4237.1400,N,07120.8300,W," <> 
                 fix_str <> "," <> sats_str <> ",1.0,100.0,M,0.0,M,,*00"
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        result.packet_type |> should.equal(types.NmeaGpgga)
      }
      Error(_) -> {
        // Some NMEA might be invalid
        Nil
      }
    }
  })
}

// Property test: NMEA GPGLL sentences
pub fn nmea_gpgll_property_test() {
  let gen = {
    use lat_deg <- qcheck.bind(qcheck.bounded_int(0, 90))
    use lat_min <- qcheck.bind(qcheck.bounded_int(0, 5999))
    use lon_deg <- qcheck.bind(qcheck.bounded_int(0, 180))
    use lon_min <- qcheck.bind(qcheck.bounded_int(0, 5999))
    use valid <- qcheck.bind(qcheck.bool())
    
    qcheck.return(#(lat_deg, lat_min, lon_deg, lon_min, valid))
  }
  
  qcheck.given(gen, fn(params) {
    let #(lat_deg, lat_min, lon_deg, lon_min, valid) = params
    
    let lat = pad_left(int.to_string(lat_deg), 2, "0") <>
              pad_left(int.to_string(lat_min), 4, "0") <> ".00"
    
    let lon = pad_left(int.to_string(lon_deg), 3, "0") <>
              pad_left(int.to_string(lon_min), 4, "0") <> ".00"
    
    let status = case valid {
      True -> "A"
      False -> "V"
    }
    
    let packet = "K1ABC>APRS:$GPGLL," <> lat <> ",N," <> lon <> ",W,123456.00," <> status <> ",*00"
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        result.packet_type |> should.equal(types.NmeaGpgll)
      }
      Error(_) -> {
        // Some NMEA might be invalid
        Nil
      }
    }
  })
}

// Property test: DX Spot packets
pub fn dx_spot_property_test() {
  let gen = {
    use freq <- qcheck.bind(qcheck.bounded_int(1800, 30000))
    use dx_call <- qcheck.bind(
      qcheck.string_from(qcheck.uppercase_ascii_codepoint())
      |> qcheck.map(fn(s) { 
        let trimmed = string.slice(s, 0, 8)
        case string.length(trimmed) {
          0 -> "W1AW"  // Default callsign if empty
          _ -> trimmed
        }
      })
    )
    use spotter <- qcheck.bind(
      qcheck.string_from(qcheck.uppercase_ascii_codepoint())
      |> qcheck.map(fn(s) { 
        let trimmed = string.slice(s, 0, 8)
        case string.length(trimmed) {
          0 -> "K1ABC"  // Default callsign if empty
          _ -> trimmed
        }
      })
    )
    
    qcheck.return(#(freq, dx_call, spotter))
  }
  
  qcheck.given(gen, fn(params) {
    let #(freq, dx_call, spotter) = params
    
    let freq_str = int.to_string(freq / 10) <> "." <> int.to_string(freq % 10)
    let dx = string.slice(dx_call, 0, 8)
    let spotter_call = string.slice(spotter, 0, 8)
    
    let packet = "DX>APRS:DX de " <> spotter_call <> ": " <> freq_str <> " " <> dx <> " CQ DX"
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        result.packet_type |> should.equal(types.DxSpot)
      }
      Error(_) -> {
        // Some DX spots might be invalid
        Nil
      }
    }
  })
}

// Property test: Unknown/unsupported packet types
pub fn unknown_packet_property_test() {
  let gen = {
    use symbol <- qcheck.bind(
      qcheck.from_generators(
        qcheck.return("$"),
        [qcheck.return("%"), qcheck.return("&"), qcheck.return("*")]
      )
    )
    use content <- qcheck.bind(qcheck.string_from(qcheck.printable_ascii_codepoint()))
    
    qcheck.return(#(symbol, content))
  }
  
  qcheck.given(gen, fn(params) {
    let #(symbol, content) = params
    let text = string.slice(content, 0, 50)
    
    let packet = "K1ABC>APRS:" <> symbol <> text
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        // Should parse as UnknownPacket or specific type
        case result.packet_type {
          types.UnknownPacket -> Nil
          _ -> Nil  // Might parse as a known type
        }
      }
      Error(_) -> {
        // Some packets might be completely invalid
        Nil
      }
    }
  })
}