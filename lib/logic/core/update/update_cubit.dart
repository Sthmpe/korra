import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/update_service.dart';

class UpdateState {
  final bool isUpdateRequired;
  final String? updateUrl;
  final String? version;

  const UpdateState({this.isUpdateRequired = false, this.updateUrl, this.version});
}

class UpdateCubit extends Cubit<UpdateState> {
  final UpdateService _service = UpdateService();

  UpdateCubit() : super(const UpdateState());

  Future<void> checkForUpdate() async {
    final result = await _service.check();
    
    if (result.isBlocked) {
      emit(UpdateState(
        isUpdateRequired: true, 
        updateUrl: result.updateUrl, 
        version: result.latestVersion
      ));
    } else {
      // Ensure we clear the block if they updated
      if (state.isUpdateRequired) {
        emit(const UpdateState(isUpdateRequired: false));
      }
    }
  }
}