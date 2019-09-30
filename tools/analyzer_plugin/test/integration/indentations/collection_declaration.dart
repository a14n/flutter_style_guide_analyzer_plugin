class A {
  var a = [
    // OK
    null,
    // LINT :6
     null,
    // LINT :4
   null,
  ];
  var b = {
    // OK
    null,
    // LINT :6
     null,
    // LINT :4
   null,
  };
  var c = {
    // OK
    1: null,
    // LINT :6
     2: null,
    // LINT :4
   3: null,
  };
  // exception for aligned colon in map if every entries are at least +2 and colons aligned
  var map1 = {
    200: null,
      1: null,
  };
  var map2 = {
     // LINT +2:4
     1: null,
   200: null,
  };
  var map3 = {
        // LINT +1:9,+2:7
        1: null,
      200: null,
  };
}
