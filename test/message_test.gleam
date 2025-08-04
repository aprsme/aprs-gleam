import gleeunit
import gleeunit/should
import aprs
import aprs/types
import gleam/option.{Some, None}

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