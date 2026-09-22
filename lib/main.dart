import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() => runApp(const MovieLogApp());

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light, //디자인 규칙 연결!
    home: const ProfileScreen(),
  );
}

class StartScreen extends StatelessWidget { 
  const StartScreen({super.key});

// 수정 시작

  @override
  Widget build(BuildContext context) { //위젯 1
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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

//스텝 3 수정
                  SvgPicture.asset(
                    'assets/logos/movielog_logo.svg',
                    width: 72,
                    height: 72,
                    semanticsLabel: 'MovieLog 로고',
                  ),
                
                  const SizedBox(height: 32),
                  Text(
                    '영화의 순간을\n기록하세요',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {}, // 1주차에는 화면 이동을 연결하지 않습니다.
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                  ),
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
// 🚀 [스텝 4] 프로필 화면 및 헤더 구현하기
// ==========================================

// 2️⃣ 프로필 전체 화면 (Scaffold 뼈대 제공)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) { //위젯 2
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 프로필'),
        centerTitle: false, //가운데를 원하면 true
        titleTextStyle: TextStyle(
        color: colors.primary, //수정
        ),
      ),
      body: SingleChildScrollView( //스크롤바를 만들어주는 위젯
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            //프로필 헤더
            const ProfileHeader(),

            //프로필 수정 버튼 추가
            const SizedBox(height: 32), // 8px 간격 단위 준수
            
            Center(
              child: SizedBox(
              width: 150,
              child: OutlinedButton( //워크북 요구사항 x
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                 side: BorderSide(color: colors.primary), // 보라색 테두리
                 shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // 8px 둥근 모서리
      ),
    ),
                child: Text('프로필 수정', style: TextStyle(color: colors.primary),
                ),
              ),
            ),
            ),

            const SizedBox(height: 32),
 
            // 2️⃣ 스텝 5에서 만든 통계 항목 1개 ('본 영화')
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround, //spaceBetween은 양 끝에 딱 붙이고,
              //남은 공간을 아이템들 사이에 똑같이 나누어주는 개념.. Around는 끝과 끝이 더 안쪽으로 들어옴
              children: const[ //아래 위젯 활용
                StatItem(label: '본 영화', value: '24'),
                StatItem(label: '평점', value: '4.8'), //미션 수행 - 통계 항목 채우기
                StatItem(label: '즐겨찾기', value: '12')
          ],
        ),
        const SizedBox(height: 32), // 8px 간격 단위 준수

        Text(
          '선호하는 장르',
           style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,  
            )
        ),
        const SizedBox(height: 12),

        Row(  //위젯을 추가해서 보라색 배경, 글자색, 둥근 모서리 단체 적용
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildGenreChip(context, '드라마'),
            SizedBox(width: 8), // 8px 간격 단위 준수
            _buildGenreChip(context, 'SF'),
            SizedBox(width: 8),
            _buildGenreChip(context, '애니메이션'),
  ]
  ),
          ]
        )
    )
    );
  }
}

// 3️⃣ 스텝 4의 핵심: 프로필 헤더 위젯 - 위에서 가져다 씀
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) { //위젯 3
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        children: [
          // ① 프로필 이미지 (CircleAvatar 사용)
         const CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage('assets/images/profile/profile.jpg'),
          ),
          const SizedBox(width: 16), // 8px 간격 단위 준수 (16px)

          // ② 닉네임 & ③ 소개글 영역 (세로로 쌓기)
        
                Text(
                  '무비러버', // 닉네임
                  style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8), // 8px 간격 단위 준수

                const Text(
                  '좋아하는 영화를 기록하고 있어요', //소개글
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
  }
}

// 스텝 5 통계 위젯
class StatItem extends StatelessWidget {
  const StatItem({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) { //위젯 4
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: colors.surface, 
        border: Border.all(color: Colors.grey.shade300), 
        borderRadius: BorderRadius.circular(12), 
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colors.primary)),
        ],
      ),
    );
  }
}

// 🎨 선호하는 장르 파트를 위한 위젯(컨테이너)
Widget _buildGenreChip(BuildContext context, String title) {
  final colors = Theme.of(context).colorScheme;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // 안쪽 여백
    decoration: BoxDecoration(
      color: colors.primaryContainer.withValues(alpha: 0.4), // 연한 보라색 배경(오래된 문법이라고 함)
      borderRadius: BorderRadius.circular(20),          // 둥근 캡슐형 모서리 (원하면 8 등 숫자로 변경 가능)
    ),
    child: Text(
      title,
      style: TextStyle(
        color: colors.primary,      // 글자색을 진한 보라색으로
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
