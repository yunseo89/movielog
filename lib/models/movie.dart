class Movie {
  const Movie({
    required this.title,
    required this.genre,
    required this.year,
    required this.rating,
    required this.imagePath,
    this.description = '',
  });

  final String title;
  final String genre;
  final int year;
  final double rating;
  final String imagePath;
  final String description;
}

const mockMovies = <Movie>[
  Movie(
    title: '별빛 아래 우리',
    genre: '드라마',
    year: 2024,
    rating: 4.5,
    imagePath: 'assets/images/posters/hero_under_the_starlight.jpg',
    description: '바쁜 현대 사회 속에서 서로의 존재를 잊고 살아가던 두 남녀가 작은 우연을 계기로 다시 만나며 시작되는 이야기입니다.',
  ),
  Movie(
    title: '스파이 코드',
    genre: 'SF',
    year: 2024,
    rating: 4.2,
    imagePath: 'assets/images/posters/poster_abyss_walker.jpg',
    description: '미지의 세계를 탐험하며 자신의 기억을 찾아가는 SF 영화입니다.',
  ),
  Movie(
    title: '공허의 끝에서',
    genre: 'SF',
    year: 2024,
    rating: 4.2,
    imagePath: 'assets/images/posters/poster_echoes_of_the_void.jpg',
    description: '우주 깊은 곳에서 들려온 정체불명의 신호를 둘러싼 이야기입니다.',
  ),
  Movie(
    title: '네 번째 오후',
    genre: '드라마',
    year: 2021,
    rating: 4.5,
    imagePath: 'assets/images/posters/poster_fourth_afternoon.jpg',
    description: '평범한 오후에 찾아온 작은 변화와 관계에 관한 이야기입니다.',
  ),
  Movie(
    title: '밤의 그림자',
    genre: '스릴러',
    year: 2024,
    rating: 3.8,
    imagePath: 'assets/images/posters/poster_night_shadows.jpg',
    description: '밤마다 반복되는 이상한 사건의 진실을 추적하는 스릴러입니다.',
  ),
  Movie(
    title: '기억의 숲',
    genre: '애니메이션',
    year: 2022,
    rating: 4.9,
    imagePath: 'assets/images/posters/poster_whispering_woods.jpg',
    description: '숲의 목소리를 들을 수 있는 주인공의 판타지 모험입니다.',
  ),
];
