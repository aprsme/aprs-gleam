# APRS Gleam Parser

A pure functional APRS (Automatic Packet Reporting System) parser written in Gleam. This library provides comprehensive parsing of APRS packets used in amateur radio for position reporting, weather data, messaging, and telemetry.

## Features

- **Complete APRS protocol support**: Parses all major APRS packet types
- **Type-safe**: Extensive use of Gleam's type system with validated opaque types
- **Pure functional**: No side effects, predictable behavior
- **Comprehensive validation**: All data is validated during parsing
- **Multiple format support**: Handles compressed, uncompressed, and MIC-E formats
- **Weather station support**: Full parsing of weather data packets
- **NMEA integration**: Parses GPS NMEA sentences embedded in APRS

## Installation

Add `aprs_gleam` to your `gleam.toml` dependencies:

```toml
[dependencies]
aprs_gleam = "~> 1.0"
```

Then run:

```sh
gleam deps download
```

## Quick Start

```gleam
import aprs

pub fn main() {
  // Parse a simple position packet
  let packet = "K1ABC>APRS:!4237.14N/07120.83W#PHG2360"
  
  case aprs.parse_aprs(packet) {
    Ok(result) -> {
      // Access parsed data
      io.println("Source: " <> aprs.callsign_value(result.source.callsign))
      io.println("Latitude: " <> float.to_string(aprs.latitude_value(result.position.latitude)))
      io.println("Longitude: " <> float.to_string(aprs.longitude_value(result.position.longitude)))
    }
    Error(err) -> {
      io.println("Parse error: " <> err.message)
    }
  }
}
```

## Usage Examples

### Basic Position Report

```gleam
import aprs
import gleam/io

pub fn parse_position_example() {
  let packet = "N0CALL>APRS:!3553.52N/08343.73W>088/036/A=001234"
  
  case aprs.parse_aprs(packet) {
    Ok(result) -> {
      // Extract position data
      let pos = result.position
      io.println("Position: " <> 
        float.to_string(aprs.latitude_value(pos.latitude)) <> ", " <>
        float.to_string(aprs.longitude_value(pos.longitude)))
      
      // Check for altitude
      case pos.altitude {
        Some(alt) -> io.println("Altitude: " <> float.to_string(aprs.altitude_value(alt)) <> " feet")
        None -> Nil
      }
      
      // Check for course and speed
      case result.course {
        Some(course) -> io.println("Course: " <> int.to_string(course) <> "°")
        None -> Nil
      }
      
      case result.speed {
        Some(speed) -> io.println("Speed: " <> float.to_string(aprs.speed_value(speed)) <> " mph")
        None -> Nil
      }
    }
    Error(err) -> io.println("Error: " <> err.message)
  }
}
```

### Weather Station Data

```gleam
import aprs
import gleam/io
import gleam/option.{Some, None}

pub fn parse_weather_example() {
  let packet = "KC0YIR>APRS:@092345z4651.95N/09625.50W_090/005g010t073r000p010P010h50b10150"
  
  case aprs.parse_aprs(packet) {
    Ok(result) -> {
      case result.weather {
        Some(weather) -> {
          // Temperature
          case weather.temperature {
            Some(temp) -> io.println("Temperature: " <> float.to_string(aprs.temperature_value(temp)) <> "°F")
            None -> Nil
          }
          
          // Wind data
          case weather.wind_direction {
            Some(dir) -> io.println("Wind Direction: " <> int.to_string(dir) <> "°")
            None -> Nil
          }
          
          case weather.wind_speed {
            Some(speed) -> io.println("Wind Speed: " <> float.to_string(aprs.speed_value(speed)) <> " mph")
            None -> Nil
          }
          
          // Precipitation
          case weather.rain_last_hour {
            Some(rain) -> io.println("Rain (1h): " <> float.to_string(aprs.precipitation_value(rain)) <> " inches")
            None -> Nil
          }
          
          // Barometric pressure
          case weather.pressure {
            Some(pressure) -> io.println("Pressure: " <> float.to_string(aprs.pressure_value(pressure)) <> " mbar")
            None -> Nil
          }
        }
        None -> io.println("No weather data in packet")
      }
    }
    Error(err) -> io.println("Parse error: " <> err.message)
  }
}
```

### Message Handling

