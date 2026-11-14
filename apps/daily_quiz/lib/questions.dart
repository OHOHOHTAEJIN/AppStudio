class QuizQuestion {
  const QuizQuestion(this.category, this.prompt, this.answers, this.correct);
  final String category;
  final String prompt;
  final List<String> answers;
  final int correct;
}

const questionBank = <QuizQuestion>[
  QuizQuestion('과학', '물의 화학식은?', ['CO₂','H₂O','NaCl','O₂'], 1),
  QuizQuestion('과학', '지구의 공전 주기는?', ['하루','약 1년','약 1개월','약 10년'], 1),
  QuizQuestion('과학', '진공에서 소리는?', ['전달된다','더 빨라진다','전달되지 않는다','느려진다'], 2),
  QuizQuestion('과학', '빛의 삼원색이 아닌 것은?', ['빨강','초록','파랑','노랑'], 3),
  QuizQuestion('과학', '식물이 광합성할 때 흡수하는 기체는?', ['산소','이산화탄소','질소','수소'], 1),
  QuizQuestion('과학', '태양계에서 가장 큰 행성은?', ['화성','목성','금성','지구'], 1),
  QuizQuestion('과학', '혈액을 순환시키는 기관은?', ['폐','간','심장','위'], 2),
  QuizQuestion('과학', '표준 기압에서 물의 어는점은?', ['0℃','20℃','50℃','100℃'], 0),
  QuizQuestion('지리', '대한민국의 수도는?', ['대전','부산','서울','인천'], 2),
  QuizQuestion('지리', '세계에서 가장 넓은 대륙은?', ['아시아','유럽','오세아니아','남극'], 0),
  QuizQuestion('지리', '적도가 지나는 대륙은?', ['유럽','남아메리카','남극','북아메리카'], 1),
  QuizQuestion('지리', '일본의 수도는?', ['오사카','교토','도쿄','삿포로'], 2),
  QuizQuestion('지리', '한반도 동쪽의 바다는?', ['동해','서해','카스피해','홍해'], 0),
  QuizQuestion('지리', '이집트가 속한 대륙은?', ['아시아','아프리카','유럽','남미'], 1),
  QuizQuestion('지리', '세계에서 가장 넓은 대양은?', ['대서양','인도양','태평양','북극해'], 2),
  QuizQuestion('IT', 'CPU의 주 역할은?', ['연산·명령 처리','화면 보호','파일 인쇄','소리 증폭'], 0),
  QuizQuestion('IT', 'HTTPS의 S는?', ['Simple','Secure','System','Service'], 1),
  QuizQuestion('IT', '2진수의 숫자는?', ['0과 1','1과 2','0과 9','2와 8'], 0),
  QuizQuestion('IT', '웹페이지의 구조를 정의하는 언어는?', ['CSS','HTML','SQL','JSON'], 1),
  QuizQuestion('IT', 'JSON은 주로 무엇에 쓰이나?', ['이미지 압축','데이터 교환','전원 공급','CPU 냉각'], 1),
  QuizQuestion('IT', 'Git의 주요 용도는?', ['버전 관리','전기 관리','밝기 제어','날씨'], 0),
  QuizQuestion('IT', 'RAM은 일반적으로?', ['인쇄 장치','주기억장치','외부 디스크','통신 안테나'], 1),
  QuizQuestion('생활', '1시간은 몇 분?', ['30','60','90','120'], 1),
  QuizQuestion('생활', '1kg은 몇 g?', ['10','100','1000','10000'], 2),
  QuizQuestion('생활', '윤년의 2월 마지막 날은?', ['27일','28일','29일','30일'], 2),
  QuizQuestion('생활', '일주일은 며칠?', ['5','6','7','8'], 2),
  QuizQuestion('생활', '직각은 몇 도?', ['45','90','180','360'], 1),
  QuizQuestion('생활', '정사각형의 네 변 길이는?', ['다 다르다','모두 같다','두 변만 같다','관계없다'], 1),
  QuizQuestion('생활', '12개월은?', ['1분기','반년','1년','10년'], 2),
  QuizQuestion('생활', '신호등의 빨간불은 보통?', ['진행','정지','좌회전','가속'], 1),
];
