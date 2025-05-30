import 'package:collection/collection.dart';
import 'package:delivery_app/common/model/cursor_pagination_model.dart';
import 'package:delivery_app/common/provider/pagination_provider.dart';
import 'package:delivery_app/restaurant/model/restaurant_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Repository/restaurant_repository.dart';

final restaurantDetailProvider =
    Provider.family<RestaurantModel?, String>((ref, id) {
  final state = ref.watch(restaurantProvider);

  if (state is! CursorPagination) {
    return null;
  }

  return state.data.firstWhereOrNull((element) => element.id == id);
});

final restaurantProvider =
    StateNotifierProvider<RestaurantStateNotifier, CursorPaginationBase>((ref) {
  final repository = ref.watch(restaurantRepositoryProvider);
  final notifier = RestaurantStateNotifier(repository: repository);
  return notifier;
});

class RestaurantStateNotifier
    extends PaginationProvider<RestaurantModel, RestaurantRepository> {
  RestaurantStateNotifier({
    required super.repository,
  });

  getDetail({
    required String id,
  }) async {
    //만약에 아직 데이터가 하나도 없는 상태라면 (CursorPagination이 아니라면)
    //데이터를 가져오는 시도를 한다.
    if (state is! CursorPagination) {
      await paginate();
    }

    // state가 CurosrPagination이 아닐 때 그냥 null 반환 / return ;
    if (state is! CursorPagination) {
      return;
    }

    final pState = state as CursorPagination;

    final response = await repository.getRestaurantDetail(id: id);

    // [RestaurantModel(1), RestaurantModel(2), RestaurantModel(3)]
    // 요청 id: 10
    // list.where((e) => e.id == 10) 데이터 x
    // 데이터가 없을때는 그냥 캐시의 끝에다가 데이터를 추가해버린다.
    //[RestaurantModel(1), RestaurantModel(2), RestaurantModel(3),
    //RestaurantModel(10)]
    if (pState.data.where((e) => e.id == id).isEmpty) {
      state = pState.copyWith(
        data: <RestaurantModel>[
          ...pState.data,
          response,
        ],
      );
    } else {
      //[RestaurantModel(1), RestaurantModel(2), RestaurantModel(3)]
      //id : 2인 친구를 Detail모델을 가져와라
      //getDetail(id:2);
      //[RestaurantModel(1), RestaurantDetailModel(2), RestaurantDetailModel(3)]
      state = pState.copyWith(
        data: pState.data
            .map<RestaurantModel>(
              (e) => e.id == id ? response : e,
            )
            .toList(),
      );
    }
  }
}
