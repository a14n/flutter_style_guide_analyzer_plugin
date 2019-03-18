f() {
  var a;
  a == null ? null : null;
  a == null ? null : () {
    m;
  };
  // LINT +2:7
  a == null ? null : () {
      m;
  };
}
var m;