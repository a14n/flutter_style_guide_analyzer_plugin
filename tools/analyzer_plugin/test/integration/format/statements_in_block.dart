f() {
  // LINT :5
    var a;
  var b;

  {
    // LINT :7
      var a;
    var b;
  }

  // LINT :4 +3:4
   {
     //
   }

  // LINT :4
   {
     //
  }

  // LINT +3:4
  {
    //
   }
}