```gleam
import aprs
import gleam/io

pub fn parse_message_example() {
  let packet = "KB2ICI-14>APU25N::/N2MH-9   :Happy Birthday{001"
  
  case aprs.parse_aprs(packet) {
    Ok(result) -> {
      case result.message {
        Some(msg) -> {
          io.println("From: " <> aprs.callsign_value(result.source.callsign))
          io.println("To: " <> aprs.callsign_value(msg.addressee))
          io.println("Message: " <> msg.text)
          
          case msg.message_id {
            Some(id) -> io.println("Message ID: " <> id)
            None -> io.println("No message ID")
          }
        }
        None -> io.println("Not a message packet")
      }
    }
    Error(err) -> io.println("Parse error: " <> err.message)
  }
}
```

### MIC-E Packet Parsing

```gleam
import aprs
import gleam/io

pub fn parse_mice_example() {
  let packet = "KB1GIM>T2SQPR,WIDE1-1:`c_Vm6hk/`\"4)}_%"
  
  case aprs.parse_aprs(packet) {
    Ok(result) -> {
      io.println("Packet Type: MIC-E")
      
      // MIC-E packets encode position data
      let pos = result.position
      io.println("Position: " <> 
        float.to_string(aprs.latitude_value(pos.latitude)) <> ", " <>
        float.to_string(aprs.longitude_value(pos.longitude)))
      
      // MIC-E status text
      case result.mic_e_status {
        Some(status) -> io.println("MIC-E Status: " <> status)
        None -> Nil
      }
    }
    Error(err) -> io.println("Parse error: " <> err.message)
  }
}
```

### Creating Validated Types

```gleam
import aprs
import gleam/result

pub fn create_types_example() {
  // Create a validated callsign
  case aprs.make_callsign("N0CALL") {
    Ok(callsign) -> {
      io.println("Valid callsign: " <> aprs.callsign_value(callsign))
    }
    Error(_) -> io.println("Invalid callsign")
  }
  
  // Create validated coordinates
  let coords = {
    use lat <- result.try(aprs.make_latitude(42.345))
    use lon <- result.try(aprs.make_longitude(-71.098))
    Ok(#(lat, lon))
  }
  
  case coords {
    Ok(#(lat, lon)) -> {
      io.println("Coordinates: " <> 
        float.to_string(aprs.latitude_value(lat)) <> ", " <>
        float.to_string(aprs.longitude_value(lon)))
    }
    Error(_) -> io.println("Invalid coordinates")
  }
}
```

## Supported Packet Types

The library supports all major APRS packet types:

### Position Packets
- **`!`** - Position without timestamp
- **`=`** - Position with messaging capability
- **`@`** - Position with timestamp
- **`/`** - Position with timestamp and course/speed

### Other Packet Types
- **`'` and `` ` ``** - MIC-E compressed position/telemetry
- **`;`** - Object reports
- **`)`** - Item reports
- **`:`** - Messages, bulletins, and announcements
- **`T`** - Telemetry data
- **`_`** - Weather reports
- **`$`** - Raw NMEA sentences
- **`>`** - Status reports

## Using from Elixir

Gleam compiles to Erlang and integrates seamlessly with Elixir projects. Here's how to use the APRS parser from Elixir:

### Adding the Dependency

In your `mix.exs` file, add the APRS Gleam library to your dependencies:

```elixir
defp deps do
  [
    {:aprs_gleam, "~> 1.0", manager: :rebar3}
  ]
end
```

### Basic Usage

```elixir
defmodule MyApp.APRSExample do
  # The Gleam module is available as :aprs
  
  def parse_packet(packet_string) do
    case :aprs.parse_aprs(packet_string) do
      {:ok, result} -> 
        # Access fields from the result
        source = result.source
        position = result.position
        
        # Extract values using accessor functions
        callsign = :aprs.callsign_value(source.callsign)
        latitude = :aprs.latitude_value(position.latitude)
        longitude = :aprs.longitude_value(position.longitude)
        
        {:ok, %{
          callsign: callsign,
          latitude: latitude,
          longitude: longitude,
          packet_type: result.packet_type
        }}
        
      {:error, error} ->
        {:error, error.message}
    end
  end
