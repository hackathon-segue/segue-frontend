String displayProductColor(String color) {
  final String normalized = color.trim().toLowerCase().replaceAll(' ', '');
  return switch (normalized) {
    'black' || '블랙' => 'Black',
    'beige' || '베이지' => 'Beige',
    'brown' || '브라운' => 'Brown',
    'cognac' || '꼬냑' || '코냑' => 'Cognac',
    'camel' || '카멜' => 'Camel',
    'orange' || '오렌지' => 'Orange',
    'orangeaid' || '오렌지에이드' => 'Orange Aid',
    'green' || '그린' => 'Green',
    'khaki' || '카키' => 'Khaki',
    'navy' || '네이비' => 'Navy',
    'pink' || '핑크' => 'Pink',
    'white' || '화이트' => 'White',
    'gray' || 'grey' || '그레이' => 'Gray',
    'darkbrown' || '다크브라운' => 'Dark Brown',
    _ => color.trim(),
  };
}

String displayProductSize(String size) {
  final String normalized = size.trim().toLowerCase().replaceAll(' ', '');
  return switch (normalized) {
    '미니' => 'Mini',
    'small' || '스몰' => 'S',
    'medium' || '미디움' => 'M',
    'large' || '라지' => 'L',
    'onesize' || '원사이즈' || 'free' || '프리' => 'One Size',
    _ => size.trim(),
  };
}
