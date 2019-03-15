class Initializers {
  Initializers._1() : super();

  Initializers._2()
    : super();

  Initializers._3a(
    a,
  ) : super();
  Initializers._3b({
    a,
  }) : super();

  Initializers._4a(
    a,
  ) : a = a,
      b = a,
      super();
  // LINT +3:6
  Initializers._4b(
    a,
  ) :  a = a,
      b = a,
      super();
  // LINT +4:8
  Initializers._4c(
    a,
  ) : a = a,
       b = a,
      super();
  // LINT +5:8
  Initializers._4d(
    a,
  ) : a = a,
      b = a,
       super();

  Initializers._5a()
    : a = true,
      super();
  // LINT :22 :34
  Initializers._5b() : a = true, super();

  var a, b, c;
}