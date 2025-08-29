import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

// A simple class to represent a task
class Task {
  String name;
  bool isCompleted;
  DateTime creationTime;
  DateTime? completionTime;
  String priority;

  Task(this.name, this.isCompleted, this.creationTime, {this.completionTime, this.priority = 'Low'});

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      json['name'] as String,
      json['isCompleted'] as bool,
      DateTime.parse(json['creationTime'] as String),
      completionTime: json['completionTime'] != null
          ? DateTime.parse(json['completionTime'] as String)
          : null,
      priority: json['priority'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isCompleted': isCompleted,
      'creationTime': creationTime.toIso8601String(),
      'completionTime': completionTime?.toIso8601String(),
      'priority': priority,
    };
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yuvej\'s To-Do List',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ToDoListScreen(),
    );
  }
}

class ToDoListScreen extends StatefulWidget {
  const ToDoListScreen({Key? key}) : super(key: key);

  @override
  _ToDoListScreenState createState() => _ToDoListScreenState();
}

class _ToDoListScreenState extends State<ToDoListScreen> {
  List<Task> _tasks = [];
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  late SharedPreferences _prefs;
  String _filter = 'All Tasks';
  String _searchQuery = '';

  String _userName = 'Yuvej';
  Color _primaryColor = const Color(0xFFE91E63);
  Color _secondaryColor = const Color(0xFF9C27B0);
  String _selectedPriority = 'Low';
  final List<String> _priorities = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  void _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadTasks();
  }

  void _loadTasks() {
    final String? tasksJson = _prefs.getString('tasks');
    if (tasksJson != null) {
      final List<dynamic> decodedList = jsonDecode(tasksJson);
      setState(() {
        _tasks.clear();
        _tasks.addAll(decodedList.map((item) => Task.fromJson(item as Map<String, dynamic>)));
      });
    }

    final String? userName = _prefs.getString('userName');
    if (userName != null) {
      setState(() {
        _userName = userName;
      });
    }
    final int? primaryColorValue = _prefs.getInt('primaryColor');
    final int? secondaryColorValue = _prefs.getInt('secondaryColor');
    if (primaryColorValue != null && secondaryColorValue != null) {
      setState(() {
        _primaryColor = Color(primaryColorValue);
        _secondaryColor = Color(secondaryColorValue);
      });
    }
  }

  void _saveTasks() {
    final List<Map<String, dynamic>> tasksToSave = _tasks.map((task) => task.toJson()).toList();
    _prefs.setString('tasks', jsonEncode(tasksToSave));
  }

  void _saveUserData() {
    _prefs.setString('userName', _userName);
    _prefs.setInt('primaryColor', _primaryColor.value);
    _prefs.setInt('secondaryColor', _secondaryColor.value);
  }

  void _addTask() {
    if (_taskController.text.isNotEmpty) {
      final newTask = Task(_taskController.text, false, DateTime.now(), priority: _selectedPriority);
      setState(() {
        _tasks.add(newTask);
        _taskController.clear();
        _selectedPriority = 'Low';
      });
      _saveTasks();
    }
  }

  void _toggleTaskCompletion(Task taskToToggle) {
    final int index = _tasks.indexOf(taskToToggle);
    if (index != -1) {
      setState(() {
        final task = _tasks[index];
        task.isCompleted = !task.isCompleted;
        if (task.isCompleted) {
          task.completionTime = DateTime.now();
        } else {
          task.completionTime = null;
        }
      });
      _saveTasks();
    }
  }

  void _deleteTask(Task taskToDelete) {
    final int index = _tasks.indexOf(taskToDelete);
    if (index != -1) {
      setState(() {
        _tasks.removeAt(index);
      });
      _saveTasks();
    }
  }

  void _clearAllTasks() {
    setState(() {
      _tasks.clear();
    });
    _saveTasks();
  }

  void _editTask(Task taskToEdit) {
    final TextEditingController editController = TextEditingController(text: taskToEdit.name);
    String selectedPriority = taskToEdit.priority;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editController,
                decoration: const InputDecoration(labelText: 'Task Name'),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: _priorities.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    selectedPriority = newValue;
                  }
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                if (editController.text.isNotEmpty) {
                  setState(() {
                    taskToEdit.name = editController.text;
                    taskToEdit.priority = selectedPriority;
                  });
                  _saveTasks();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  List<Task> get _filteredTasks {
    List<Task> filteredByStatus;
    if (_filter == 'Pending') {
      filteredByStatus = _tasks.where((task) => !task.isCompleted).toList();
    } else if (_filter == 'Completed') {
      filteredByStatus = _tasks.where((task) => task.isCompleted).toList();
    } else {
      filteredByStatus = _tasks;
    }

    if (_searchQuery.isNotEmpty) {
      return filteredByStatus.where((task) =>
          task.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    return filteredByStatus;
  }

  void _navigateToProfile() async {
    final newUserData = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          initialName: _userName,
          initialPrimaryColor: _primaryColor,
          initialSecondaryColor: _secondaryColor,
        ),
      ),
    );

    if (newUserData != null) {
      setState(() {
        _userName = newUserData['name'];
        _primaryColor = newUserData['primaryColor'];
        _secondaryColor = newUserData['secondaryColor'];
        _saveUserData();
      });
    }
  }

  Widget _buildPrioritySelector() {
    return PopupMenuButton<String>(
      onSelected: (String newValue) {
        setState(() {
          _selectedPriority = newValue;
        });
      },
      itemBuilder: (BuildContext context) {
        return _priorities.map((String choice) {
          return PopupMenuItem<String>(
            value: choice,
            child: Text(choice),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Text(
              _selectedPriority,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.black87),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int completedCount = _tasks.where((task) => task.isCompleted).length;
    int totalTasks = _tasks.length;
    final List<Task> displayedTasks = _filteredTasks;

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_primaryColor, _secondaryColor],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 50),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(25.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: _secondaryColor),
                            const SizedBox(width: 10),
                            Text(
                              "$_userName's To-Do List",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _secondaryColor,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: _navigateToProfile,
                          child: Icon(Icons.account_circle, color: _secondaryColor, size: 30),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "A colorful task manager by Yuvej Kumar",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(255, 33, 59, 222),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFilterButton('All Tasks', _primaryColor),
                        _buildFilterButton('Pending', const Color(0xFF4DB6AC)),
                        _buildFilterButton('Completed', _secondaryColor),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search tasks...',
                          prefixIcon: Icon(Icons.search, color: _secondaryColor),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: TextField(
                              controller: _taskController,
                              decoration: const InputDecoration(
                                hintText: 'Add a new task...',
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _addTask(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _buildPrioritySelector(),
                        const SizedBox(width: 10),
                        FloatingActionButton(
                          onPressed: _addTask,
                          backgroundColor: _secondaryColor,
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: displayedTasks.length,
                        itemBuilder: (context, index) {
                          final task = displayedTasks[index];
                          return _buildTaskItem(task);
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${completedCount}/${totalTasks} tasks',
                          style: const TextStyle(
                            color: Color(0xFF757575),
                            fontSize: 16,
                          ),
                        ),
                        TextButton(
                          onPressed: _clearAllTasks,
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFF44336),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Clear All',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String title, Color color) {
    bool isSelected = _filter == title;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _filter = title;
        });
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : Colors.black,
        backgroundColor: isSelected ? color : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Text(title),
    );
  }

  Widget _buildTaskItem(Task task) {
    String _formatDateTime(DateTime dateTime) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final taskDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
      final String time = DateFormat('hh:mm a').format(dateTime);

      if (taskDate.isAtSameMomentAs(today)) {
        return 'Today at $time';
      } else if (taskDate.isAtSameMomentAs(yesterday)) {
        return 'Yesterday at $time';
      } else {
        return DateFormat('MMM d, yyyy').format(dateTime);
      }
    }

    final String creationDate = _formatDateTime(task.creationTime);
    final String? completionDate = task.isCompleted && task.completionTime != null
        ? 'Completed: ${_formatDateTime(task.completionTime!)}'
        : null;

    Color _getPriorityColor(String priority) {
      switch (priority) {
        case 'High':
          return Colors.red;
        case 'Medium':
          return Colors.orange;
        case 'Low':
          return const Color.fromARGB(255, 13, 210, 26);
        default:
          return Colors.blueGrey;
      }
    }

    return GestureDetector(
      onTap: () => _editTask(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _toggleTaskCompletion(task),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: task.isCompleted ? const Color(0xFF4DB6AC) : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xFF4DB6AC), width: 2),
                ),
                child: task.isCompleted
                    ? const Icon(Icons.check, size: 20, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.name,
                    style: TextStyle(
                      fontSize: 16,
                      color: task.isCompleted ? const Color(0xFF757575) : Colors.black87,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Created: $creationDate',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  if (completionDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.check, size: 12, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            completionDate,
                            style: const TextStyle(fontSize: 12, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(task.priority).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        task.priority,
                        style: TextStyle(
                          fontSize: 10,
                          color: _getPriorityColor(task.priority),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Color(0xFFF44336)),
              onPressed: () => _deleteTask(task),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  final String initialName;
  final Color initialPrimaryColor;
  final Color initialSecondaryColor;

  const ProfileScreen({
    Key? key,
    required this.initialName,
    required this.initialPrimaryColor,
    required this.initialSecondaryColor,
  }) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late Color _selectedPrimaryColor;
  late Color _selectedSecondaryColor;

  final List<Map<String, Color>> _colorThemes = [
    {'primary': const Color(0xFFE91E63), 'secondary': const Color(0xFF9C27B0)},
    {'primary': Colors.blue, 'secondary': Colors.cyan},
    {'primary': Colors.green, 'secondary': Colors.lightGreen},
    {'primary': Colors.orange, 'secondary': Colors.deepOrange},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _selectedPrimaryColor = widget.initialPrimaryColor;
    _selectedSecondaryColor = widget.initialSecondaryColor;
  }

  void _saveProfile() {
    Navigator.of(context).pop({
      'name': _nameController.text.isEmpty ? 'Yuvej' : _nameController.text,
      'primaryColor': _selectedPrimaryColor,
      'secondaryColor': _selectedSecondaryColor,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
        backgroundColor: _selectedPrimaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Name',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter your name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Select a Color Theme',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colorThemes.map((theme) {
                final primary = theme['primary']!;
                final secondary = theme['secondary']!;
                final isSelected = _selectedPrimaryColor == primary;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPrimaryColor = primary;
                      _selectedSecondaryColor = secondary;
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary, secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: isSelected
                          ? Border.all(color: Colors.black, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedSecondaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text('Save', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}