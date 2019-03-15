var m;
test_thenExpression_indent() {
  if (m)
    m;
  // LINT +2:6
  if (m)
     m;

  if (m) {
    m;
  }
  // LINT +2:6
  if (m) {
     m;
  }
}
test_esleExpression_indent() {
  if (m)
    m;
  else
    m;
  // LINT +4:6
  if (m)
    m;
  else
     m;

  if (m)
    m;
  else {
    m;
  }
  // LINT +4:6
  if (m)
    m;
  else {
     m;
  }
}
test_spaces() {
  if (m)
    m;
  // LINT :5
  if(m)
    m;
  // LINT :7
  if ( m)
    m;
  // LINT :8
  if (m )
    m;
  // LINT :9
  if (m)  {
    m;
  }
  // LINT :9
  if (m){
    m;
  }

  // LINT +3:4
  if (m) {
    m;
  }else
    m;
  // LINT +3:4
  if (m) {
    m;
  }  else
    m;
  // LINT +3:7
  if (m)
    m;
  else{
    m;
  }
  // LINT +3:7
  if (m)
    m;
  else  {
    m;
  }

  // allow comment before else
  if (m)
    m;
  // comment
  else
    m;
  if (m) {
    m;
  }
  // comment
  else {
    m;
  }
}
