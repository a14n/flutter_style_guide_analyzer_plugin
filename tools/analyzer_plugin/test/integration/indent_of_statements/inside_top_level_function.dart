f1() {
  // OK
  null;
  // LINT :3
   null;
  // LINT :2
 null;
}

f2(
  int i,
) {
  // OK
  null;
  // LINT :3
   null;
  // LINT :2
 null;
}

f3(
  int i,
) async {
  // OK
  null;
  // LINT :3
   null;
  // LINT :2
 null;
}