# FutJá ⚽

> Encontre a partida perfeita!  
> App mobile em Flutter para conectar pessoas que querem jogar futebol com partidas próximas.

---

## 📚 Sumário

- [Sobre o projeto](#-sobre-o-projeto)
- [Funcionalidades](#-funcionalidades)
- [Arquitetura e tecnologias](#-arquitetura-e-tecnologias)
- [Estrutura de pastas](#-estrutura-de-pastas)
- [Pré-requisitos](#-pré-requisitos)
- [Configuração do Firebase](#-configuração-do-firebase)
- [Executando o projeto](#-executando-o-projeto)
- [Banco de dados (Cloud Firestore)](#-banco-de-dados-cloud-firestore)
- [Notificações push (FCM)](#-notificações-push-fcm)
- [Roadmap](#-roadmap)
- [Contribuindo](#-contribuindo)
- [Contato](#-contato)

---

## 🔎 Sobre o projeto

O **FutJá** é um aplicativo mobile que facilita a organização e a participação em partidas de futebol amador.

Com ele, o usuário pode:

- Entrar com e-mail e senha.
- Criar partidas com foto, local, data, hora, cidade, nível técnico e número de vagas.
- Ver partidas disponíveis por cidade.
- Confirmar presença ou sair da partida.
- Cancelar partidas que ele mesmo organizou.
- Receber notificações push (FCM) de eventos importantes (estrutura pronta no app).

---

## ✅ Funcionalidades

### Autenticação

- Login e cadastro com **Firebase Auth** (e-mail/senha).
- Estado de autenticação gerenciado por `AuthViewModel`.
- Armazenamento do token FCM do usuário na coleção `users` para futuros envios de notificações.

### Partidas

- Listagem de partidas futuras, filtradas por cidade.
- Cartão com:
    - Nome da partida
    - Local
    - Data e horário formatados
    - Nível técnico
    - Vagas disponíveis (`spotsLeft/maxPlayers`)
    - Foto da quadra/clube (opcional)
- Criação de partidas:
    - Cidade (dropdown com cidades pré-definidas)
    - Local
    - Nome da partida
    - Data e horário
    - Nível técnico (iniciante, intermediário, avançado)
    - Número de vagas
    - Upload de imagem para **Firebase Storage**
- Detalhes da partida:
    - Informações completas da partida
    - Lista de jogadores confirmados
    - Ação para **entrar** ou **sair** da partida
    - Organizador pode **cancelar** a partida

### Notificações

- Inicialização do **Firebase Messaging**.
- Registro de handler para mensagens em:
    - Foreground
    - Background
    - App fechado (terminated)
- Salvamento dos tokens FCM dos usuários na coleção `users`.

---

## 🧱 Arquitetura e tecnologias

- **Framework:** Flutter
- **Linguagem:** Dart
- **Arquitetura:** MVVM simples com `ChangeNotifier`
- **Gerenciamento de estado:** `provider`
- **Backend as a Service:** Firebase
    - `firebase_core`
    - `firebase_auth`
    - `cloud_firestore`
    - `firebase_storage`
    - `firebase_messaging`
- **Outros pacotes:**
    - `image_picker` (upload de imagem da galeria)
- **Camadas principais:**
    - `models/` → entidades e serviços de acesso a dados
    - `viewmodels/` → lógica de apresentação (Auth, MatchList, MatchForm)
    - `views/` → telas (login, home, detalhes, formulário)
    - `core/` → tema e estilos globais

---

## 📁 Estrutura de pastas

```text
lib/
├─ core/
│  └─ app_theme.dart          # Cores e tema da aplicação
├─ models/
│  ├─ app_user.dart           # Modelo de usuário
│  ├─ match.dart              # Modelo de partida (Match)
│  ├─ match_service.dart      # Acesso ao Firestore (matches)
│  └─ storage_service.dart    # Upload de imagens no Firebase Storage
├─ services/
│  └─ auth_service.dart       # Encapsula FirebaseAuth
├─ viewmodels/
│  ├─ auth_view_model.dart    # Estado de autenticação + FCM
│  ├─ match_form_view_model.dart
│  └─ match_list_view_model.dart
├─ views/
│  ├─ login_page.dart
│  ├─ home_page.dart
│  ├─ match_detail_page.dart
│  └─ match_form_page.dart
├─ app.dart                   # MyApp, SplashPage e AuthGate
└─ main.dart                  # bootstrap + Firebase + FCM
