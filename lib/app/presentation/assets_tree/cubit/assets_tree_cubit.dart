import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:traction_selection_proccess/app/core/utils/base_cubit.dart';
import 'package:traction_selection_proccess/app/domain/locations/entities/location.dart';
import 'package:traction_selection_proccess/app/domain/assets_tree/entities/tree_assets.dart';
import 'package:traction_selection_proccess/app/core/extensions/tree_branches_extension.dart';
import 'package:traction_selection_proccess/app/domain/assets_tree/entities/assets_component.dart';
import 'package:traction_selection_proccess/app/domain/locations/use_cases/get_location_use_case.dart';
import 'package:traction_selection_proccess/app/presentation/assets_tree/cubit/assets_tree_states.dart';
import 'package:traction_selection_proccess/app/domain/assets_tree/use_case/get_tree_asset_use_case.dart';
import 'package:traction_selection_proccess/app/domain/assets_tree/use_case/build_assets_tree_use_case.dart';

class AssetsTreeCubit extends BaseCubit<AssetsTreeState> {
  final GetLocationUseCase _getLocationUseCase;
  final GetAssetsTreeUseCase _getAssetsTreeUseCase;
  final BuildAssetsTreeUseCase _buildAssetsTreeUseCase;

  AssetsTreeCubit({
    required GetLocationUseCase getLocationUseCase,
    required GetAssetsTreeUseCase getAssetsTreeUseCase,
    required BuildAssetsTreeUseCase buildAssetsTreeUseCase,
  })  : _getLocationUseCase = getLocationUseCase,
        _getAssetsTreeUseCase = getAssetsTreeUseCase,
        _buildAssetsTreeUseCase = buildAssetsTreeUseCase,
        super(AssetsTreeInitial());

  late final AssetsTreeArgs _args;

  Completer<List<Location>> completer = Completer();

  AssetsTree _assetsTreeCache = const AssetsTree(branches: []);

  @override
  void onInit() {
    _args = Get.arguments as AssetsTreeArgs;
    _getData();
  }

  Future<void> _getData() async {
    await Future.wait([
      _getLocations(),
      _getAssetsTree(),
    ]);
  }

  Future<void> onRefresh() async => await _getData();

  Future<void> _getLocations() async {
    emit(AssetsTreeLoading());
    completer = Completer();

    final result = await _getLocationUseCase(_args.companyId);

    result.proccessResult(
      onFailure: (error) => emit(AssetsTreeError()),
      onSuccess: (data) => completer.complete(data),
    );
  }

  Future<void> _getAssetsTree() async {
    emit(AssetsTreeLoading());
    final result = await _getAssetsTreeUseCase(_args.companyId);

    result.proccessResult(
      onSuccess: _buildAssetsTree,
      onFailure: (error) => emit(AssetsTreeError()),
    );
  }

  Future<void> _buildAssetsTree(AssetsTree inputData) async {
    final locations = await completer.future;
    final assetsTreeData = _combineBranches(inputData, locations);

    _emitInitialAssetsTree(assetsTreeData);
    _listenForUpdatedAssetsTree(assetsTreeData);
  }

  AssetsTree _combineBranches(
    AssetsTree inputData,
    List<TreeBranches> locations,
  ) {
    return AssetsTree(
      branches: [...inputData.branches, ...locations],
    );
  }

  void _emitInitialAssetsTree(AssetsTree assetsTreeData) {
    emit(
      AssetsTreeLoaded(
        assetsTree: state.assetsTree.copyWith(
          branches: assetsTreeData.branches.componentsUnliked,
        ),
      ),
    );
  }

  void _listenForUpdatedAssetsTree(AssetsTree assetsTreeData) {
    _buildAssetsTreeUseCase(assetsTreeData).listen((resultData) {
      _updateAssetsTree(resultData);
    });
  }