end
```

### Working with Optional Values

Gleam's `Option` type is represented as `{:some, value}` or `:none` in Elixir:

```elixir
defmodule MyApp.WeatherStation do
  def extract_weather_data(packet_string) do
    case :aprs.parse_aprs(packet_string) do
      {:ok, result} ->
        case result.weather do
          {:some, weather} ->
            # Extract weather data
            temp = case weather.temperature do
              {:some, t} -> :aprs.temperature_value(t)
              :none -> nil
            end
            
            wind_speed = case weather.wind_speed do
              {:some, s} -> :aprs.speed_value(s)
              :none -> nil
            end
            
            humidity = case weather.humidity do
              {:some, h} -> :aprs.humidity_value(h)
              :none -> nil
            end
            
            %{
              temperature: temp,
              wind_speed: wind_speed,
              humidity: humidity
            }
            
          :none ->
            {:error, "No weather data in packet"}
        end
        
      {:error, error} ->
        {:error, error.message}
    end
  end
end
```

### Creating Validated Types

You can create validated types from Elixir:

```elixir
defmodule MyApp.APRSBuilder do
  def create_station_id(callsign_str, ssid_int \\ nil) do
    with {:ok, callsign} <- :aprs.make_callsign(callsign_str),
         ssid <- create_optional_ssid(ssid_int) do
      {:ok, %{callsign: callsign, ssid: ssid}}
    else
      {:error, reason} -> {:error, reason}
    end
  end
  
  defp create_optional_ssid(nil), do: :none
  defp create_optional_ssid(ssid_int) do
    case :aprs.make_ssid(ssid_int) do
      {:ok, ssid} -> {:some, ssid}
      {:error, _} -> :none
    end
  end
  
  def create_position(lat, lon, alt \\ nil) do
    with {:ok, latitude} <- :aprs.make_latitude(lat),
         {:ok, longitude} <- :aprs.make_longitude(lon),
         altitude <- create_optional_altitude(alt) do
      {:ok, %{
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
        ambiguity: 0
      }}
    else
      {:error, reason} -> {:error, reason}
    end
  end
  
  defp create_optional_altitude(nil), do: :none
  defp create_optional_altitude(alt) do
    case :aprs.make_altitude(alt) do
      {:ok, altitude} -> {:some, altitude}
      {:error, _} -> :none
    end
  end
end
```

### Pattern Matching on Packet Types

Gleam's variants are represented as atoms in Elixir:

```elixir
defmodule MyApp.PacketHandler do
  def handle_packet(packet_string) do
    case :aprs.parse_aprs(packet_string) do
      {:ok, result} ->
        case result.packet_type do
          :position_packet -> 
            handle_position(result)
            
          :weather ->
            handle_weather(result)
            
          :message ->
            handle_message(result)
            
          :mic_e ->
            handle_mice(result)
            
          :telemetry ->
            handle_telemetry(result)
            
          :unknown_packet ->
            {:unknown, result.body}
            
          _ ->
            {:other, result.packet_type}
        end
        
      {:error, error} ->
        {:error, error.message}
    end
  end
  
  defp handle_position(result) do
    %{
      type: :position,
      lat: :aprs.latitude_value(result.position.latitude),
      lon: :aprs.longitude_value(result.position.longitude),
      comment: extract_optional(result.comment)
    }
  end
  
  defp handle_weather(result) do
    case result.weather do
      {:some, weather} ->
        %{
          type: :weather,
          data: extract_weather_fields(weather)
        }
      :none ->
        {:error, "No weather data"}
    end
  end
  
  defp handle_message(result) do
    case result.message do
      {:some, msg} ->
        %{
          type: :message,
          to: :aprs.callsign_value(msg.addressee),
          text: msg.text,
          id: extract_optional(msg.message_id)
        }
      :none ->
        {:error, "No message data"}
    end
  end
  
  defp handle_mice(result) do
    %{
      type: :mice,
      lat: :aprs.latitude_value(result.position.latitude),
      lon: :aprs.longitude_value(result.position.longitude),
      status: extract_optional(result.mic_e_status)
    }
  end
  
  defp handle_telemetry(result) do
    %{type: :telemetry, data: result.body}
  end
  
  defp extract_optional({:some, value}), do: value
  defp extract_optional(:none), do: nil
  
  defp extract_weather_fields(weather) do
    %{
      temperature: extract_weather_value(weather.temperature, &:aprs.temperature_value/1),
      pressure: extract_weather_value(weather.pressure, &:aprs.pressure_value/1),
      humidity: extract_weather_value(weather.humidity, &:aprs.humidity_value/1),
      wind_speed: extract_weather_value(weather.wind_speed, &:aprs.speed_value/1),
      wind_direction: extract_optional(weather.wind_direction),
      rain_1h: extract_weather_value(weather.rain_last_hour, &:aprs.precipitation_value/1),
      rain_24h: extract_weather_value(weather.rain_last_24_hours, &:aprs.precipitation_value/1)
    }
  end
  
  defp extract_weather_value(:none, _), do: nil
  defp extract_weather_value({:some, value}, extractor), do: extractor.(value)
