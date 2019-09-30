f1() {
  o.g1
    .m1(() {
      null;
      // LINT :8
       null;
    });
  o.g1
    .g2.m1(() {
      null;
      // LINT :8
       null;
    });
}

var o;