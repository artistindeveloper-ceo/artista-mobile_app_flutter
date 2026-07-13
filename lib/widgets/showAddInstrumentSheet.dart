import 'package:flutter/material.dart';

import '../model/CategoryModel.dart';
import '../model/InstrumentTypeModel.dart';
import '../model/InstrumentModel.dart';
import '../service/InstrumentService.dart';
import '../theme/app_theme.dart';

/// Shows the Add Instrument bottom sheet. Calls [onAdded] after a
/// successful save so the caller can refresh the instrument list.
Future<void> showAddInstrumentSheet(
    BuildContext context, {
      required VoidCallback onAdded,
    }) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _AddInstrumentSheet(onAdded: onAdded),
  );
}

const _proficiencyLevels = ['BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'PROFESSIONAL'];

enum _Step { category, type, model, details }

class _AddInstrumentSheet extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddInstrumentSheet({required this.onAdded});

  @override
  State<_AddInstrumentSheet> createState() => _AddInstrumentSheetState();
}

class _AddInstrumentSheetState extends State<_AddInstrumentSheet> {
  _Step _step = _Step.category;

  List<CategoryModel> _categories = [];
  List<InstrumentTypeModel> _types = [];
  List<InstrumentModel> _models = [];

  CategoryModel? _selectedCategory;
  InstrumentTypeModel? _selectedType;
  InstrumentModel? _selectedModel;

  bool _isPrimary = true;
  String? _proficiency;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final categories = await InstrumentService.getAllCategories();
      if (mounted) setState(() => _categories = categories);
    } catch (e) {
      if (mounted) setState(() => _error = 'Categories load nahi ho payi');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTypes(CategoryModel category) async {
    setState(() {
      _selectedCategory = category;
      _isLoading = true;
      _error = null;
      _step = _Step.type;
    });
    try {
      final types = await InstrumentService.getTypesByCategory(category.id);
      if (mounted) setState(() => _types = types);
    } catch (e) {
      if (mounted) setState(() => _error = 'Types load nahi ho paye');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadModels(InstrumentTypeModel type) async {
    setState(() {
      _selectedType = type;
      _isLoading = true;
      _error = null;
      _step = _Step.model;
    });
    try {
      final models = await InstrumentService.getInstrumentsByType(type.id);
      if (mounted) setState(() => _models = models);
    } catch (e) {
      if (mounted) setState(() => _error = 'Models load nahi ho paye');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectModel(InstrumentModel model) {
    setState(() {
      _selectedModel = model;
      _step = _Step.details;
    });
  }

  void _goBack() {
    setState(() {
      switch (_step) {
        case _Step.type:
          _step = _Step.category;
          _selectedCategory = null;
          _types = [];
          break;
        case _Step.model:
          _step = _Step.type;
          _selectedType = null;
          _models = [];
          break;
        case _Step.details:
          _step = _Step.model;
          _selectedModel = null;
          break;
        case _Step.category:
          break;
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedModel == null) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await InstrumentService.addUserInstrument(
        instrumentId: _selectedModel!.id,
        isPrimary: _isPrimary,
        proficiencyLevel: _proficiency,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onAdded();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 6),
            _buildBreadcrumb(),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Flexible(child: _buildStepContent()),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        if (_step != _Step.category)
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: _goBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        if (_step != _Step.category) const SizedBox(width: 8),
        const Text('Add Instrument',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBreadcrumb() {
    final parts = <String>[];
    if (_selectedCategory != null) parts.add(_selectedCategory!.name);
    if (_selectedType != null) parts.add(_selectedType!.name);
    if (_selectedModel != null) parts.add(_selectedModel!.displayName);
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' → '),
      style: TextStyle(color: AppColors.textGrey, fontSize: 12),
    );
  }

  Widget _buildStepContent() {
    if (_isLoading) {
      return const SizedBox(
          height: 200, child: Center(child: CircularProgressIndicator()));
    }

    switch (_step) {
      case _Step.category:
        return _buildCategoryList();
      case _Step.type:
        return _buildTypeList();
      case _Step.model:
        return _buildModelList();
      case _Step.details:
        return _buildDetailsForm();
    }
  }

  Widget _buildCategoryList() {
    if (_categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text('Koi category nahi mili')),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _categories.length,
      itemBuilder: (ctx, i) {
        final cat = _categories[i];
        return ListTile(
          leading: const Icon(Icons.category_outlined),
          title: Text(cat.name),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => _loadTypes(cat),
        );
      },
    );
  }

  Widget _buildTypeList() {
    if (_types.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text('Is category me koi type nahi mila')),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _types.length,
      itemBuilder: (ctx, i) {
        final type = _types[i];
        return ListTile(
          leading: const Icon(Icons.piano_outlined),
          title: Text(type.name),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => _loadModels(type),
        );
      },
    );
  }

  Widget _buildModelList() {
    if (_models.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text('Is type me koi model nahi mila')),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _models.length,
      itemBuilder: (ctx, i) {
        final model = _models[i];
        return ListTile(
          leading: model.displayImageUrl != null
              ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(model.displayImageUrl!,
                  width: 36, height: 36, fit: BoxFit.cover))
              : const Icon(Icons.music_note),
          title: Text(model.displayName),
          onTap: () => _selectModel(model),
        );
      },
    );
  }

  Widget _buildDetailsForm() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Type', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TypeChip(
                  label: 'Primary',
                  selected: _isPrimary,
                  onTap: () => setState(() => _isPrimary = true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TypeChip(
                  label: 'Secondary',
                  selected: !_isPrimary,
                  onTap: () => setState(() => _isPrimary = false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Proficiency (optional)',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _proficiencyLevels.map((level) {
              final selected = _proficiency == level;
              return ChoiceChip(
                label: Text(level[0] + level.substring(1).toLowerCase()),
                selected: selected,
                onSelected: (_) =>
                    setState(() => _proficiency = selected ? null : level),
                selectedColor: AppColors.primaryDark,
                labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.black87),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isSaving
                  ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : const Text('Save Instrument'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? AppColors.primaryDark : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}