  void _updateAssetsTree(AssetsTree resultData) {
    final currentAssetsTree = state.assetsTree;

    final updatedBranches = List<TreeBranches>.from(resultData.branches)
      ..addAll(currentAssetsTree.branches);

    emit(
      AssetsTreeLoaded(
        assetsTree: currentAssetsTree.copyWith(branches: updatedBranches),
      ),
    );

    _assetsTreeCache = currentAssetsTree.copyWith(branches: updatedBranches);
  }

  void toggleTree(String id) {
    _assetsTreeCache = AssetsTree(
      branches: _deepSearchToExpandes(id, _assetsTreeCache.branches),
    );

    emit(AssetsTreeLoaded(assetsTree: _assetsTreeCache));
  }

  List<TreeBranches> _deepSearchToExpandes(
    String id,
    List<TreeBranches> branches,
  ) {
    final List<TreeBranches> assetsTree = [];

    for (var element in branches) {
      if (element.children.isNotEmpty) {
        element = element.copyWith(
          children: _deepSearchToExpandes(id, element.children),
        );
      }

      if (element.id == id) {
        element = element.copyWith(isOpen: !element.isOpen);
      }

      assetsTree.add(element);
    }

    return assetsTree;
  }

  Future<void> toggleAlertCritical() async {
    final newCriticalState = !state.critical;
    final assetsTreeFiltered = newCriticalState
        ? await compute(_deepCriticalFilter, _assetsTreeCache.branches)
        : _assetsTreeCache.branches;

    emit(
      state.copyWith(
        energy: false,
        critical: newCriticalState,
        assetsTree: AssetsTree(branches: assetsTreeFiltered),
      ),
    );
  }

  static List<TreeBranches> _deepCriticalFilter(
    List<TreeBranches> branches,
  ) {
    final List<TreeBranches> assetsTree = [];

    for (var element in branches) {
      if (element.children.isNotEmpty) {
        element = element.copyWith(
          isOpen: true,
          children: _deepCriticalFilter(element.children),
        );
      }

      if (element is AssetsComponent) {
        if (element.isCritical) {
          assetsTree.add(element);
        }
      }

      if (element.children.isNotEmpty) {
        assetsTree.add(element);
      }
    }

    return assetsTree;
  }

  Future<void> toggleEnergySensor() async {
    final newEnergySytate = !state.energy;
    final assetsTreeFiltered = newEnergySytate
        ? await compute(_deepEnergySensorFilter, _assetsTreeCache.branches)
        : _assetsTreeCache.branches;

    emit(
      state.copyWith(
        critical: false,
        energy: newEnergySytate,
        assetsTree: AssetsTree(branches: assetsTreeFiltered),
      ),
    );
  }

  static List<TreeBranches> _deepEnergySensorFilter(
    List<TreeBranches> branches,
  ) {
    final List<TreeBranches> assetsTree = [];

    for (var element in branches) {
      if (element.children.isNotEmpty) {
        element = element.copyWith(
          isOpen: true,
          children: _deepEnergySensorFilter(element.children),
        );
      }

      if (element is AssetsComponent) {
        if (element.isEnergySensor) {
          assetsTree.add(element);
        }
      }

      if (element.children.isNotEmpty) {
        assetsTree.add(element);
      }
    }

    return assetsTree;
  }

  Future<void> onFiltering(String query) async {
    if (query.length >= 3) {
      final filterByTyping = await compute(
        _deepTypingFilter,
        _assetsTreeCache.branches,
      );

      emit(
        state.copyWith(
          energy: false,
          critical: false,
          assetsTree: AssetsTree(branches: filterByTyping),
        ),
      );
    }
  }

  static List<TreeBranches> _deepTypingFilter(
    List<TreeBranches> branches,
  ) {
    final List<TreeBranches> assetsTree = [];

    for (var element in branches) {
      if (element.children.isNotEmpty) {
        element = element.copyWith(
          isOpen: true,
          children: _deepTypingFilter(element.children),
        );
      }

      if (element.name == "Location 410") {
        assetsTree.add(element);
      } else if (element.children.isNotEmpty) {
        assetsTree.add(element);
      }
    }

    return assetsTree;
  }
}

class AssetsTreeArgs {
  final String companyId;

  AssetsTreeArgs({required this.companyId});
}
