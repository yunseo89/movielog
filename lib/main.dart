import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'theme/app_theme.dart';
import 'sign_up_screen.dart';

void main() => runApp(const MovieLogApp());

// ==========================================
// 🚀 [데이터 모델 및 Mock Data 업데이트]
// ==========================================
class Movie {
  final String id;
  final String title;
  final String genre;
  final String year;
  final double rating;
  final String synopsis;
  final String? duration; // 재생 시간 추가

  Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.rating,
    required this.synopsis,
    this.duration,
  });
}

// 시안에 맞춘 Mock 데이터
final List<Movie> mockMovies = [
  Movie(
    id: '1', 
    title: '별빛 아래 우리', 
    genre: '로맨스 · 드라마', // 👈 이 부분이 그대로 유지되도록 설정
    year: '2023', 
    rating: 4.8, 
    duration: '120분', // 👈 시간이 정상적으로 들어가도록 설정
    synopsis: '바쁜 현대 사회 속에서 서로의 존재를 잊고 살아가던 두 남녀가 우연한 계기로 작은 천문대에서 만나게 됩니다.'
  ),
  Movie(id: '2', title: '우주의 끝에서', genre: 'SF', year: '2024', rating: 4.2, synopsis: '미지의 행성을 탐사하던 중 발견한 고대 유적의 비밀.'),
  Movie(id: '3', title: '기억의 숲', genre: '애니메이션', year: '2022', rating: 4.9, synopsis: '잃어버린 기억을 찾아 몽환적인 숲으로 떠나는 모험.'),
  Movie(id: '4', title: '밤의 그림자', genre: '스릴러', year: '2024', rating: 3.8, synopsis: '어두운 도시의 이면에서 벌어지는 숨 막히는 추격전.'),
  Movie(id: '5', title: '봄날의 커피', genre: '로맨스', year: '2021', rating: 4.5, synopsis: '따뜻한 봄날, 카페에서 시작된 인연.'),
  Movie(id: '6', title: '도시의 선', genre: '다큐멘터리', year: '2023', rating: 4.1, synopsis: '현대 건축물들이 그리는 도심 속 선의 미학.'),
];

final List<Movie> popularMovies = [
  Movie(id: '101', title: '마션 레스큐', genre: 'SF', year: '2024', rating: 9.6, synopsis: ''),
  Movie(id: '102', title: '스파이 코드', genre: '액션', year: '2024', rating: 9.2, synopsis: ''),
  Movie(id: '103', title: '비오는 날의 기적', genre: '드라마', year: '2023', rating: 8.9, synopsis: ''),
];

Movie findMovieById(String id) {
  return [...mockMovies, ...popularMovies].firstWhere((movie) => movie.id == id, orElse: () => mockMovies.first);
}

// ==========================================
// 🚀 [GoRouter 라우팅 설정]
// ==========================================
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const StartScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/movies',
          builder: (context, state) => const MovieListScreen(),
          routes: [
            GoRoute(
              path: ':movieId',
              builder: (context, state) => MovieDetailScreen(movieId: state.pathParameters['movieId']!),
            ),
          ],
        ),
        GoRoute(path: '/my', builder: (context, state) => const ProfileScreen()),
      ],
    ),
  ],
);

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
    );
  }
}

// ==========================================
// 🚀 [하단 네비게이션 바] - 시안의 보라색 둥근 선택 배경 적용
// ==========================================
class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    int currentIndex = 0;
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/movies')) currentIndex = 1;
    if (location.startsWith('/my')) currentIndex = 2;

    return Scaffold(
      body: child,
      // 시안과 동일한 Material 3 네비게이션 바
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          if (index == 0) context.go('/home');
          if (index == 1) context.go('/movies');
          if (index == 2) context.go('/my');
        },
        indicatorColor: Colors.deepPurple.shade100, // 선택 시 보라색 타원 배경
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: Colors.deepPurple), label: '홈'),
          NavigationDestination(icon: Icon(Icons.movie_outlined), selectedIcon: Icon(Icons.movie, color: Colors.deepPurple), label: '영화'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: Colors.deepPurple), label: '마이'),
        ],
      ),
    );
  }
}

