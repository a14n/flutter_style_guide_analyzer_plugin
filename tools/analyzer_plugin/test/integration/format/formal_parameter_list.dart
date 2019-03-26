abstract class A {
  m1a();
  // LINT :7
  m1b(
  );
  m1c(
    //
  );

  m2a({ p });
  // LINT :7
  m2b( { p });
  // LINT :12
  m2c({ p } );

  m3a(p1, { p2 });
  // LINT :10
  m3b(p1,{ p2 });
  // LINT :10
  m3c(p1,  { p2 });

  m4a(p, p1, { p2, p3 });
  // LINT :8 :13 :20
  m4b(p , p1 , { p2 , p3 });
  // LINT :9 :18
  m4c(p,p1, { p2,p3 });
  // LINT :9 :20
  m4d(p,  p1, { p2,  p3 });

  // LINT :10
  m5a({ p, });
}

abstract class B {
  m1a(
    int p,
  );
  // LINT +2:10
  m1b(
    int p
  );
  // LINT +2:6
  m1c(
     int p,
  );
  // LINT +3:4
  m1d(
    int p,
   );
  // LINT +2:10
  m1e(
    int p ,
  );

  m2a({
    int p,
  });
  // LINT :7
  m2b( {
    int p,
  });
  // LINT +3:4
  m2c({
    int p,
  } );
  // LINT +3:4
  m2d({
    int p,
   });
  // LINT :7 +3:7 +4:5 +4:6
  m2e(
    {
      int p,
    }
  );

  m3a(
    p1,
    p2, {
    p3,
    p4,
  });
  // LINT +3:8
  m3b(
    p1,
    p2,{
    p3,
    p4,
  });
  // LINT +3:8
  m3c(
    p1,
    p2,  {
    p3,
    p4,
  });
}