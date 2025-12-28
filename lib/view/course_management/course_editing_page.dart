import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schedu/model/course.dart';
import 'package:schedu/repository/app_settings_store.dart';
import 'package:schedu/repository/course_repository.dart';
import 'package:schedu/style/colors.dart';
import 'package:schedu/view/course_management/section_picker_bottom_sheet.dart';

/// Course Editing Page - Allows editing or adding a course
class CourseEditingPage extends StatefulWidget {
  final Course? course; // null means adding new course

  const CourseEditingPage({super.key, this.course});

  @override
  State<CourseEditingPage> createState() => _CourseEditingPageState();
}

class _CourseEditingPageState extends State<CourseEditingPage> {
  final _formKey = GlobalKey<FormState>();
  late int _maxSections;
  late int _maxWeeks;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _positionController;
  late TextEditingController _teacherController;

  // Form data
  int _day = 1;
  List<int> _selectedWeeks = [];
  int _sectionStart = 1;
  int _sectionEnd = 1;
  int? _colorId;

  // Track changes for unsaved changes detection
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();

    final course = widget.course;
    if (course != null) {
      // Editing existing course
      _nameController = TextEditingController(text: course.name);
      _positionController = TextEditingController(text: course.position);
      _teacherController = TextEditingController(text: course.teacher);
      _selectedWeeks = List<int>.from(course.weeks);
      _day = course.day;
      if (course.sections.isNotEmpty) {
        _sectionStart = course.sections.first;
        _sectionEnd = course.sections.last;
      }
      _colorId = course.colorId;
    } else {
      // Adding new course
      _nameController = TextEditingController();
      _positionController = TextEditingController();
      _teacherController = TextEditingController();
    }

    // Add listeners to track changes
    _nameController.addListener(_onFormChanged);
    _positionController.addListener(_onFormChanged);
    _teacherController.addListener(_onFormChanged);

    // Initialize max sections and weeks
    final appSettings = AppSettingsStore.instance.data;
    _maxSections = appSettings.totalDailySections;
    _maxWeeks = appSettings.totalWeeks;
  }

  void _onFormChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _teacherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 未保存更改时阻止返回
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: _handlePopWithResult,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.course == null ? '添加课程' : '编辑课程'),
          actions: [
            TextButton(
              onPressed: _hasUnsavedChanges ? _saveCourse : null,
              child: Builder(
                builder: (context) {
                  final colorScheme = Theme.of(context).colorScheme;
                  return Text(
                    '保存',
                    style: TextStyle(
                      color: _hasUnsavedChanges ? colorScheme.onPrimary : colorScheme.onSurface.withOpacity(0.3),
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: '课程名称',
                  icon: Icons.book,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _positionController,
                  label: '上课地点',
                  icon: Icons.location_on,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _teacherController,
                  label: '教师姓名',
                  icon: Icons.person,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildDaySelector(),
                const SizedBox(height: 16),
                _buildWeekSelector(),
                const SizedBox(height: 16),
                _buildSectionSelector(),
                const SizedBox(height: 24),
                _buildColorSelector(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      keyboardType: keyboardType,
      validator: validator ?? (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return '请输入$label';
        }
        return null;
      },
    );
  }

  Widget _buildDaySelector() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                '星期',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (index) {
              final day = index + 1;
              final isSelected = _day == day;
              return ChoiceChip(
                label: Text('周${['一', '二', '三', '四', '五', '六', '日'][index]}'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _day = day;
                      _onFormChanged();
                    });
                  }
                },
                selectedColor: Theme.of(context).colorScheme.primary,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.view_week, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                '周数',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(_maxWeeks, (index) {
              final week = index + 1;
              final isSelected = _selectedWeeks.contains(week);
              return ChoiceChip(
                label: Text('$week'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedWeeks.add(week);
                    } else {
                      _selectedWeeks.remove(week);
                    }
                    _onFormChanged();
                  });
                },
                selectedColor: Theme.of(context).colorScheme.primary,
              );
            }),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedWeeks = List.generate(20, (i) => i + 1);
                    _onFormChanged();
                  });
                },
                child: const Text('全选'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedWeeks.clear();
                    _onFormChanged();
                  });
                },
                child: const Text('清空'),
              ),
              const Spacer(),
              if (_selectedWeeks.isNotEmpty)
                Text(
                  '已选 ${_selectedWeeks.length} 周',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                '节次',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _showSectionPickerBottomSheet,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '第$_sectionStart节 - 第$_sectionEnd节',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Icon(Icons.arrow_drop_down, color: colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.color_lens, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                '课程颜色 (可选)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(AppColors.lessonTilePalette.length, (index) {
              final isSelected = _colorId == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _colorId = isSelected ? null : index;
                    _onFormChanged();
                  });
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.lessonTilePalette[index],
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(
                      color: colorScheme.primary,
                      width: 3,
                    ) : null,
                    boxShadow: isSelected
                        ? [BoxShadow(color: colorScheme.shadow.withOpacity(0.3), blurRadius: 4)]
                        : null,
                  ),
                ),
              );
            }),
          ),
          if (_colorId == null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '未选择颜色，将自动分配',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
              ),
            ),
        ],
      ),
    );
  }

  void _showSectionPickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SectionPickerBottomSheet(
          initialStart: _sectionStart,
          initialEnd: _sectionEnd,
          maxSections: _maxSections,
          onConfirm: (start, end) {
            setState(() {
              _sectionStart = start;
              _sectionEnd = end;
              _onFormChanged();
            });
          },
        );
      },
    );
  }

  String? _validateWeeks() {
    if (_selectedWeeks.isEmpty) {
      return '请至少选择一周';
    }
    return null;
  }

  String? _validateSections() {
    if (_sectionStart > _sectionEnd) {
      return '开始节次不能大于结束节次';
    }
    return null;
  }

  void _handlePopWithResult(bool didPop, dynamic result) async {
    if (didPop || !_hasUnsavedChanges) {
      return;
    }

    final shouldPop = await _showUnsavedChangesDialog();
    if (shouldPop == true) {
      Navigator.pop(context);
    }
  }

  Future<bool?> _showUnsavedChangesDialog() async {
    final colorScheme = Theme.of(context).colorScheme;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('未保存的更改'),
        content: const Text('您有未保存的更改，确定要离开吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('继续编辑'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: const Text('离开'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCourse() async {
    // Validate basic form fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Custom validation for weeks and sections
    final weeksError = _validateWeeks();
    if (weeksError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(weeksError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final sectionsError = _validateSections();
    if (sectionsError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sectionsError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Generate sections list from start and end
    final sections = List.generate(
      _sectionEnd - _sectionStart + 1,
      (index) => _sectionStart + index,
    );

    final course = Course(
      name: _nameController.text.trim(),
      position: _positionController.text.trim(),
      teacher: _teacherController.text.trim(),
      weeks: _selectedWeeks,
      day: _day,
      sections: sections,
      colorId: _colorId,
    );

    try {
      final repository = context.read<CourseRepository>();

      if (widget.course == null) {
        // Add new course
        await repository.insertCourse(course);
      } else {
        // Update existing course
        await repository.updateCourse(course);
      }

      setState(() {
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.course == null ? '课程添加成功' : '课程更新成功'),
            backgroundColor: colorScheme.primary,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: ${e.toString()}'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }
}