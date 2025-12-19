///|
priv enum LazyPrim[T] {
  Thunk(() -> T)
  Value(T)
}

///|
impl[T : Default] Default for LazyPrim[T] with default() {
  Value(Default::default())
}

///|
impl[T : Show] Show for LazyPrim[T] with to_string(self) {
  match self {
    Thunk(_) => "Thunk".to_string()
    Value(v) => "Value(\{v})"
  }
}

///|
impl[T : Show] Show for LazyPrim[T] with output(self, logger) {
  logger.write_string(self.to_string())
}

///|
struct Lazy[T] {
  mut body : LazyPrim[T]
} derive(Default)

///|
impl[T : Show] Show for Lazy[T] with to_string(self) {
  self.body.to_string()
}

///|
impl[T : Show] Show for Lazy[T] with output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub fn[T] Lazy::from_value(val : T) -> Lazy[T] {
  { body: Value(val) }
}

///|
pub fn[T] Lazy::from_thunk(f : () -> T) -> Lazy[T] {
  { body: Thunk(f) }
}

///|
/// Creates a lazy value from a thunk
pub fn[T] Lazy::new(f : () -> T) -> Lazy[T] {
  Lazy::from_thunk(f)
}

///|
/// Forces the lazy value
pub fn[T] Lazy::force(self : Lazy[T]) -> T {
  match self.body {
    Value(v) => v
    Thunk(f) => {
      let v = f()
      self.body = Value(v)
      v
    }
  }
}

///|
/// Returns true if the value is already forced
pub fn[T] Lazy::is_value(self : Lazy[T]) -> Bool {
  match self.body {
    Value(_) => true
    Thunk(_) => false
  }
}

///| Applies f directly if self is already forced,

///|
/// otherwise it behaves like map
pub fn[A, B] Lazy::map_val(self : Lazy[A], f : (A) -> B) -> Lazy[B] {
  match self.body {
    Thunk(t) => Lazy::from_thunk(fn() { f(t()) })
    Value(v) => Lazy::from_value(f(v))
  }
}

///| Returns a lazy value that when forced,

///|
/// forces self and applies f to its value
pub fn[A, B] Lazy::map(self : Lazy[A], f : (A) -> B) -> Lazy[B] {
  Lazy::from_thunk(fn() { f(self.force()) })
}

///|
/// Get the value if it is already forced
pub fn[T] Lazy::get(self : Lazy[T]) -> T? {
  match self.body {
    Value(v) => Some(v)
    Thunk(_) => None
  }
}

///|
test "lazy" {
  let x = Lazy::new(fn() { 1 + 1 })
  // Before forcing
  inspect(x.map(fn(x) { x + 1 }), content="Thunk")
  inspect(x.map_val(fn(x) { x + 1 }), content="Thunk")
  inspect(x, content="Thunk")
  inspect(x.get(), content="None")
  inspect(x.is_value(), content="false")
  // Force the value
  inspect(x.force(), content="2")
  inspect(x.is_value(), content="true")
  inspect(x.map(fn(x) { x + 1 }), content="Thunk")
  inspect(x.map(fn(x) { x + 1 }).force(), content="3")
  inspect(x.map_val(fn(x) { x + 1 }), content="Value(3)")
  inspect(x.get(), content="Some(2)")
  inspect(x, content="Value(2)")
}
