import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../data/repository/customer/customer_repository.dart';

// --- EVENTS ---
abstract class EditProfileEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class EditProfileSaved extends EditProfileEvent {
  final String address;
  final String city;
  final String stateName;

  EditProfileSaved({
    required this.address,
    required this.city,
    required this.stateName,
  });
  
  @override
  List<Object?> get props => [address, city, stateName];
}

// --- STATE ---
enum EditStatus { initial, submitting, success, failure }

class EditProfileState extends Equatable {
  final EditStatus status;
  final String? errorMessage;

  const EditProfileState({this.status = EditStatus.initial, this.errorMessage});

  @override
  List<Object?> get props => [status, errorMessage];
}

// --- BLOC ---
class EditProfileBloc extends Bloc<EditProfileEvent, EditProfileState> {
  final CustomerRepository repo;
  final String customerUid;

  EditProfileBloc({required this.repo, required this.customerUid}) : super(const EditProfileState()) {
    on<EditProfileSaved>(_onSave);
  }

  Future<void> _onSave(EditProfileSaved event, Emitter<EditProfileState> emit) async {
    emit(const EditProfileState(status: EditStatus.submitting));
    
    try {
      await repo.updateCustomerAddress(
        uid: customerUid,
        address: event.address,
        city: event.city,
        state: event.stateName,
      );
      emit(const EditProfileState(status: EditStatus.success));
    } catch (e) {
      emit(EditProfileState(status: EditStatus.failure, errorMessage: e.toString()));
    }
  }
}