end
```

### Math Functions

The APRS library exports math functions that can be used from Elixir:

```elixir
defmodule MyApp.DistanceCalculator do
  @earth_radius_km 6371.0
  
  def distance_between(lat1, lon1, lat2, lon2) do
    # Convert to radians
    lat1_rad = deg_to_rad(lat1)
    lat2_rad = deg_to_rad(lat2)
    delta_lat = deg_to_rad(lat2 - lat1)
    delta_lon = deg_to_rad(lon2 - lon1)
    
    # Haversine formula using APRS math functions
    a = :aprs.sin(delta_lat / 2) * :aprs.sin(delta_lat / 2) +
        :aprs.cos(lat1_rad) * :aprs.cos(lat2_rad) *
        :aprs.sin(delta_lon / 2) * :aprs.sin(delta_lon / 2)
    
    c = 2 * :aprs.atan2(:math.sqrt(a), :math.sqrt(1 - a))
    
    @earth_radius_km * c
  end
  
  def bearing_to(lat1, lon1, lat2, lon2) do
    lat1_rad = deg_to_rad(lat1)
    lat2_rad = deg_to_rad(lat2)
    delta_lon = deg_to_rad(lon2 - lon1)
    
    y = :aprs.sin(delta_lon) * :aprs.cos(lat2_rad)
    x = :aprs.cos(lat1_rad) * :aprs.sin(lat2_rad) -
        :aprs.sin(lat1_rad) * :aprs.cos(lat2_rad) * :aprs.cos(delta_lon)
    
    bearing_rad = :aprs.atan2(y, x)
    
    # Convert to degrees and normalize to 0-360
    rem(rad_to_deg(bearing_rad) + 360, 360)
  end
  
  defp deg_to_rad(deg), do: deg * :math.pi() / 180
  defp rad_to_deg(rad), do: rad * 180 / :math.pi()
end
```

### Complete Elixir Example

Here's a complete example of an Elixir module that processes APRS packets:

```elixir
defmodule MyApp.APRSProcessor do
  require Logger
  
  def process_packet_stream(packets) do
    packets
    |> Enum.map(&process_single_packet/1)
    |> Enum.filter(&match?({:ok, _}, &1))
    |> Enum.map(fn {:ok, data} -> data end)
  end
  
  defp process_single_packet(packet_string) do
    case :aprs.parse_aprs(packet_string) do
      {:ok, result} ->
        data = %{
          source: format_station_id(result.source),
          destination: format_station_id(result.destination),
          path: Enum.map(result.path, &format_station_id/1),
          packet_type: result.packet_type,
          timestamp: extract_optional(result.timestamp),
          position: format_position(result.position),
          data: extract_packet_data(result)
        }
        
        {:ok, data}
        
      {:error, error} ->
        Logger.warning("Failed to parse APRS packet: #{error.message}")
        {:error, error.message}
    end
  end
  
  defp format_station_id(station) do
    callsign = :aprs.callsign_value(station.callsign)
    
    case station.ssid do
      {:some, ssid} -> "#{callsign}-#{:aprs.ssid_value(ssid)}"
      :none -> callsign
    end
  end
  
  defp format_position(position) do
    %{
      latitude: :aprs.latitude_value(position.latitude),
      longitude: :aprs.longitude_value(position.longitude),
      altitude: extract_altitude(position.altitude),
      ambiguity: position.ambiguity
    }
  end
  
  defp extract_altitude({:some, alt}), do: :aprs.altitude_value(alt)
  defp extract_altitude(:none), do: nil
  
  defp extract_packet_data(result) do
    %{
      weather: extract_weather(result.weather),
      message: extract_message(result.message),
      course: extract_optional(result.course),
      speed: extract_speed(result.speed),
      comment: extract_optional(result.comment)
    }
    |> Enum.filter(fn {_, v} -> v != nil end)
    |> Map.new()
  end
  
  defp extract_weather({:some, weather}), do: extract_weather_fields(weather)
  defp extract_weather(:none), do: nil
  
  defp extract_message({:some, msg}) do
    %{
      addressee: :aprs.callsign_value(msg.addressee),
      text: msg.text,
      id: extract_optional(msg.message_id)
    }
  end
  defp extract_message(:none), do: nil
  
  defp extract_speed({:some, speed}), do: :aprs.speed_value(speed)
  defp extract_speed(:none), do: nil
  
  defp extract_optional({:some, value}), do: value
  defp extract_optional(:none), do: nil
  
  defp extract_weather_fields(weather) do
    # Similar to previous example
    %{
      temperature: extract_weather_value(weather.temperature, &:aprs.temperature_value/1),
      humidity: extract_weather_value(weather.humidity, &:aprs.humidity_value/1),
      pressure: extract_weather_value(weather.pressure, &:aprs.pressure_value/1)
    }
  end
  
  defp extract_weather_value({:some, value}, extractor), do: extractor.(value)
  defp extract_weather_value(:none, _), do: nil
