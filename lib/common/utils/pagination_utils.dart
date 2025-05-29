import 'package:flutter/cupertino.dart';

import '../provider/pagination_provider.dart';

class PaginationUtils {
  //현재 위치가
  //최대 길이보다 조금 덜되는 위치까지 왔다면
  //새로운 데이터를 추가요청
  static paginate({
    required ScrollController controller,
    required PaginationProvider provider,
  }) {
    if (controller.offset > controller.position.maxScrollExtent - 300) {
      provider.paginate(fetchMore: true);
    }
  }
}
