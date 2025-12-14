import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart'; // Optional, for easy state comparison

// --- EVENTS ---
abstract class PinEvent {}

class PinDigitEntered extends PinEvent {
  final String digit;
  PinDigitEntered(this.digit);
}

class PinDigitDeleted extends PinEvent {}

class PinReset extends PinEvent {} // Reset to start (e.g. on mismatch error)

// --- STATES ---
enum PinStage { entering, confirming, verified }

class PinState {
  final String input;
  final PinStage stage;
  final String? firstPin; // Only used during creation
  final bool hasError;    // ✅ New: Just a flag, not a whole new state

  const PinState({
    this.input = "",
    this.stage = PinStage.entering,
    this.firstPin,
    this.hasError = false,
  });

  PinState copyWith({
    String? input,
    PinStage? stage,
    String? firstPin,
    bool? hasError,
  }) {
    return PinState(
      input: input ?? this.input,
      stage: stage ?? this.stage,
      firstPin: firstPin ?? this.firstPin,
      hasError: hasError ?? this.hasError,
    );
  }
}

// --- BLOC ---
class TransactionPinBloc extends Bloc<PinEvent, PinState> {
  final bool isCreating;
  
  TransactionPinBloc({required this.isCreating}) : super(const PinState()) {
    on<PinDigitEntered>(_onDigitEntered);
    on<PinDigitDeleted>(_onDigitDeleted);
    on<PinReset>(_onReset);
  }

  Future<void> _onDigitEntered(PinDigitEntered event, Emitter<PinState> emit) async {
    // If error is currently showing, ignore input or reset immediately
    if (state.hasError) return; 

    final newInput = state.input + event.digit;
    if (newInput.length > 4) return;

    // Just update input for now
    emit(state.copyWith(input: newInput));

    // CHECK COMPLETION
    if (newInput.length == 4) {
      await _handleCompletion(emit, newInput);
    }
  }

  Future<void> _handleCompletion(Emitter<PinState> emit, String input) async {
    // 1. VERIFY MODE (Existing Pin)
    if (!isCreating) {
      // In real verify mode, we return immediately.
      // The parent PayoutBloc checks validity. 
      // So we just stay here and let the UI listener handle the submission.
      return; 
    }

    // 2. CREATE MODE (New Pin)
    if (state.stage == PinStage.entering) {
      // Finished Step 1 -> Move to Confirm
      emit(state.copyWith(
        stage: PinStage.confirming,
        firstPin: input,
        input: "", // Clear for step 2
      ));
    } 
    else if (state.stage == PinStage.confirming) {
      if (input == state.firstPin) {
        // MATCH!
        emit(state.copyWith(stage: PinStage.verified));
      } else {
        // MISMATCH! Trigger Error
        emit(state.copyWith(hasError: true)); // UI shows Red/Shake

        // Wait 1 second, then auto-reset
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Reset to Step 1 (Create) so they try again
        emit(const PinState(
          stage: PinStage.entering, // Go back to start
          input: "",
          hasError: false,
        ));
      }
    }
  }

  void _onDigitDeleted(PinDigitDeleted event, Emitter<PinState> emit) {
    if (state.input.isNotEmpty && !state.hasError) {
      emit(state.copyWith(input: state.input.substring(0, state.input.length - 1)));
    }
  }

  void _onReset(PinReset event, Emitter<PinState> emit) {
    emit(const PinState());
  }
}