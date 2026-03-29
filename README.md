# FutJá ⚽

> Encontre a partida perfeita!  
> Aplicativo mobile em Flutter para conectar pessoas que querem jogar futebol com partidas próximas.

---

## 📌 Informações

- **Aluno:** Kaio Vinicius Corredor da Silva
- **Vídeo demonstrativo no YouTube:** https://www.youtube.com/watch?v=y-C73NpZy7Y

---

## 📚 Sumário

- [Sobre o projeto](#-sobre-o-projeto)
- [Objetivo](#-objetivo)
- [Funcionalidades](#-funcionalidades)
- [Telas do aplicativo](#-telas-do-aplicativo)
- [Arquitetura e tecnologias](#-arquitetura-e-tecnologias)
- [Estrutura de pastas](#-estrutura-de-pastas)
- [Aplicação dos requisitos](#-aplicação-dos-requisitos)
- [Design Patterns utilizados](#-design-patterns-utilizados)
- [Injeção de Dependência](#-injeção-de-dependência)
- [Testes unitários](#-testes-unitários)
- [Pré-requisitos](#-pré-requisitos)
- [Configuração do Firebase](#-configuração-do-firebase)
- [Executando o projeto](#-executando-o-projeto)
- [Conclusão](#-conclusão)

---

## 🔎 Sobre o projeto

O **FutJá** é um aplicativo mobile desenvolvido em **Flutter** para facilitar a organização e a participação em partidas de futebol amador.

A proposta do app é conectar pessoas que querem jogar futebol com partidas disponíveis em sua cidade, permitindo que os usuários encontrem jogos, criem novas partidas, confirmem presença, visualizem detalhes da partida e gerenciem seu próprio perfil.

O projeto foi estruturado com **Flutter + Firebase**, utilizando **MVVM**, `Provider` para gerenciamento de estado e injeção de dependência, além de uma separação clara entre interface, lógica de apresentação e acesso aos dados.

---

## 🎯 Objetivo

O principal objetivo do aplicativo é oferecer uma experiência simples e funcional para:

- organizar partidas de futebol amador;
- permitir a criação de jogos com informações completas;
- facilitar a busca por partidas disponíveis por cidade;
- permitir a entrada e saída de participantes de forma dinâmica;
- gerenciar o perfil do usuário;
- manter uma estrutura preparada para notificações push com Firebase Cloud Messaging.

---

## ✅ Funcionalidades

### Autenticação
- Cadastro com **e-mail e senha** usando Firebase Authentication.
- Login com **e-mail e senha**.
- Controle do estado de autenticação com `AuthViewModel`.
- Logout do usuário.
- Salvamento do token FCM do usuário para futuras notificações.
- Criação e atualização do documento do usuário na coleção `users`.

### Partidas
- Listagem de partidas futuras.
- Filtro de partidas por cidade.
- Exibição de informações resumidas em cards:
  - nome da partida;
  - local;
  - data e horário;
  - nível técnico;
  - número de vagas disponíveis;
  - imagem do local, quando cadastrada.

### Criação de partidas
- Criação de partidas com:
  - nome da partida;
  - cidade;
  - local;
  - data e horário;
  - nível técnico;
  - número de vagas;
  - imagem opcional do local.
- Persistência dos dados da partida no **Cloud Firestore**.
- Estratégia de salvamento de imagem desacoplada da interface.

### Detalhes da partida
- Visualização completa de uma partida.
- Exibição da lista de jogadores confirmados.
- Entrada e saída da partida.
- Cancelamento da partida pelo organizador.
- Exibição do nome e da foto do usuário confirmado quando disponíveis.

### Perfil do usuário
- Edição de:
  - nome;
  - posição em que joga;
  - idade;
  - peso;
  - foto de perfil.
- Salvamento das informações do perfil no Firestore.
- Exibição da foto do usuário na interface.

### Notificações
- Inicialização do Firebase Messaging.
- Configuração para receber notificações:
  - em foreground;
  - em background;
  - com o app encerrado.
- Estrutura pronta para futuras notificações relacionadas às partidas.

---

## 📱 Telas do aplicativo

O aplicativo possui múltiplas telas funcionais para diferentes fluxos de uso.

### 1. Splash Screen
Tela inicial exibida ao abrir o aplicativo.

### 2. Login / Cadastro
Tela de autenticação com e-mail e senha.

### 3. Home
Tela principal do app, com:
- aba para visualizar partidas;
- aba para criar partidas;
- menu lateral com acesso ao perfil e logout.

### 4. Detalhes da partida
Tela com informações completas da partida e ações de participação.

### 5. Perfil
Tela para edição de dados do usuário.

### 6. Criar partida
Tela dedicada para cadastro de uma nova partida.

---

## 🧱 Arquitetura e tecnologias

### Tecnologias utilizadas
- **Flutter**
- **Dart**
- **Provider**
- **Firebase Core**
- **Firebase Auth**
- **Cloud Firestore**
- **Firebase Messaging**
- **Image Picker**

### Arquitetura adotada
O projeto utiliza uma arquitetura **MVVM (Model-View-ViewModel)**, organizada da seguinte forma:

- **View**: telas e widgets responsáveis pela interface;
- **ViewModel**: classes responsáveis pelo estado e pela lógica de apresentação;
- **Model**: entidades de domínio da aplicação;
- **Service**: camada responsável pela integração com Firebase e persistência dos dados.

### Organização da arquitetura
O fluxo principal da aplicação segue esta estrutura:

**View → ViewModel → Service → Firebase**

- A **View** exibe dados e captura interações do usuário.
- O **ViewModel** controla estado, loading, mensagens de erro e regras de fluxo.
- O **Service** concentra operações externas, como autenticação, leitura e escrita no banco.
- Os **Models** representam os dados utilizados na aplicação.

Essa organização ajuda a manter o projeto mais limpo, modular e fácil de evoluir.

## 🔌 Injeção de Dependência

A injeção de dependência no projeto foi implementada com **Provider**, utilizando `MultiProvider` no arquivo `main.dart`.

No ponto de entrada da aplicação, as dependências principais são registradas de forma global. Isso permite que os serviços e ViewModels sejam disponibilizados para toda a árvore de widgets sem que precisem ser instanciados manualmente em cada tela.

### Dependências registradas

No `main.dart`, são registradas dependências como:

- `IAuthService`
- `IMatchService`
- `IStorageService`
- `IProfileService`
- `AuthViewModel`

Essas dependências são disponibilizadas através do `Provider` e depois consumidas nas telas e nos widgets com `context.read()`, `context.watch()` e `Consumer`.

### Como a injeção de dependência funciona no projeto

O fluxo da injeção de dependência acontece da seguinte forma:

1. O app inicia no `main.dart`;
2. o `MultiProvider` registra as dependências principais;
3. essas dependências ficam disponíveis para a aplicação;
4. as telas acessam essas dependências com `context.read()` ou `context.watch()`;
5. os ViewModels recebem os serviços via construtor;
6. os ViewModels utilizam esses serviços para executar autenticação, leitura e escrita de dados.

### Aplicação prática no projeto

#### Autenticação
- `main.dart` registra `IAuthService`;
- `AuthViewModel` recebe `IAuthService` no construtor;
- `LoginPage` consome `AuthViewModel` para executar login e cadastro.

Nesse fluxo, a tela não acessa o Firebase diretamente.  
Ela delega a ação para o ViewModel, que por sua vez utiliza o serviço injetado.

#### Lista de partidas
- `HomePage` acessa `IMatchService`;
- `MatchListViewModel` recebe `IMatchService` no construtor;
- o ViewModel utiliza esse serviço para carregar, filtrar e observar partidas.

#### Criação de partidas
- `MatchFormViewModel` recebe `IMatchService` e `IStorageService`;
- a lógica de criação da partida fica concentrada no ViewModel;
- a tela apenas envia os dados preenchidos no formulário.

#### Perfil
- `ProfileViewModel` recebe `IProfileService`;
- a tela de perfil não conhece os detalhes de persistência;
- o ViewModel delega a leitura e a gravação dos dados ao serviço injetado.

### Por que isso é injeção de dependência

No projeto, os ViewModels **não criam diretamente** os serviços que utilizam.  
Em vez disso, essas dependências são fornecidas de fora para dentro da aplicação.

Isso caracteriza injeção de dependência porque:
- a classe não depende da criação manual da dependência;
- a dependência é recebida externamente;
- a responsabilidade de montagem do objeto fica centralizada na configuração da aplicação.

### Benefícios obtidos

A aplicação dessa abordagem trouxe os seguintes benefícios:

- redução de acoplamento entre classes;
- maior modularidade;
- melhor organização do projeto;
- facilidade de manutenção;
- facilidade para testes unitários;
- possibilidade de trocar implementações com menos impacto.

Em resumo, a injeção de dependência no projeto foi aplicada para desacoplar os ViewModels da criação direta dos serviços, deixando a arquitetura mais limpa, mais organizada e mais fácil de evoluir.
---

## 📁 Estrutura de pastas

```text
lib/
├─ core/
│  ├─ app_constants.dart
│  ├─ app_theme.dart
│  ├─ auth_error_mapper.dart
│  ├─ date_time_formatter.dart
│  └─ form_validators.dart
│
├─ models/
│  ├─ app_user.dart
│  ├─ match.dart
│  └─ user_profile.dart
│
├─ services/
│  ├─ auth_service.dart
│  ├─ match_service.dart
│  ├─ profile_service.dart
│  └─ storage_service.dart
│
├─ viewmodels/
│  ├─ auth_view_model.dart
│  ├─ match_form_view_model.dart
│  ├─ match_list_view_model.dart
│  └─ profile_view_model.dart
│
├─ views/
│  ├─ home_page.dart
│  ├─ login_page.dart
│  ├─ match_detail_page.dart
│  ├─ match_form_page.dart
│  └─ profile_page.dart
│
├─ widgets/
│  └─ match_form_widget.dart
│
├─ app.dart
└─ main.dart
