class A{
  A() {
    // OK
    null;
    // LINT :5
     null;
    // LINT :4
   null;
  }
  A.m1() : super() {
    // OK
    null;
    // LINT :5
     null;
    // LINT :4
   null;
  }
  A.m2()
      : super() {
    // OK
    null;
    // LINT :5
     null;
    // LINT :4
   null;
  }
}