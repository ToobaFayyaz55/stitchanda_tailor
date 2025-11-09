import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:stichanda_tailor/data/models/driver_model.dart';
import 'package:stichanda_tailor/data/repository/ride_repo.dart';

// ==================== STATES ====================

sealed class RideState extends Equatable {
  const RideState();

  @override
  List<Object?> get props => [];
}

class RideInitial extends RideState {
  const RideInitial();
}

class RideLoading extends RideState {
  const RideLoading();
}

class RideSearching extends RideState {
  const RideSearching();
}

class AvailableDriversLoaded extends RideState {
  final List<Driver> drivers;

  const AvailableDriversLoaded(this.drivers);

  @override
  List<Object?> get props => [drivers];
}

class RideRequested extends RideState {
  const RideRequested();
}

class DriverAssigned extends RideState {
  final Driver driver;

  const DriverAssigned(this.driver);

  @override
  List<Object?> get props => [driver];
}

class DriverPickedUp extends RideState {
  const DriverPickedUp();
}

class RideCompleted extends RideState {
  const RideCompleted();
}

class RideError extends RideState {
  final String message;

  const RideError(this.message);

  @override
  List<Object?> get props => [message];
}

// ==================== CUBIT ====================

class RideCubit extends Cubit<RideState> {
  final RideRepo rideRepo;

  RideCubit({required this.rideRepo}) : super(const RideInitial());

  // ==================== DRIVER FETCHING ====================

  /// Fetch all available drivers
  Future<void> fetchAvailableDrivers() async {
    try {
      emit(const RideSearching());
      final drivers = await rideRepo.getAvailableDrivers();
      if (drivers.isEmpty) {
        emit(const RideError('No drivers available at the moment'));
      } else {
        emit(AvailableDriversLoaded(drivers));
      }
    } catch (e) {
      emit(RideError('Failed to fetch drivers: ${e.toString()}'));
    }
  }

  /// Get a single driver by ID
  Future<Driver?> getDriverById(String driverId) async {
    try {
      return await rideRepo.getDriverById(driverId);
    } catch (e) {
      emit(RideError('Failed to fetch driver: ${e.toString()}'));
      return null;
    }
  }

  // ==================== RIDE REQUEST OPERATIONS ====================

  /// Tailor presses "Call Driver" button
  /// This requests a driver for pickup
  Future<void> requestDriver({
    required String detailsId,
    required String tailorId,
  }) async {
    try {
      emit(const RideLoading());
      await rideRepo.requestDriver(
        detailsId: detailsId,
        tailorId: tailorId,
      );
      emit(const RideRequested());
      // Fetch available drivers after requesting
      await fetchAvailableDrivers();
    } catch (e) {
      emit(RideError('Failed to request driver: ${e.toString()}'));
    }
  }

  /// Tailor selects and assigns a driver to the order
  /// This transitions status from 6 → 7
  Future<void> assignDriver({
    required String detailsId,
    required String driverId,
    required String tailorId,
  }) async {
    try {
      emit(const RideLoading());
      await rideRepo.assignDriver(
        detailsId: detailsId,
        driverId: driverId,
        tailorId: tailorId,
      );

      // Fetch assigned driver details
      final driver = await rideRepo.getDriverById(driverId);
      if (driver != null) {
        emit(DriverAssigned(driver));
      } else {
        emit(const RideError('Driver details not found after assignment'));
      }
    } catch (e) {
      emit(RideError('Failed to assign driver: ${e.toString()}'));
    }
  }

  /// Mark that driver has picked up from tailor
  /// Status transition: 7 → 8
  Future<void> markPickedFromTailor({
    required String detailsId,
    required String driverId,
  }) async {
    try {
      emit(const RideLoading());
      await rideRepo.markPickedFromTailor(
        detailsId: detailsId,
        driverId: driverId,
      );
      emit(const DriverPickedUp());
    } catch (e) {
      emit(RideError('Failed to mark pickup: ${e.toString()}'));
    }
  }

  /// Mark delivery complete
  /// Status transition: 8 → 9
  Future<void> markDeliveryComplete({
    required String detailsId,
  }) async {
    try {
      emit(const RideLoading());
      await rideRepo.markDeliveryComplete(detailsId: detailsId);
      emit(const RideCompleted());
    } catch (e) {
      emit(RideError('Failed to complete delivery: ${e.toString()}'));
    }
  }

  // ==================== UI HELPER METHODS ====================

  /// Get human-readable text for ride status
  static String getStatusText(int status) {
    switch (status) {
      case 5:
        return 'Order Completed - Ready for Pickup';
      case 6:
        return 'Searching for Drivers...';
      case 7:
        return 'Driver Assigned - Waiting for Pickup';
      case 8:
        return 'Driver Picked Up';
      case 9:
        return 'Delivered to Customer';
      case 11:
        return 'Customer Self-Pickup';
      default:
        return 'Unknown Status';
    }
  }

  /// Check if tailor can request a driver
  static bool canRequestDriver(int status) {
    return status == 5;
  }

  /// Check if tailor can assign a driver
  static bool canAssignDriver(int status) {
    return status == 6;
  }
}

