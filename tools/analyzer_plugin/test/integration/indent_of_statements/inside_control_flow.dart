f1() {
  for (;false;)
    null;
  for (;false;)
     // LINT :6
     null;
  for (;false;) {
    null;
     // LINT :6
     null;
  }

  if (b)
    null;
  if (b)
    null;
  if (b)
     // LINT :6
     null;
  if (b) {
    null;
     // LINT :6
     null;
  }

  while (b)
    null;
  while (b)
    null;
  while (b)
     // LINT :6
     null;
  while (b) {
    null;
     // LINT :6
     null;
  }
}

var b;