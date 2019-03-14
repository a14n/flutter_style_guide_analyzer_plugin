f() {
  var a;
  a == null ? null : null;
  a == null ? null : () {
    var b;
  };
  // LINT +2:7
  a == null ? null : () {
      var b;
  };
}