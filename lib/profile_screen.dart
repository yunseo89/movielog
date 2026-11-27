import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'view_models/auth_view_model.dart';
import 'view_models/session_ratings_view_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final member = auth.member;
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '로그아웃',
            onPressed: auth.storageCleanupInProgress ? null : auth.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 48,
                backgroundImage: AssetImage(
                  'assets/images/profile/profile.jpg',
                ),
              ),
              const SizedBox(height: 20),
              Text(
                member?.nickname ??
                    (auth.memberStatus == MemberLoadStatus.error
                        ? '내 정보를 확인해 주세요.'
                        : '내 정보를 불러오는 중이에요.'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (member != null) Text(member.email),
              if (auth.memberStatus == MemberLoadStatus.error) ...[
                const SizedBox(height: 12),
                Text(auth.message ?? '내 정보를 불러오지 못했어요.'),
                TextButton(
                  onPressed: () => auth.loadMember(force: true),
                  child: const Text('내 정보 다시 불러오기'),
                ),
              ],
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: member == null
                    ? null
                    : () => context.push('/my/profile/edit'),
                child: const Text('프로필 수정'),
              ),
              const SizedBox(height: 24),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.star_outline),
                  title: const Text('이번 로그인에서 등록한 평점'),
                  subtitle: Text(
                    '${context.watch<SessionRatingsViewModel>().ratings.length}개',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/my/ratings'),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '앱을 다시 실행하거나 로그아웃하면 이 목록은 비워집니다. 저장한 평점은 서버에 남아 있습니다.',
                style: TextStyle(color: Colors.grey),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.bookmark_outline),
                  title: const Text('내 즐겨찾기'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/my/favorites'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
