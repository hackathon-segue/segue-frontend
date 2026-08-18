String displayProductColor(String color) {
  return switch (color) {
    '블랙' => 'BLACK',
    '베이지' => 'BEIGE',
    '브라운' => 'BROWN',
    '꼬냑' || '코냑' => 'COGNAC',
    '오렌지' => 'ORANGE',
    '그린' => 'GREEN',
    _ => color,
  };
}

String displayProductSize(String size) {
  return switch (size) {
    '미니' => 'Mini',
    '스몰' => 'S',
    '미디움' => 'M',
    '라지' => 'L',
    _ => size,
  };
}
