import 'package:flutter/material.dart';

class Movie {
  final String title;
  Movie(this.title); //Movie의 객체는 반드시 title이라는 문자열 정보를 가지도록 정의함
  }

void main() {

  List<Movie> movietitle = [
  Movie('파묘'),
  Movie('공조'),
  Movie('범죄도시'),
]; //영화 객체 3개를 만들고, 이걸 List<movie>에 담음(객체를 담음)

//for문 사용 
for(var i = 0; i < movietitle.length; i++) {
  print(movietitle[i].title); //영화 객체의 title을 출력
}

String? nickname;
String safeNickname = nickname ?? '회원님'; //nickname이 null이면 '회원님'을
print(safeNickname); //출력

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(child: Text('Hello MovieLog!')),
      ),
    ),
  );
}