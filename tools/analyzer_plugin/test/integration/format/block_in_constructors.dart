class A {
  A(x);
}
class B extends A {
  B()
    : super(() {
        //
      });
}