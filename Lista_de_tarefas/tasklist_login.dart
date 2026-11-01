import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gerenciador de Tarefas',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool buttonCadastro = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _fazerLogin(String email, String senha) async {
    final url = Uri.https('barra.cos.ufrj.br:443', 't5/rest/rpc/fazer_login');
    final url2 = Uri.https('barra.cos.ufrj.br:443', 't5/rest/tarefas');

    final Map<String, String> headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final Map<String, String> body = {'email': email, 'senha': senha};
    final String jsonBody = json.encode(body);
    
    String jwt = "";
    bool usuarionaocadastrado = false;
    Map<String, List<TaskItem>> tarefasMapeadas = {
      "notchecked": [],
      "checked": [],
    };

    try {
      final response = await http.post(url, headers: headers, body: jsonBody);

      if (response.statusCode == 200) {
        jwt = (json.decode(response.body))['token'];
      } else if (response.statusCode == 401) {
        final message = (json.decode(response.body))['message'];
        if (message == "Senha inválida!") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Senha inválida!'),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 2),
            ),
          );
        } else if (message == "Usuário não encontrado!") {
          usuarionaocadastrado = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuário não cadastrado!'),
              backgroundColor: Colors.orangeAccent,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return [jwt, tarefasMapeadas, usuarionaocadastrado];
      } else {
        print('Erro: ${response.statusCode} - ${response.body}');
        return [jwt, tarefasMapeadas, usuarionaocadastrado];
      }
    } catch (e) {
      print('Ocorreu um erro: ${e.toString()}');
      return [jwt, tarefasMapeadas, usuarionaocadastrado];
    }

    final Map<String, String> headerstask = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $jwt',
    };

    try {
      final response = await http.get(url2, headers: headerstask);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List && decoded.isNotEmpty) {
          final dadosSalvos = decoded[0];

          if (dadosSalvos is Map && dadosSalvos.containsKey('valor')) {
            final valorBruto = dadosSalvos['valor'];

            if (valorBruto is Map) {
              if (valorBruto['notchecked'] != null) {
                tarefasMapeadas["notchecked"] = (valorBruto['notchecked'] as List)
                    .map((item) => TaskItem(item.toString()))
                    .toList();
              }
              if (valorBruto['checked'] != null) {
                tarefasMapeadas["checked"] = (valorBruto['checked'] as List)
                    .map((item) => TaskItem(item.toString()))
                    .toList();
              }
            }
          }
        }
      } else {
        print('Erro ao carregar tarefas: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Ocorreu um erro ao carregar tarefas: ${e.toString()}');
    }

    return [jwt, tarefasMapeadas, usuarionaocadastrado];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Bem-vindo', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_outline, size: 70, color: Colors.deepPurple),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Digite o seu email',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      hintText: 'Digite a sua senha',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final email = _emailController.text;
                      final senha = _passwordController.text;
                      final result = await _fazerLogin(email, senha);
                      if (result[0] == "") {
                        if (result[2]) {
                          setState(() {
                            buttonCadastro = true;
                          });
                        }
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ListTaskPage(
                              title: "Lista de Tarefas",
                              lista: result[1],
                              email: email,
                              jwt: result[0],
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Entrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  if (buttonCadastro) ...[
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CadastroPage()),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Colors.deepPurple),
                      ),
                      child: const Text('Cadastre o Usuário', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordconfirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _celularController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordconfirmController.dispose();
    super.dispose();
  }

  Future<bool> _fazerCadastro(String celular, String email, String nome, String senha) async {
    final url = Uri.https('barra.cos.ufrj.br:443', 't5/rest/rpc/registra_usuario');
    final Map<String, String> headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final Map<String, String> body = {
      'nome': nome,
      'email': email,
      'celular': celular,
      'senha': senha,
    };
    final String jsonBody = json.encode(body);
    bool sucesso = false;

    try {
      final response = await http.post(url, headers: headers, body: jsonBody);
      if (response.statusCode == 200) {
        sucesso = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário cadastrado com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (response.statusCode == 400) {
        final message = (json.decode(response.body))['message'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 2)),
        );
      }
    } catch (e) {
      print('Ocorreu um erro: ${e.toString()}');
    }
    return sucesso;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Criar Conta', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nome',
                      hintText: 'Digite o seu nome',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _celularController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Celular',
                      hintText: 'Digite o seu número de celular',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.smartphone),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Digite o seu email',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      hintText: 'Digite a sua senha',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordconfirmController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirmação da Senha',
                      hintText: 'Confirme sua senha',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final celular = _celularController.text;
                      final name = _nameController.text;
                      final email = _emailController.text;
                      final senha = _passwordController.text;
                      if (_passwordController.text != _passwordconfirmController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('As senhas não são idênticas'),
                            backgroundColor: Colors.redAccent,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else {
                        final sucesso = await _fazerCadastro(celular, email, name, senha);
                        if (sucesso) Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cadastre-se', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TaskItem {
  final String text;
  final Key key;

  TaskItem(this.text) : key = Key(text);
}

class ListTaskPage extends StatefulWidget {
  final String title;
  final Map<String, List<TaskItem>> lista;
  final String email;
  final String jwt;

  const ListTaskPage({
    super.key,
    required this.title,
    required this.lista,
    required this.email,
    required this.jwt,
  });

  @override
  State<ListTaskPage> createState() => _ListTaskPageState();
}

class _ListTaskPageState extends State<ListTaskPage> {
  late List<TaskItem> taskList = widget.lista["notchecked"] ?? [];
  late List<TaskItem> taskListChecked = widget.lista["checked"] ?? [];
  final textController = TextEditingController();
  final Set<Key> deleting = <Key>{};
  late Set<Key> checked = <Key>{for (var item in taskListChecked) item.key};

  void _addTask(String st) {
    final trimmedText = st.trim();
    if (trimmedText.isEmpty) return;

    final existsInPending = taskList.any(
      (item) => item.text.toLowerCase() == trimmedText.toLowerCase(),
    );
    final existsInChecked = taskListChecked.any(
      (item) => item.text.toLowerCase() == trimmedText.toLowerCase(),
    );

    if (existsInPending || existsInChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta tarefa já foi adicionada!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      taskList.add(TaskItem(trimmedText));
      textController.clear();
    });
  }

  void _deleteTask(Key key) async {
    setState(() {
      deleting.add(key);
    });

    await Future.delayed(const Duration(seconds: 3));

    if (!mounted || !deleting.contains(key)) return;

    setState(() {
      taskList.removeWhere((item) => item.key == key);
      taskListChecked.removeWhere((item) => item.key == key);
      deleting.remove(key);
      checked.remove(key);
    });
  }

  void _undoTask(Key key) {
    setState(() {
      deleting.remove(key);
    });
  }

  void _checkTask(Key key) {
    setState(() {
      final index = taskList.indexWhere((item) => item.key == key);
      if (index != -1) {
        final item = taskList.removeAt(index);
        taskListChecked.insert(0, item);
        checked.add(key);
      }
    });
  }

  Future _salvarLista(String email, String jwt, Map<String, List<TaskItem>> lista) async {
    final url = Uri.https('barra.cos.ufrj.br:443', 't5/rest/tarefas', {
      'email': "eq.$email",
    });

    final Map<String, String> headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $jwt',
    };

    final Map<String, Object> listaSerializada = {
      "notchecked": lista["notchecked"]!.map((item) => item.text).toList(),
      "checked": lista["checked"]!.map((item) => item.text).toList(),
    };

    final Map<String, Object> body = {'valor': listaSerializada};
    final String jsonBody = json.encode(body);

    try {
      final response = await http.patch(url, headers: headers, body: jsonBody);
      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lista salva com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('JWT expirado, faça login novamente.'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Houve um erro ao salvar a lista.'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Ocorreu um erro: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = taskList.length + taskListChecked.length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.deepPurple,
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      hintText: 'Digite uma nova tarefa...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    autofocus: true,
                    onSubmitted: _addTask,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  heroTag: null,
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  onPressed: () => _addTask(textController.text),
                  tooltip: 'Incluir Tarefa',
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.deepPurple.shade100, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: totalItems == 0
                      ? const Center(
                          child: Text(
                            'Nenhuma tarefa cadastrada.',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: totalItems,
                          itemBuilder: (context, index) {
                            final bool isPending = index < taskList.length;
                            final itemIndex = isPending ? index : index - taskList.length;
                            final item = isPending ? taskList[itemIndex] : taskListChecked[itemIndex];

                            final isDeleting = deleting.contains(item.key);
                            final isDone = checked.contains(item.key);

                            return Dismissible(
                              key: item.key,
                              direction: isPending ? DismissDirection.horizontal : DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.endToStart) {
                                  _deleteTask(item.key);
                                } else if (direction == DismissDirection.startToEnd && isPending) {
                                  _checkTask(item.key);
                                }
                                return false;
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: isDeleting
                                      ? Colors.red.shade400
                                      : (index % 2 == 0 ? Colors.amber: Colors.deepOrangeAccent),
                                ),
                                child: ListTile(
                                  leading: Checkbox(
                                    value: isDone,
                                    activeColor: Colors.deepPurple,
                                    onChanged: isDone ? null : (_) => _checkTask(item.key),
                                  ),
                                  title: Text(
                                    item.text,
                                    style: TextStyle(
                                      decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
                                      color: isDeleting
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: isDeleting
                                      ? IconButton(
                                          icon: const Icon(Icons.undo),
                                          onPressed: () => _undoTask(item.key),
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.delete_outline),
                                          onPressed: () => _deleteTask(item.key),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async => await _salvarLista(
                  widget.email,
                  widget.jwt,
                  {"notchecked": taskList, "checked": taskListChecked},
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.save),
                label: const Text('Salvar Lista de Tarefas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
