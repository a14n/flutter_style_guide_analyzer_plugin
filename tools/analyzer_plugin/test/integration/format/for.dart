var m;
test_indent() {
  for (var _; m; m)
    m;
  // LINT +2:6
  for (var _; m; m)
     m;

  for (var _; m; m) {
    m;
  }
  // LINT +2:6
  for (var _; m; m) {
     m;
  }
}
test_spaces() async {
  for (var _ in m)
    m;
  // LINT :6
  for(var _ in m)
    m;
  // LINT :8
  for ( var _ in m)
    m;
  // LINT :18
  for (var _ in m )
    m;
  // LINT :19
  for (var _ in m)  {
    m;
  }
  // LINT :19
  for (var _ in m){
    m;
  }
  // LINT :8
  await  for (var _ in m) {
    m;
  }
}
test_wrap() async {
  for (var _;
      m; m)
    m;
  for (var _; m;
      m)
    m;
  for (var _;
      m;
      m)
    m;
  // LINT :8
  for (
      var _; m; m)
    m;
  // LINT :13
  for (var _
      ; m; m)
    m;
  // LINT :16
  for (var _; m
      ; m)
    m;
}
