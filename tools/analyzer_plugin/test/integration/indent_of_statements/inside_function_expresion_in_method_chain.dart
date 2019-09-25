f1() {
  o.g1
    .m1(() {
      null;
      // LINT :7
       null;
    });
  o.g1
    .g2.m1(() {
      null;
      // LINT :7
       null;
    });
}

var o;