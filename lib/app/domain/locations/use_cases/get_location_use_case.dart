import 'package:traction_selection_proccess/app/core/utils/result.dart';
import 'package:traction_selection_proccess/app/core/use_cases/use_cases.dart';
import 'package:traction_selection_proccess/app/domain/locations/entities/location.dart';
import 'package:traction_selection_proccess/app/domain/locations/repository/location_repository.dart';

typedef LocationResult = Result<List<Location>, Exception>;

class GetLocationUseCase extends UseCases<LocationResult, String> {

  final LocationRepository _locationRepository;

  GetLocationUseCase(this._locationRepository);

  @override
  Future<LocationResult> call(String params) async{
    return await _locationRepository.getLocations(params);
  }
}

