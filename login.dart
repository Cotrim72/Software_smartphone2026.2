import 'dart:convert';
import 'dart:io'; 

Future fazerCadastro(String email, String nome, String senha) async {
  final client = HttpClient();
  final url = Uri.https('barra.cos.ufrj.br:443', '/rest/rpc/registra_usuario');
  
  final Map<String,String> body = {
    'email': email,
    'nome': nome,
    'senha': senha,
  };
  
  final String jsonBody = json.encode(body);
  
  try {
    final request = await client.postUrl(url);
    
    request.headers.set('accept', 'application/json');
    request.headers.set('Content-Type', 'application/json');
    
    request.write(jsonBody);
    
    final response = await request.close();
    await response.drain(); 
  } catch (e) {
    print('Ocorreu um erro: ${e.toString()}');
  } finally {
    client.close(); 
  }
}

Future fazerLogin(String email, String senha) async {
  final client = HttpClient();
  final url = Uri.https('barra.cos.ufrj.br:443', '/rest/rpc/fazer_login');
  final url2 = Uri.https('barra.cos.ufrj.br:443', '/rest/tarefas');
  final url3 = Uri.https('barra.cos.ufrj.br:443', '/rest/tarefas', {'email': "eq.$email"});

  final Map<String,String> body = {
    'email': email,
    'senha': senha,
  };

  final String jsonBody = json.encode(body);
  String jwt = "";

  try {
    final request = await client.postUrl(url);
    request.headers.set('accept', 'application/json');
    request.headers.set('Content-Type', 'application/json');
    request.write(jsonBody);
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join(); // Lê o body como String

    if (response.statusCode == 200) {
      jwt = (json.decode(responseBody))['token'];
      print(jwt);
    } else {
      print('Erro: ${response.statusCode} - $responseBody');
    }
  } catch (e) {
    print('Ocorreu um erro: ${e.toString()}');
  }
  
  final Map<String,Object> body2 = {
    'email': email,
    'valor': []
  };
  final String jsonBody2 = json.encode(body2);
  
  final Map<String,Object> body3 = {
    'valor': []
  };
  final String jsonBody3 = json.encode(body3);
  
  bool existeLista = false;
  
  try {
    final request = await client.getUrl(url2);
    request.headers.set('accept', 'application/json');
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Authorization', 'Bearer $jwt');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode == 200) {
      var dados = json.decode(responseBody);
      if (dados is List && dados.isNotEmpty) {
        existeLista = true;
      }
    } else {
      print('Erro: ${response.statusCode} - $responseBody');
    }    
  } catch(e) {
    print('Ocorreu um erro: ${e.toString()}');
  }

  if (existeLista) {
    try {
      final request = await client.patchUrl(url3);
      request.headers.set('accept', 'application/json');
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'Bearer $jwt');
      request.write(jsonBody3);
      
      final response = await request.close();
      await response.drain();
    } catch(e) {
      print('Ocorreu um erro: ${e.toString()}');
    }
  } else {
    try {
      final request = await client.postUrl(url2);
      request.headers.set('accept', 'application/json');
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'Bearer $jwt');
      request.write(jsonBody2);
      
      final response = await request.close();
      await response.drain();
    } catch(e) {
      print('Ocorreu um erro: ${e.toString()}');
    }
  }
  
  client.close();
}

void main() async {
  await fazerCadastro('subaru5@gmail.com','flamengo', 'suasenha');
  await fazerLogin('subaru5@gmail.com', 'suasenha');
}
