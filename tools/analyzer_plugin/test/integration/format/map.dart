f() {
  var m;

  // empty map
  m = {};
  // LINT :8
  m = { };
  // LINT :8
  m = {
  };

  // one liner without trailing comma
  m = {'a': 1};
  // LINT :14
  m = {'a': 1,};

  // spaces in one liner
  m = {'a': 1};
  // LINT :12
  m = {'a':1};
  // LINT :8
  m = { 'a': 1};
  // LINT :11
  m = {'a' : 1};
  // LINT :12
  m = {'a':  1};
  // LINT :14
  m = {'a': 1 };

  // spaces in entries
  m = {
    'a': 1,
  };
  // LINT +2:8
  m = {
    'a' : 1,
  };
  // LINT +2:9
  m = {
    'a':1,
  };
  // LINT +2:9
  m = {
    'a':  1,
  };

  // spaces with trailing commas
  m = {
    'a': 1,
  };
  // LINT +2:11
  m = {
    'a': 1 ,
  };
  // LINT +2:11
  m = {
    'a': 1
    ,
  };

  // allow align values
  m = {
    'a':   1,
    'aa':  1,
    'aaa': 1,
  };
  // LINT +2:9 +3:10
  m = {
    'a':  1,
    'aa':  1,
    'aaa': 1,
  };

  // check type argument separation
  m = <String, int>{
    'a': 1,
  };
  // LINT :20
  m = <String, int> {
    'a': 1,
  };
}