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

  Initializers._4(
    a,
  ) : a = a,
      b = a,
      super();

  var a, b, c;
}