end
```

### Tips for Elixir Integration

1. **Atom vs String**: Gleam variant constructors become atoms in Elixir (e.g., `:position_packet`, `:weather`)
2. **Options**: Gleam's `Option(a)` becomes `{:some, value}` or `:none` in Elixir
3. **Results**: Gleam's `Result(a, b)` becomes `{:ok, value}` or `{:error, reason}` in Elixir
4. **Module Names**: Gleam modules are available as atoms (e.g., `:aprs`)
5. **Function Names**: Gleam functions use snake_case and are called the same way from Elixir

## API Reference

### Main Functions

#### `parse_aprs(packet: String) -> Result(ParseResult, ParseError)`
Parses a complete APRS packet and returns a `ParseResult` or `ParseError`.

### Type Constructors

All constructors return `Result(Type, String)` with validation:

- `make_callsign(String)` - Creates a validated callsign (1-9 alphanumeric characters)
- `make_ssid(Int)` - Creates a validated SSID (0-15)
- `make_latitude(Float)` - Creates a validated latitude (-90.0 to 90.0)
- `make_longitude(Float)` - Creates a validated longitude (-180.0 to 180.0)
- `make_altitude(Float)` - Creates a validated altitude (non-negative)
- `make_speed(Float)` - Creates a validated speed (non-negative)
- `make_temperature(Float)` - Creates a validated temperature
- `make_pressure(Float)` - Creates a validated pressure (non-negative)
- `make_humidity(Int)` - Creates a validated humidity (0-100)
- `make_precipitation(Float)` - Creates a validated precipitation (non-negative)

### Value Extractors

Extract values from opaque types:

- `callsign_value(Callsign) -> String`
- `ssid_value(Ssid) -> Int`
- `latitude_value(Latitude) -> Float`
- `longitude_value(Longitude) -> Float`
- `altitude_value(Altitude) -> Float`
- `speed_value(Speed) -> Float`
- `temperature_value(Temperature) -> Float`
- `pressure_value(Pressure) -> Float`
- `humidity_value(Humidity) -> Int`
- `precipitation_value(Precipitation) -> Float`

### Types

#### `ParseResult`
```gleam
type ParseResult {
  ParseResult(
    raw: String,
    source: StationId,
    destination: StationId,
    path: List(StationId),
    body: String,
    packet_type: PacketType,
    position: StrictPosition,
    timestamp: Option(String),
    comment: Option(String),
    weather: Option(StrictWeatherData),
    course: Option(Int),
    speed: Option(Speed),
    message: Option(Message),
    mic_e_status: Option(String),
    // ... other fields
  )
}
```

#### `ParseError`
```gleam
type ParseError {
  ParseError(
    message: String,
    context: Option(String)
  )
}
```

## Error Handling

The library provides detailed error messages with context:

```gleam
import aprs
import gleam/io

pub fn handle_errors_example() {
  let invalid_packet = "INVALID>PACKET"
  
  case aprs.parse_aprs(invalid_packet) {
    Ok(_) -> io.println("Unexpected success")
    Error(err) -> {
      io.println("Error: " <> err.message)
      
      case err.context {
        Some(ctx) -> io.println("Context: " <> ctx)
        None -> Nil
      }
    }
  }
}
```

Common error scenarios:
- Missing packet body (no `:` delimiter)
- Invalid callsigns or SSIDs
- Out-of-range coordinates
- Malformed packet data
- Unknown packet types

## Contributing

Contributions are welcome! Please ensure all code follows Gleam idioms and includes tests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

This library implements the APRS Protocol Reference (v1.0.1) specifications for amateur radio packet communication.