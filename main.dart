import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MahamiProApp());
}

class MahamiProApp extends StatefulWidget {
  const MahamiProApp({super.key});

  @override
  State<MahamiProApp> createState() => _MahamiProAppState();
}

class _MahamiProAppState extends State<MahamiProApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مهامي Pro',
      theme: _isDarkMode
          ? ThemeData.dark(useMaterial3: true)
          : ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
      home: HomeScreen(isDarkMode: _isDarkMode, onToggleTheme: _toggleTheme),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // ----------------- المهام -----------------
  List<Map<String, dynamic>> _tasks = [];
  final TextEditingController _taskController = TextEditingController();

  // ----------------- المصاريف -----------------
  List<Map<String, dynamic>> _transactions = [];
  final TextEditingController _expenseTitleController = TextEditingController();
  final TextEditingController _expenseAmountController = TextEditingController();
  bool _isIncome = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();

    final String? tasksString = prefs.getString('saved_tasks');
    if (tasksString != null) {
      _tasks = List<Map<String, dynamic>>.from(json.decode(tasksString));
    } else {
      _tasks = [
        {'title': 'مراجعة محاضرات اليوم', 'done': false},
        {'title': 'تسجيل مصاريف المواصلات', 'done': true},
        {'title': 'تطوير تطبيق مهامي Pro', 'done': true},
      ];
    }

    final String? expensesString = prefs.getString('saved_expenses');
    if (expensesString != null) {
      _transactions = List<Map<String, dynamic>>.from(json.decode(expensesString));
    }

    setState(() {});
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_tasks', json.encode(_tasks));
  }

  Future<void> _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_expenses', json.encode(_transactions));
  }

  void _addTask() {
    if (_taskController.text.trim().isEmpty) return;
    setState(() {
      _tasks.add({'title': _taskController.text.trim(), 'done': false});
      _taskController.clear();
    });
    _saveTasks();
  }

  void _toggleTask(int index) {
    setState(() {
      _tasks[index]['done'] = !_tasks[index]['done'];
    });
    _saveTasks();
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
    _saveTasks();
  }

  void _addTransaction() {
    final title = _expenseTitleController.text.trim();
    final amount = double.tryParse(_expenseAmountController.text.trim()) ?? 0.0;

    if (title.isEmpty || amount <= 0) return;

    setState(() {
      _transactions.insert(0, {
        'title': title,
        'amount': amount,
        'isIncome': _isIncome,
        'date': DateTime.now().toString().substring(0, 10),
      });
      _expenseTitleController.clear();
      _expenseAmountController.clear();
    });
    _saveExpenses();
    Navigator.pop(context);
  }

  void _deleteTransaction(int index) {
    setState(() {
      _transactions.removeAt(index);
    });
    _saveExpenses();
  }

  double get _totalIncome => _transactions
      .where((t) => t['isIncome'] == true)
      .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());

  double get _totalExpenses => _transactions
      .where((t) => t['isIncome'] == false)
      .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());

  double get _balance => _totalIncome - _totalExpenses;

  void _showAddExpenseDialog() {
    _isIncome = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'إضافة معاملة مالية جديدة',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text('مصروف 🔴'),
                          selected: !_isIncome,
                          selectedColor: Colors.red.shade100,
                          onSelected: (selected) {
                            setModalState(() => _isIncome = false);
                          },
                        ),
                        const SizedBox(width: 15),
                        ChoiceChip(
                          label: const Text('دخل / إيداع 🟢'),
                          selected: _isIncome,
                          selectedColor: Colors.green.shade100,
                          onSelected: (selected) {
                            setModalState(() => _isIncome = true);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _expenseTitleController,
                      decoration: const InputDecoration(
                        labelText: 'الوصف (مثال: أكل، مواصلات، مكافأة)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _expenseAmountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'المبلغ بالجنية',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('حفظ المعاملة', style: TextStyle(fontSize: 16)),
                      onPressed: _addTransaction,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentIndex == 0 ? 'مهامي اليومية 📝' : 'المصاريف والميزانية 💰'),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
              onPressed: widget.onToggleTheme,
              tooltip: 'الوضع الليلي',
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: _currentIndex == 0 ? _buildTasksTab() : _buildExpensesTab(),
            ),
            Container(
              width: double.infinity,
              color: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: const Text(
                'Developed by Gemini (Google)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.checklist_rtl), label: 'المهام'),
            NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'المصاريف'),
          ],
        ),
        floatingActionButton: _currentIndex == 1
            ? FloatingActionButton.extended(
                onPressed: _showAddExpenseDialog,
                icon: const Icon(Icons.add),
                label: const Text('إضافة مصروف / دخل'),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              )
            : null,
      ),
    );
  }

  Widget _buildTasksTab() {
    return Column(
      children: [
        Expanded(
          child: _tasks.isEmpty
              ? const Center(child: Text('لا توجد مهام حالياً! أضف مهمة جديدة 🚀'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: Checkbox(
                          value: task['done'],
                          onChanged: (_) => _toggleTask(index),
                        ),
                        title: Text(
                          task['title'],
                          style: TextStyle(
                            decoration: task['done'] ? TextDecoration.lineThrough : null,
                            color: task['done'] ? Colors.grey : null,
                            fontSize: 16,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deleteTask(index),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _taskController,
                  decoration: const InputDecoration(
                    hintText: 'اكتب مهمة جديدة...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                onPressed: _addTask,
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpensesTab() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade400],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: Column(
            children: [
              const Text('المتبقي في الميزانية', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 6),
              Text(
                '${_balance.toStringAsFixed(1)} ج.م',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Divider(color: Colors.white30, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('إجمالي الدخل 🟢', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('+${_totalIncome.toStringAsFixed(1)} ج.م',
                          style: const TextStyle(color: Colors.lightGreenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  Container(height: 30, width: 1, color: Colors.white30),
                  Column(
                    children: [
                      const Text('إجمالي المصاريف 🔴', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('-${_totalExpenses.toStringAsFixed(1)} ج.م',
                          style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _transactions.isEmpty
              ? const Center(child: Text('لم تسجل أي مصاريف بعد. ابدأ بالتسجيل الآن! 💵'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final item = _transactions[index];
                    final bool isInc = item['isIncome'] ?? false;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isInc ? Colors.green.shade100 : Colors.red.shade100,
                          child: Icon(
                            isInc ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isInc ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(item['date'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${isInc ? '+' : '-'}${item['amount']} ج.م',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isInc ? Colors.green : Colors.red,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                              onPressed: () => _deleteTransaction(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
