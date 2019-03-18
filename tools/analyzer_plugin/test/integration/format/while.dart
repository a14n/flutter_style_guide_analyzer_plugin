var m;
test_indent() {
  while (m)
    m;
  // LINT +2:6
  while (m)
     m;

  while (m) {
    m;
  }
  // LINT +2:6
  while (m) {
     m;
  }
}
test_spaces() async {
  while (m)
    m;
  // LINT :8
  while(m)
    m;
  // LINT :10
  while ( m)
    m;
  // LINT :11
  while (m )
    m;
  // LINT :12
  while (m)  {
    m;
  }
  // LINT :12
  while (m){
    m;
  }
}

