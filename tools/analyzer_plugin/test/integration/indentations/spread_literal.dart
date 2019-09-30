var o;

var a = [
  if (o) ...[
    1,
    2,
  ] else if (o) ...[
    3,
    4,
  ] else ...[
    5,
    6,
  ],
  if (o) ...[
    // LINT :6
     1,
    2,
  ] else if (o) ...[
    3,
    // LINT :6
     4,
  ] else ...[
    5,
    // LINT :6
     6,
  ],
];

var b = [
  if (o &&
      o) ...[
    1,
    2,
  ] else if (o &&
      o) ...[
    3,
    4,
  ] else ...[
    5,
    6,
  ],
  if (o &&
      o) ...[
    // LINT :6
     1,
    2,
  ] else if (o &&
      o) ...[
    3,
    // LINT :6
     4,
  ] else ...[
    5,
    // LINT :6
     6,
  ],
];

var c = [
  for (var _ in o) ...[
    1,
    2,
  ],
  for (var _ in o) ...[
    1,
    // LINT :6
     2,
  ],
];