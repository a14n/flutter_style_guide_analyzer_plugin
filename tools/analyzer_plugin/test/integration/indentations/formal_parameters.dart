f(
  a,
  // LINT :4
   b,
  // LINT :2
 c,
) {}

class A {
  A(
    a,
    // LINT :6
     b,
    // LINT :4
   c,
  ) {}
  m(
    a,
    // LINT :6
     b,
    // LINT :4
   c,
  ) {}
}

f1() {
  f({
    a,
    // LINT :6
     b,
    // LINT :4
   c,
  }) {}
  f();
}