import 'dart:io';

int somadivisores(int n){
  int soma = 0;
  for(int i = 1; i < n; i++){
    if(n%i == 0){
      soma += i;
    }
  }
  return soma;
}

List<int> divisores(int n){
  return [for(int i = 1; i < n; i++) if(n%i == 0) i];
}

bool isperfectnumber(int n){
  if(somadivisores(n)==n){
    return true;
  }
  return false;
}

({bool a, int b}) isabundantnumber(int n){
  int soma = somadivisores(n);
  if(soma > n){
    return (a: true, b: soma);
  }
  return (a: false, b: -1);
}

bool isvalidinput(String input1, String input2){
    if(input1 == '' || input2 == ''){
      return false;
    }
    else if(int.tryParse(input1) == null || int.tryParse(input2) == null){
      return false;
    }
    else if(input1.indexOf(".") != -1 || input2.indexOf(".") != -1){
      return false;
    }
    else if((int.tryParse(input1) ?? 0) < 0 || (int.tryParse(input2) ?? 0) < 0){
      return false;
    }
    return true;
}
void verificaintervalo(int n1, int n2){
   int abundantnumber = 0;
   int soma = 0;
   bool perfectnumbersearched = false;
   for(int i = n1; i <= n2; i++){
      if(isperfectnumber(i)){
        perfectnumbersearched = true;
        List<int> fatores = divisores(i);
        print("$i é um número perfeito.");
        print("Fatores: $fatores");
      }
      if(isabundantnumber(i).a){
         if(isabundantnumber(i).b > soma){
           abundantnumber = i;
           soma = isabundantnumber(i).b;
         }
      }
   }
   if(!perfectnumbersearched){
     print("Nenhum número perfeito encontrado na faixa entre $n1 e $n2.");
   }
   if(abundantnumber == 0){
     print("Nenhum número abundante encontrado na faixa entre $n1 e $n2.");
   }
   else{
     List<int> fatores = divisores(abundantnumber);
     print("Maior número abundante: $abundantnumber");
     print("Fatores: $fatores");
     print("Soma dos fatores: $soma");  
   }
}
void main(){
   String input = stdin.readLineSync() ?? '';
   List<String> partes = input.trim().split(' ');
   if(partes.length == 1){
      print("Por favor forneça dois números inteiros positivos.");
      return;
   }
   String input1 = partes[0];
   String input2 = partes[1];
   int n1 = int.tryParse(input1 ?? '') ?? 0;
   int n2 = int.tryParse(input2 ?? '') ?? 0;
   bool valid = isvalidinput(input1,input2);
   if(!valid){
     print("Por favor forneça dois números inteiros positivos.");
   }
   else if(n1 > n2){
     print("O primeiro número deve ser menor ou igual ao segundo.");
   }
   else{
     verificaintervalo(n1,n2);
   }
}
