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

fn atan2_quadrant_adjustment(atan_value: Float, x: Float, y: Float) -> Float {
  case x >. 0.0, y >=. 0.0 {
    True, _ -> atan_value  // Quadrant I or IV
    False, True -> atan_value +. 3.141592653589793  // Quadrant II
    False, False -> atan_value -. 3.141592653589793  // Quadrant III
  }
}

pub fn atan2(y: Float, x: Float) -> Float {
  case x, y {
    0.0, y if y >. 0.0 -> 1.5707963267948966   // PI/2
    0.0, _ -> -1.5707963267948966              // -PI/2
    x, y -> {
      let atan_yx = atan(y /. x)
      atan2_quadrant_adjustment(atan_yx, x, y)
    }
  }
}

fn atan_taylor_series(x: Float) -> Float {
  let x2 = x *. x
  let x3 = x2 *. x
  let x5 = x3 *. x2
  let x7 = x5 *. x2
  x -. x3 /. 3.0 +. x5 /. 5.0 -. x7 /. 7.0
}

pub fn atan(x: Float) -> Float {
  case x {
    x if x >. 1.0 -> 1.5707963267948966 -. atan(1.0 /. x)
    x if x <. -1.0 -> -1.5707963267948966 -. atan(1.0 /. x)
    x -> atan_taylor_series(x)
  }
}