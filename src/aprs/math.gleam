pub fn sin(x: Float) -> Float {
  let x2 = x *. x
  let x3 = x2 *. x
  let x5 = x3 *. x2
  let x7 = x5 *. x2
  x -. x3 /. 6.0 +. x5 /. 120.0 -. x7 /. 5040.0
}

pub fn cos(x: Float) -> Float {
  let x2 = x *. x
  let x4 = x2 *. x2
  let x6 = x4 *. x2
  let x8 = x6 *. x2
  1.0 -. x2 /. 2.0 +. x4 /. 24.0 -. x6 /. 720.0 +. x8 /. 40_320.0
}

pub fn atan2(y: Float, x: Float) -> Float {
  case x == 0.0 {
    True ->
      case y >. 0.0 {
        True -> 1.5707963267948966
        False -> -1.5707963267948966
      }
    False -> {
      let atan_yx = atan(y /. x)
      case x >. 0.0 {
        True -> atan_yx
        False ->
          case y >=. 0.0 {
            True -> atan_yx +. 3.141592653589793
            False -> atan_yx -. 3.141592653589793
          }
      }
    }
  }
}

pub fn atan(x: Float) -> Float {
  case x >. 1.0 {
    True -> 1.5707963267948966 -. atan(1.0 /. x)
    False ->
      case x <. -1.0 {
        True -> -1.5707963267948966 -. atan(1.0 /. x)
        False -> {
          let x2 = x *. x
          let x3 = x2 *. x
          let x5 = x3 *. x2
          let x7 = x5 *. x2
          x -. x3 /. 3.0 +. x5 /. 5.0 -. x7 /. 7.0
        }
      }
  }
}