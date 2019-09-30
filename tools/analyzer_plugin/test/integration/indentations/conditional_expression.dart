f1() {
  b
    ? () {
        null;
        // LINT :10
         null;
      }
    : () {
        null;
        // LINT :10
         null;
      };
}

bool b;