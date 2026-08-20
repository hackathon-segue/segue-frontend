String displayProductColor(String color) {
  return switch (color) {
    '블랙' => 'Black',
    '베이지' => 'Beige',
    '브라운' => 'Brown',
    '꼬냑' || '코냑' => 'Cognac',
    '오렌지' => 'Orange',
    '오렌지 에이드' => 'Orange Aid',
    '그린' => 'Green',
    '네이비' => 'Navy',
    '다크브라운' => 'Dark Brown',
    '카멜' => 'Camel',
    '카키' => 'Khaki',
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
