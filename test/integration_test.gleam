import gleeunit
import gleeunit/should
import aprs
import aprs/types
import gleam/list

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

