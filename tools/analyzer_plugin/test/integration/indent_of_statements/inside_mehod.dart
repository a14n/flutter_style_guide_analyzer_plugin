class A{
  m1() {
    // OK
    null;
    // LINT :5
     null;
    // LINT :4
   null;
  }

  m2(
    int i,
  ) {
    // OK
    null;
    // LINT :5
     null;
    // LINT :4
   null;
  }

  m3(
    int i,
  ) async {
    // OK
    null;
    // LINT :5
     null;
    // LINT :4
   null;
  }
}