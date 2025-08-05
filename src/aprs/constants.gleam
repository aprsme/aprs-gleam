/// Constants used throughout the APRS parser
/// 
/// This module contains all the magic numbers and conversion factors
/// used in APRS packet parsing and processing.

// Mathematical Constants
pub const pi = 3.141592653589793
pub const half_pi = 1.5707963267948966

// Taylor Series Factorials for Trigonometry
pub const factorial_3 = 6.0
pub const factorial_4 = 24.0
pub const factorial_5 = 120.0
pub const factorial_6 = 720.0
pub const factorial_7 = 5040.0
pub const factorial_8 = 40_320.0

// Time Constants
pub const seconds_per_minute = 60
pub const seconds_per_hour = 3600
pub const seconds_per_day = 86_400
pub const minutes_per_degree = 60.0

// APRS Packet Format Constants
pub const min_packet_length = 10
pub const min_callsign_length = 1
pub const max_callsign_length = 9
pub const max_base_call_length = 9
pub const min_ssid = 0
pub const max_ssid = 15
pub const max_dstar_ssid_length = 3
pub const max_digipeater_count = 8
pub const addressee_field_length = 9
pub const object_name_length = 9

// Position Format Constants
pub const compressed_position_length = 13
pub const uncompressed_position_length = 19
pub const latitude_field_length = 8
pub const longitude_field_length = 9
pub const max_latitude_degrees = 90
pub const max_longitude_degrees = 180
pub const max_course_degrees = 360

// Compressed Position Constants
pub const compressed_lat_divisor = 380_926.0
pub const compressed_lon_divisor = 190_463.0
pub const latitude_offset = 90.0
pub const longitude_offset = 180.0

// Base-91 Constants
pub const base91_radix = 91
pub const base91_min_ascii = 33
pub const base91_max_ascii = 126
pub const base91_excluded_ascii = 96
pub const base91_offset = 33

// MIC-E Constants
pub const mice_destination_length = 6
pub const mice_data_min_length = 9
pub const mice_data_marker = 0x60  // backtick character
pub const mice_longitude_offset = 100

// Unit Conversion Constants
pub const knots_to_kmh = 1.852
pub const mph_to_kmh = 1.60934
pub const feet_to_meters = 0.3048
pub const miles_to_km = 1.60934
pub const hundredths_inch_to_mm = 0.254

// Temperature Conversion Constants
pub const fahrenheit_offset = 32.0
pub const fahrenheit_to_celsius_factor = 0.5555555556  // 5.0 / 9.0

// Weather Field Lengths
pub const weather_direction_length = 3
pub const weather_speed_length = 3
pub const weather_temp_length = 3
pub const weather_rain_length = 3
pub const weather_humidity_length = 2
pub const weather_pressure_length = 5
pub const pressure_divisor = 10.0

// PHG/RNG Constants
pub const phg_field_length = 7
pub const phg_data_length = 4
pub const rng_field_length = 7
pub const max_phg_digit = 9

// Altitude Constants
pub const altitude_field_length = 9

// DAO Extension Constants
pub const dao_extension_length = 5

// Message Format Constants
pub const message_min_length = 11
pub const telemetry_prefix_length = 3
pub const digital_bits_length = 8

// Timestamp Format Constants
pub const timestamp_field_length = 6
pub const timestamp_packet_min_length = 8
pub const positionless_weather_min_length = 9

// Maximum Values
pub const max_humidity_percent = 100
pub const max_wind_direction = 360