// ==========================================
// 🚀 [1. 시작 화면] (유지)
// ==========================================
class StartScreen extends StatelessWidget { 
  const StartScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const SizedBox(height: 32),
                  const Text('FLUTTER 1주차'),
                  const SizedBox(height: 64),
                  const Icon(Icons.movie_creation, size: 72, color: Colors.deepPurple),
                  const SizedBox(height: 32),
                  Text('영화의 순간을\n기록하세요', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요', textAlign: TextAlign.center),
                ],
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/signup'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                  child: const Text('시작하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 🚀 [2. 홈 화면] - 히어로 카드 및 인기 영화 뱃지 디자인 적용
// ==========================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final heroMovie = mockMovies[0];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'MovieLog', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)
        ),
        centerTitle: false, // 👈 로고가 중앙에 있지 않고 왼쪽으로 가도록 설정!
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87), 
            onPressed: () {}
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '오늘은 어떤\n영화를 볼까요?', 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3)
            ),
            const SizedBox(height: 20),
            
            // 🎬 히어로 무비 카드
            GestureDetector(
              onTap: () => context.push('/movies/${heroMovie.id}'),
              child: Container(
                width: double.infinity,
                height: 400,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey.shade900,
                ),
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: Center(
                        child: Icon(Icons.image, color: Colors.white24, size: 80)
                      )
                    ),
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter, 
                            end: Alignment.topCenter, 
                            colors: [Colors.black.withOpacity(0.9), Colors.transparent]
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.9), 
                                borderRadius: BorderRadius.circular(12)
                              ),
                              child: const Text('추천 신작', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 8),
                            Text(heroMovie.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            // 👇 null 대신 장르와 재생시간이 정상적으로 출력되도록 수정
                            // 👈 장르와 시간이 중간에 잘리지 않고 '로맨스 · 드라마 · 120분' 형태로 온전히 출력됩니다!
                            Text(
                              '${heroMovie.genre} · ${heroMovie.duration ?? ''}', 
                              style: const TextStyle(color: Colors.white70, fontSize: 14)
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => context.push('/movies/${heroMovie.id}'),
                                icon: const Icon(Icons.info_outline, size: 18),
                                label: const Text('상세보기', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple, 
                                  foregroundColor: Colors.white, 
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('인기 영화', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {},
                  child: const Text('전체보기 >', style: TextStyle(color: Colors.deepPurple)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: popularMovies.length,
                itemBuilder: (context, index) {
                  final movie = popularMovies[index];
                  return GestureDetector(
                    onTap: () => context.push('/movies/${movie.id}'),
                    child: Container(
                      width: 130,
                      margin: const EdgeInsets.only(right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12)),
                                  child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
                                ),
                                Positioned(
                                  top: 0, left: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: const BoxDecoration(
                                      color: Colors.black87, 
                                      borderRadius: BorderRadius.only(topLeft: Radius.circular(12), bottomRight: Radius.circular(12))
                                    ),
                                    child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(movie.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text('${movie.rating}', style: const TextStyle(color: Colors.black87, fontSize: 13)),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 🚀 [3. 영화 목록 화면] - 상단바 정렬, 칩 디자인, 평점 뱃지 적용
// ==========================================
class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});
  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final List<String> genres = ['전체', '드라마', 'SF', '애니메이션', '스릴러'];
  String selectedGenre = '전체';

  @override
  Widget build(BuildContext context) {
    final filteredMovies = selectedGenre == '전체' ? mockMovies : mockMovies.where((m) => m.genre.contains(selectedGenre)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('영화', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        centerTitle: false, // 좌측 정렬
        actions: [IconButton(icon: const Icon(Icons.search, color: Colors.black54), onPressed: () {})],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: genres.map((genre) {
                final isSelected = selectedGenre == genre;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(genre),
                    selected: isSelected,
                    onSelected: (selected) { if (selected) setState(() => selectedGenre = genre); },
                    selectedColor: Colors.deepPurple,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: isSelected ? Colors.deepPurple : Colors.grey.shade300),
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 16, mainAxisSpacing: 24,
              ),
              itemCount: filteredMovies.length,
              itemBuilder: (context, index) {
                final movie = filteredMovies[index];
                return GestureDetector(
                  onTap: () => context.push('/movies/${movie.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12)),
                              child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
                            ),
                            // 우측 상단 별점 뱃지
                            Positioned(
                              top: 8, right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.white, size: 12),
                                    const SizedBox(width: 4),
                                    Text('${movie.rating}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(movie.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1),
                      const SizedBox(height: 4),
                      Text('${movie.year} · ${movie.genre.split(' · ')[0]}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 🚀 [4. 영화 상세 화면] (유지)
// ==========================================
class MovieDetailScreen extends StatefulWidget {
  final String movieId;
  const MovieDetailScreen({super.key, required this.movieId});
  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool isFavorite = false;

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('평점 남기기'),
          content: RatingBar.builder(
            initialRating: 3, minRating: 0.5, direction: Axis.horizontal, allowHalfRating: true,
            itemCount: 5, itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: (rating) {},
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('평점이 등록되었습니다.')));
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final movie = findMovieById(widget.movieId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cinema Archive', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_border, color: isFavorite ? Colors.deepPurple : Colors.black),
            onPressed: () {
              setState(() => isFavorite = !isFavorite);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isFavorite ? '즐겨찾기에 추가되었습니다.' : '즐겨찾기에서 삭제되었습니다.')));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 300, color: Colors.grey.shade900, child: const Center(child: Icon(Icons.image, size: 80, color: Colors.white24))),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(movie.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${movie.year} · ${movie.genre}', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: movie.rating, itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                        itemCount: 5, itemSize: 24.0,
                      ),
                      const SizedBox(width: 8),
                      Text(movie.rating.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('시놉시스', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(movie.synopsis, style: const TextStyle(height: 1.5)),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showRatingDialog,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('평점 남기기', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 🚀 [5. 마이페이지] - 테두리, 배경색 등 시안 완벽 반영
// ==========================================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 프로필'),
        centerTitle: false,
        titleTextStyle: const TextStyle(color: Colors.deepPurple, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ProfileHeader(),
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                width: 120,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.deepPurple),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('프로필 수정', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Expanded(child: StatItem(label: '본 영화', value: '342')),
                SizedBox(width: 16),
                Expanded(child: StatItem(label: '평점', value: '4.2')),
                SizedBox(width: 16),
                Expanded(child: StatItem(label: '즐겨찾기', value: '58')),
              ],
            ),
            const SizedBox(height: 40),
            Text('선호하는 장르', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                _buildGenreChip('드라마'),
                _buildGenreChip('SF'),
                _buildGenreChip('애니메이션'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        children: [
          // 시안의 보라색 테두리가 있는 프로필 이미지 적용
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
            child: const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 60, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          Text('무비러버', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('매주 주말엔 영화관으로 출근하는 프로 관람객. 좋\n은 영화를 보고 기록하는 것을 좋아합니다.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black87, height: 1.4)),
        ],
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  const StatItem({super.key, required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50.withOpacity(0.5), // 시안의 아주 연한 보라색 배경
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.shade100, width: 0.5),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.black87, fontSize: 13)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple, fontSize: 22)),
        ],
      ),
    );
  }
}

Widget _buildGenreChip(String title) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.deepPurple.shade50, // 연한 보라색 배경
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(title, style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 13)),
  );
}