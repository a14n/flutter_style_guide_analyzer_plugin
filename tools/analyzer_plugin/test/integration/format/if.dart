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

  if (m) {
    m;
  } else {
    m;
  }
  // LINT +4:6
  if (m) {
    m;
  } else {
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
  }else {
    m;
  }
  // LINT +3:4
  if (m) {
    m;
  }  else {
    m;
  }
  // LINT +3:9
  if (m) {
    m;
  } else{
    m;
  }
  // LINT +3:9
  if (m) {
    m;
  } else  {
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

  // allow multi-line condition on its own lines but with block
  if (
    m &&
    m
  ) {
    m;
  }
  // LINT :7 +2:6
  if (
    m
  ) {
    m;
  }
  // LINT +5:5
  if (
    m &&
    m
  )
    m;
  // LINT +2:6
  if (
     m &&
     m
  ) {
    m;
  }
  // LINT +2:4
  if (
   m &&
   m
  ) {
    m;
  }
}

test_block_consistancy() {
  if (m)
    m;
  else
    m;
  if (m) {
    m;
  } else {
    m;
  }
  // LINT +2:5
  if (m)
    m;
  else {
    m;
  }
  // LINT +4:5
  if (m) {
    m;
  } else
    m;

  if (m) {
    m;
  } else if (m) {
    m;
  } else {
    m;
  }
  // LINT +2:5 +6:5
  if (m)
    m;
  else if (m) {
    m;
  } else
    m;
  // LINT +4:5 +6:5
  if (m) {
    m;
  } else if (m)
    m;
  else
    m;
}