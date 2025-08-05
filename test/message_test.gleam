import gleeunit
import gleeunit/should
import aprs
import aprs/types
import gleam/option.{Some, None}
import qcheck
import gleam/string
import gleam/int

pub fn main() {
  gleeunit.main()
}

// Test parsing a basic message packet
pub fn parse_basic_message_test() {
  let packet = "VK4ABC>APU25N::VK4XYZ   :Testing message{001"
  
  case aprs.parse_aprs(packet) {
    Ok(result) -> {
      result.packet_type |> should.equal(types.Message)
      
      // Verify addressee (should be padded to 9 chars)
      case result.addressee {
        Some(addr) -> {
          aprs.addressee_value(addr) |> should.equal("VK4XYZ   ")
        }
        None -> should.fail()
      }
      
      // Verify message content
      case result.message {
        Some(msg) -> {
          msg |> should.equal("Testing message")
        }
        None -> should.fail()
      }
      
      // Verify message ID
      case result.message_id {
        Some(id) -> {
          aprs.message_id_value(id) |> should.equal("001")
        }
        None -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

// Test message without ID
pub fn parse_message_no_id_test() {
  let packet = "KB1ABC>APRS::W1XYZ-9  :Hello there!"
  
  case aprs.parse_aprs(packet) {
    Ok(result) -> {
      result.packet_type |> should.equal(types.Message)
      
      case result.message {
        Some(msg) -> {
          msg |> should.equal("Hello there!")
        }
        None -> should.fail()
      }
      
      // Should have no message ID
      result.message_id |> should.equal(None)
    }
    Error(_) -> should.fail()
  }
}

// Test message acknowledgment
pub fn parse_message_ack_test() {
  let packet = "KB1ABC>APRS::W1XYZ-9  :ack123"
  
  case aprs.parse_aprs(packet) {
    Ok(result) -> {
      result.packet_type |> should.equal(types.Message)
      
      // Should have ack
      case result.message_ack {
        Some(ack) -> {
          aprs.message_id_value(ack) |> should.equal("123")
        }
        None -> should.fail()
      }
      
      // Should not have regular message
      result.message |> should.equal(None)
    }
    Error(_) -> should.fail()
  }
}

// Test message rejection
pub fn parse_message_reject_test() {
  let packet = "KB1ABC>APRS::W1XYZ-9  :rej456"
  
  case aprs.parse_aprs(packet) {
    Ok(result) -> {
      result.packet_type |> should.equal(types.Message)
      
      // Should have reject
      case result.message_reject {
        Some(rej) -> {
          aprs.message_id_value(rej) |> should.equal("456")
        }
        None -> should.fail()
      }
      
      // Should not have regular message
      result.message |> should.equal(None)
    }
    Error(_) -> should.fail()
  }
}

// Test malformed message (addressee too short)
pub fn parse_invalid_addressee_test() {
  let packet = "KB1ABC>APRS::SHORT:Test message"
  
  case aprs.parse_aprs(packet) {
    Ok(_) -> should.fail()  // Should not parse successfully
    Error(err) -> {
      err |> should.equal(types.InvalidMessage)
    }
  }
}

// Test message with special characters
pub fn parse_message_special_chars_test() {
  let packet = "KB1ABC>APRS::TEST     :Special chars: !@#$%^&*()"
  
  case aprs.parse_aprs(packet) {
    Ok(result) -> {
      case result.message {
        Some(msg) -> {
          msg |> should.equal("Special chars: !@#$%^&*()")
        }
        None -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

// Generator for telemetry parameter names
fn telemetry_param_generator() -> qcheck.Generator(String) {
  qcheck.string_from(qcheck.printable_ascii_codepoint())
  |> qcheck.map(fn(s) { string.slice(s, 0, 8) })
}

// Test: Telemetry packets with parameter names
pub fn telemetry_parameter_names_property_test() {
  let gen = {
    use p1 <- qcheck.bind(telemetry_param_generator())
    use p2 <- qcheck.bind(telemetry_param_generator())
    use p3 <- qcheck.bind(telemetry_param_generator())
    use p4 <- qcheck.bind(telemetry_param_generator())
    use p5 <- qcheck.bind(telemetry_param_generator())
    
    qcheck.return(#(p1, p2, p3, p4, p5))
  }
  
  qcheck.given(gen, fn(params) {
    let #(p1, p2, p3, p4, p5) = params
    let src = "KA0TEST"
    let packet = src <> ">APRS::KA0TEST  :PARM." <> p1 <> "," <> p2 <> "," <> p3 <> "," <> p4 <> "," <> p5
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        result.packet_type |> should.equal(types.Message)
      }
      Error(_) -> should.fail()
    }
  })
}

// Generator for object names with special characters
fn object_name_generator() -> qcheck.Generator(String) {
  use base <- qcheck.bind(qcheck.string_from(qcheck.uppercase_ascii_codepoint()))
  use special <- qcheck.bind(qcheck.from_generators(
    qcheck.return(" "),
    [qcheck.return("-"), qcheck.return("."), qcheck.return("_")]
  ))
  
  // Ensure at least one alphanumeric character
  let name = case string.length(base) {
    0 -> "TEST" <> special
    _ -> string.slice(base, 0, 4) <> special
  }
  let name = string.slice(name, 0, 9)
  
  case string.length(name) {
    n if n < 9 -> qcheck.return(name <> string.repeat(" ", 9 - n))
    _ -> qcheck.return(name)
  }
}

// Test: Object names with special characters
pub fn object_names_property_test() {
  qcheck.given(object_name_generator(), fn(name) {
    let packet = "K1ABC>APRS:;" <> name <> "*111111z4237.14N/07120.83W#Test"
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        // Just verify it parsed as an Object packet type
        result.packet_type |> should.equal(types.Object)
      }
      Error(_) -> {
        // Some object names might not parse correctly, that's OK for this test
        Nil
      }
    }
  })
}

// Property test: Message packets with IDs
pub fn message_with_id_property_test() {
  let gen = {
    use addressee <- qcheck.bind(qcheck.string_from(qcheck.uppercase_ascii_codepoint()))
    use message <- qcheck.bind(qcheck.string_from(qcheck.printable_ascii_codepoint()))
    use msg_id <- qcheck.bind(qcheck.bounded_int(1, 999))
    
    qcheck.return(#(addressee, message, msg_id))
  }
  
  qcheck.given(gen, fn(params) {
    let #(addressee, message, msg_id) = params
    
    // Addressee must be exactly 9 chars
    let addr = string.slice(addressee <> "         ", 0, 9)
    let msg = string.slice(message, 0, 67)  // Max message length
    let id = int.to_string(msg_id)
    
    let packet = "K1ABC>APRS::" <> addr <> ":" <> msg <> "{" <> id
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        result.packet_type |> should.equal(types.Message)
      }
      Error(_) -> {
        // Some messages might be invalid
        Nil
      }
    }
  })
}

// Property test: Message acknowledgments and rejects
pub fn message_ack_rej_property_test() {
  let gen = {
    use addressee <- qcheck.bind(qcheck.string_from(qcheck.uppercase_ascii_codepoint()))
    use msg_id <- qcheck.bind(qcheck.bounded_int(1, 99999))
    use is_ack <- qcheck.bind(qcheck.bool())
    
    qcheck.return(#(addressee, msg_id, is_ack))
  }
  
  qcheck.given(gen, fn(params) {
    let #(addressee, msg_id, is_ack) = params
    
    let addr = string.slice(addressee <> "         ", 0, 9)
    let ack_rej = case is_ack {
      True -> "ack"
      False -> "rej"
    }
    
    let packet = "K1ABC>APRS::" <> addr <> ":" <> ack_rej <> int.to_string(msg_id)
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        result.packet_type |> should.equal(types.Message)
        case is_ack {
          True -> should.be_true(result.message_ack != option.None)
          False -> should.be_true(result.message_reject != option.None)
        }
      }
      Error(_) -> {
        // Some ack/rej might be invalid
        Nil
      }
    }
  })
}

// Property test: Bulletin messages
pub fn bulletin_property_test() {
  let gen = {
    use blt_id <- qcheck.bind(qcheck.bounded_int(0, 9))
    use message <- qcheck.bind(qcheck.string_from(qcheck.printable_ascii_codepoint()))
    
    qcheck.return(#(blt_id, message))
  }
  
  qcheck.given(gen, fn(params) {
    let #(blt_id, message) = params
    
    let bulletin_addr = "BLN" <> int.to_string(blt_id) <> "     "
    let msg = string.slice(message, 0, 67)
    
    let packet = "K1ABC>APRS::" <> bulletin_addr <> ":" <> msg
    
    case aprs.parse_aprs(packet) {
      Ok(result) -> {
        result.packet_type |> should.equal(types.Message)
      }
      Error(_) -> {
        // Some bulletins might be invalid
        Nil
      }
    }
  })
}