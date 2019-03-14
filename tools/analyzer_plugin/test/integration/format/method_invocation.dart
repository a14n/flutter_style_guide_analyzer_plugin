
void f() {
  showDialog(
    context: null,
  )
  .then<void>((value) { });

  showDialog(
    context: null,
  )
  .then<void>((value) { })
  .then<void>((value) { })
  .then<void>((value) { });

  // LINT +5:5
  showDialog(
    context: null
  )
  .then<void>((value) { })
    .then<void>((value) { })
    .then<void>((value) { });

  when()
    .thenAnswer(() {
      return null;
    });
  when()
    .thenAnswer(() {
      return null;
    })
    .thenAnswer(() {
      return null;
    });

  // LINT +2:7
  when().then()
      .thenAnswer(() {
        return null;
      });

  // LINT +2:7
  var x1 = when().then()
      .thenAnswer(() {
        return null;
      });
  var x2 = when().then()
    .thenAnswer(() {
      return null;
    });
  var x3 = when()
    .then()
    .thenAnswer(() {
      return null;
    });
  var x4 =
    when().then()
      .thenAnswer(() {
        return null;
      });
}

var showDialog, when;