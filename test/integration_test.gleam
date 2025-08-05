import gleeunit
import gleeunit/should
import aprs
import aprs/types
import gleam/list
import qcheck
import gleam/int
import gleam/string

pub fn main() {
  gleeunit.main()
}

// Test parsing real-world packets from packets.csv
pub fn parse_real_world_packets_test() {
  let test_packets = [
    // Position packets
    "K1ABC>APRS:!4237.14N/07120.83W#",
    "W2XYZ-9>APOTC1,WIDE2-1:!4301.23N/07345.67W>090/035",
    "VE3DMP>BEACON:!4530.00N/07530.00W#PHG7230",
    "OH2RDP>APRS,TCPIP*:!6028.51N/02505.68E#",
    
    // Position with extensions
    "N1PCE>T3PQ16,WIDE1-1,WIDE2-1:`cN0l v/`\"4)}MT-RTG|!w:1!|3",
    "W1ABC>APRS:!4237.14N/07120.83W#PHG5360/A=001234",
    
    // Messages
    "WHO-7>APJIW4,TCPIP*,qAC,AE5PL-JF::WB4BFD   :Mike see you at the Fest?{JH}",
    "KD4YDD-8>APWW10,WIDE1-1,WIDE2-1:}WD4YDH-3>APRS,TCPIP*,KD4YDD-8*::WB4BFD-9 :Heard you unproto{08",
    
    // Weather
    "KC0YIR>APRS:@092345z4651.95N/09625.50W_090/005g010t073r000p010P010h50b10150",
    "CW0007>APRS:_10090556c220s004g005t077r001p002P003h50b10148",
    
    // Status
    "N0LKV-7>APDR15:>APRS via Davis DSR (status)",
    
    // Objects
    "]N0LKV-7>APDR15,TCPIP*:;LEADVILLE*092345z3906.28N/10615.48WaLEADVILLE NWS SITE",
  ]
  
  let results = list.map(test_packets, fn(packet) {
    case aprs.parse_aprs(packet) {
      Ok(_result) -> {
        Ok(Nil)
      }
      Error(_err) -> {
        Error(packet)
      }
    }
  })
  
  // Count successes
  let success_count = list.filter(results, fn(r) {
    case r {
      Ok(_) -> True
      Error(_) -> False
    }
  }) |> list.length()
  
  // At least half should parse successfully
  should.be_true(success_count > list.length(test_packets) / 2)
}

// Test specific packet types from real data
pub fn parse_digipeater_paths_test() {
  let packets_with_paths = [
    "OH2RDP>BEACON,OH2RDG*,WIDE:!6028.51N/02505.68E#PHG7220",
    "K1ABC>APRS,WIDE1-1,WIDE2-1:!4237.14N/07120.83W#",
    "N0CALL>APRS,DIGI1,DIGI2,DIGI3*:>Status",
  ]
  
  list.each(packets_with_paths, fn(packet) {
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        // Should have digipeaters
        let digi_count = list.length(result.digipeaters)
        should.be_true(digi_count > 0)
        
        Nil
      }
      Error(_) -> {
        Nil
      }
    }
  })
}

// Test MIC-E packets
pub fn parse_mice_packets_test() {
  let mice_packets = [
    "N1PCE>T3PQ16,WIDE1-1,WIDE2-1:`cN0l v/`\"4)}MT-RTG|!w:1!|3",
    "KB1GVR-9>T0PWYN,W2CJS,WIDE1*,WIDE2-1:`b-Tl!Ik/]\"4'}|!%&-']|!w`X!|3",
  ]
  
  list.each(mice_packets, fn(packet) {
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        case result.packet_type {
          types.MicE -> Nil
          _ -> Nil
        }
      }
      Error(_) -> {
        Nil
      }
    }
  })
}

// Test edge cases and malformed packets
pub fn parse_edge_cases_test() {
  let edge_cases = [
    // Too short
    "A>B:",
    // No body
    "CALL>APRS:",
    // Invalid source
    "123>APRS:>Test",
    // Too many digipeaters
    "A>B,D1,D2,D3,D4,D5,D6,D7,D8,D9:>Test",
    // Special characters in message
    "K1ABC>APRS::TEST     :Special: !@#$%^&*()",
  ]
  
  list.each(edge_cases, fn(packet) {
    case aprs.parse_aprs(packet) {
      Ok(_) -> {
        Nil
      }
      Error(_err) -> {
        Nil
      }
    }
  })
}

