f1() {
  for (;false;)
    null;
  for (;false;)
     // LINT :5
     null;
  for (;false;) {
    null;
     // LINT :5
     null;
  }

  if (b)
    null;
  if (b)
    null;
  if (b)
     // LINT :5
     null;
  if (b) {
    null;
     // LINT :5
     null;
  }

  while (b)
    null;
  while (b)
    null;
  while (b)
     // LINT :5
     null;
  while (b) {
    null;
     // LINT :5
     null;
  }
}

var b;