import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
      ),
      home: const MyHomePage(title: 'Lista de Tarefas'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({
    super.key,
    required this.title,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<(String,Key)> taskList = [];
  final List<(String,Key)> taskListChecked = [];
  final textController = TextEditingController();
  final Set<Key> deleting = <Key>{};
  final Set<Key> checked = <Key>{};

  void _addTask(String st) {
    setState(() {
      if (st.trim() != '' && !taskList.contains((st,Key(st)))) {
        taskList.add((st.trim(),Key(st)));
      }
      else if(taskList.contains((st,Key(st)))){
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta tarefa já foi adicionada!'),
          duration: Duration(seconds: 2),
          ),
        );
      }
      textController.clear();
    });
  }

  void _deleteTask(Key key) async {
    
    setState((){
      deleting.add(key);
    });
    
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted || !deleting.contains(key)) return;
    
    setState(() {
      final index = taskList.indexWhere((item) => item.$2 == key);
      final indexchecked = taskListChecked.indexWhere((item) => item.$2 == key);
      if (index != -1) {
        taskList.removeAt(index);
      }
      else if (indexchecked != -1) {
        taskListChecked.removeAt(indexchecked);
      }
      deleting.remove(key);
    });
  }
  
  void _undoTask(Key key){
    setState((){
      deleting.remove(key);
    });
  }
  
  void _checkTask(Key key){
    setState((){
      final index = taskList.indexWhere((item) => item.$2 == key);
      if (index != -1) {
        taskListChecked.insert(0,taskList[index]);
        taskList.removeAt(index);
        checked.add(key);
      }
    });
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.purpleAccent,
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          TextField(
            controller: textController,
            decoration: const InputDecoration(
                      hintText: 'Digite uma nova tarefa...',
                      border: OutlineInputBorder(),
                    ),
            autofocus: true,
            onSubmitted: _addTask,
          ),
          FloatingActionButton(
            onPressed: () => _addTask(textController.text),
            tooltip: 'Add text',
            child: const Icon(Icons.add),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: taskList.length + taskListChecked.length,
              itemBuilder: (context, index) {
                final bool isPending = index < taskList.length;
                final itemIndex = isPending ? index 
                  : index - taskList.length;
                final item = isPending ? taskList[itemIndex] 
                  : taskListChecked[itemIndex];
                final isdeleting = deleting.contains(item.$2);
                final isDone = checked.contains(item.$2);
                return Dismissible(
                  key: item.$2,
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      _deleteTask(item.$2);
                    } else if (direction == DismissDirection.startToEnd &&
                            isPending) {
                      _checkTask(item.$2);
                    }
                    return false; 
                  },
                  child: Container( 
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: !isdeleting ?
                    (index%2 == 0 ? Colors.amber : Colors.orange) 
                    : Colors.red,
                  ),
                  child: ListTile(
                  leading: !isDone ? 
                    IconButton( 
                      icon: const Icon(Icons.check_box_outlined),
                      onPressed: () => _checkTask(item.$2),
                    )
                    :
                    IconButton( 
                      icon: const Icon(Icons.check_box),
                      onPressed: () => (),
                    )
                  ,
                  title: 
                    Text(
                      item.$1,
                      style: TextStyle(
                        decoration: isDone ? 
                        TextDecoration.lineThrough : TextDecoration.none
                    )
                  ),
                  trailing: !isdeleting ?
                    IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteTask(item.$2),
                  )
                  :IconButton(
                    icon: const Icon(Icons.undo),
                    onPressed: () => _undoTask(item.$2),
                  ),
                )
               ));
              },
            ),
          ),
        ],
      ),
    );
  }
}