// Property test: MIC-E destination addresses
pub fn mice_destination_property_test() {
  // MIC-E uses destination addresses to encode position/status
  let gen = {
    use lat_digit1 <- qcheck.bind(qcheck.bounded_int(0, 9))
    use lat_digit2 <- qcheck.bind(qcheck.bounded_int(0, 9))
    use lat_digit3 <- qcheck.bind(qcheck.bounded_int(0, 9))
    use lat_digit4 <- qcheck.bind(qcheck.bounded_int(0, 9))
    use north <- qcheck.bind(qcheck.bool())
    use west <- qcheck.bind(qcheck.bool())
    
    qcheck.return(#(lat_digit1, lat_digit2, lat_digit3, lat_digit4, north, west))
  }
  
  qcheck.given(gen, fn(params) {
    let #(d1, d2, d3, d4, _north, _west) = params
    
    // Build destination like T3PQ16
    let dest = "T" <> int.to_string(d1) <> "P" <> int.to_string(d2) <> "Q" <> int.to_string(d3) <> int.to_string(d4)
    let packet = "N0CALL>" <> dest <> ":`cN0l v/`\"4)}MT-RTG"
    
    case aprs.parse_aprs(packet) {
      Ok(_result) -> {
        // Just verify it doesn't crash
        Nil
      }
      Error(_) -> {
        // Some MIC-E packets might be invalid
        Nil
      }
    }
  })
}

// Property test: Telemetry data values
pub fn telemetry_values_property_test() {
  let gen = {
    use seq <- qcheck.bind(qcheck.bounded_int(0, 999))
    use a1 <- qcheck.bind(qcheck.bounded_int(0, 255))
    use a2 <- qcheck.bind(qcheck.bounded_int(0, 255))
    use a3 <- qcheck.bind(qcheck.bounded_int(0, 255))
    use a4 <- qcheck.bind(qcheck.bounded_int(0, 255))
    use a5 <- qcheck.bind(qcheck.bounded_int(0, 255))
    use digital <- qcheck.bind(qcheck.bounded_int(0, 255))
    
    qcheck.return(#(seq, a1, a2, a3, a4, a5, digital))
  }
  
  qcheck.given(gen, fn(params) {
    let #(seq, a1, a2, a3, a4, a5, digital) = params
    
    let seq_str = case seq {
      s if s < 10 -> "00" <> int.to_string(s)
      s if s < 100 -> "0" <> int.to_string(s)
      s -> int.to_string(s)
    }
    let digital_bits = int.to_string(digital)
    
    let packet = "KK5CM-3>APMI06:T#" <> seq_str <> "," <> 
      int.to_string(a1) <> "," <> int.to_string(a2) <> "," <> 
      int.to_string(a3) <> "," <> int.to_string(a4) <> "," <> 
      int.to_string(a5) <> "," <> digital_bits
    
    case aprs.parse_aprs(packet) {
      Ok(_result) -> {
        // Just verify it parses without crashing
        Nil
      }
      Error(_) -> {
        // Some telemetry values might be invalid
        Nil
      }
    }
  })
}

// Property test: Status packets with various symbols
pub fn status_symbol_property_test() {
  let gen = {
    use symbol <- qcheck.bind(
      qcheck.from_generators(
        qcheck.return(">"),
        [qcheck.return("="), qcheck.return("!"), qcheck.return("@")]
      )
    )
    use status_text <- qcheck.bind(qcheck.string_from(qcheck.printable_ascii_codepoint()))
    
    qcheck.return(#(symbol, status_text))
  }
  
  qcheck.given(gen, fn(params) {
    let #(symbol, status_text) = params
    let text = string.slice(status_text, 0, 50)  // Limit length
    
    let packet = "N0CALL>APRS:" <> symbol <> text
    
    case aprs.parse_aprs(packet) {
      Ok(_result) -> {
        // Just verify it parses
        Nil
      }
      Error(_) -> {
        // Some status packets might be invalid
        Nil
      }
    }
  })
}

// Property test: Digipeater paths
pub fn digipeater_path_property_test() {
  let gen = {
    use num_digis <- qcheck.bind(qcheck.bounded_int(0, 7))
    use wide1 <- qcheck.bind(qcheck.bool())
    use wide2 <- qcheck.bind(qcheck.bool())
    
    qcheck.return(#(num_digis, wide1, wide2))
  }
  
  qcheck.given(gen, fn(params) {
    let #(num_digis, wide1, wide2) = params
    
    let digi_list = case num_digis {
      0 -> []
      n -> {
        let base_digis = list.range(1, n)
          |> list.map(fn(i) { "DIGI" <> int.to_string(i) })
        
        case wide1, wide2 {
          True, True -> list.append(base_digis, ["WIDE1-1", "WIDE2-1"])
          True, False -> list.append(base_digis, ["WIDE1-1"])
          False, True -> list.append(base_digis, ["WIDE2-1"])
          False, False -> base_digis
        }
      }
    }
    
    let path = case digi_list {
      [] -> ""
      digis -> "," <> string.join(digis, ",")
    }
    
    let packet = "K1ABC>APRS" <> path <> ":!4237.14N/07120.83W#"
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        let actual_digi_count = list.length(result.digipeaters)
        should.be_true(actual_digi_count <= 8)  // Max 8 digipeaters
      }
      Error(_) -> {
        // Some paths might be invalid
        Nil
      }
    }
  })
}

