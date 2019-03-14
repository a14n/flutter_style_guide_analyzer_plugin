
void f() {
  showDialog(
    context: null,
  ).a;

  showDialog(
    context: null
  )
  .a
  .a
  .a;

  // LINT +5:5
  showDialog(
    context: null
  )
  .a
    .a
    .a;

  when()
    .a;

  // LINT +2:7
  when().a
      .a;
}

var showDialog, when;