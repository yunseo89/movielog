import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,

      // 1️⃣ ColorScheme 연결 (색상표 세팅)
      colorScheme: ColorScheme.fromSeed(
        //fromseed는 메인 색상인 시드 컬러를 던져주면, 플러터가 알아서 그 색상과 잘 어울리는 다른 보조 
        //색상들을 자동으로 뽑아주는 역할을 함

        seedColor: AppColors.primary, //시드 컬러 = 보라색
        primary: AppColors.primary,
        surface: AppColors.surface
      ),

      // 2️⃣ TextTheme 연결 (글자 스타일 세팅 - 필요시 세부 지정)
      fontFamily: 'Manrope',

      // 3️⃣ AppBarTheme 연결 (상단바 공통 스타일 세팅)
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0, // 상단바 그림자 없애기 등 공통 디자인
        centerTitle: true,
      ),
    );
  }
}