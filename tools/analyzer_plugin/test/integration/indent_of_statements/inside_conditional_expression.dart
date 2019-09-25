f1() {
  b
    ? () {
        null;
        // LINT :9
         null;
      }
    : () {
        null;
        // LINT :9
         null;
      };
}

bool b;