import 'package:traction_selection_process/app/domain/api/api_handler.dart';
import 'package:traction_selection_process/app/core/constants/endpoints.dart';

class CompanyDatasource {
  final ApiHandler _apiHandler;

  CompanyDatasource(this._apiHandler);

  Future<dynamic> getCompanies() async {
    return await _apiHandler.get(path: Endpoints.getCompanies);
  }
}
