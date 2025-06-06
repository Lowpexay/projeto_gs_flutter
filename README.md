# Monitoramento Climático

Este é um aplicativo Flutter para monitoramento de eventos climáticos, com funcionalidades de cadastro, login, chatbot inteligente, envio de reportes com localização, imagem e priorização para pessoas com deficiência (PCD).

## Funcionalidades

- **Cadastro e Login**: Usuários podem se cadastrar informando nome, sobrenome, e-mail, senha e se são PCD. Autenticação via Firebase Auth.
- **Registro de clima atual**: Tela inicial do aplicativo. Mostra alertas em tempo real na tela selecionada pelo usuário, mostrando também a temperatura dos próximos 5 dias.
- **Chatbot**: Assistente virtual que responde dúvidas sobre segurança em eventos climáticos, usando IA (Google Gemini API).
- **Reportar Evento**: Usuário pode reportar eventos climáticos críticos, anexar foto, localização e descrição. O sistema valida o risco via IA.
- **Prioridade PCD**: Usuários PCD recebem aviso de prioridade ao enviar reportes críticos.
- **Histórico e Alertas**: Visualização de histórico de reportes e alertas climáticos.
- **Integração com Firebase**: Dados de usuários e reportes salvos no Cloud Firestore.

## Tecnologias Utilizadas

- [Flutter](https://flutter.dev/)
- [Firebase Auth](https://firebase.google.com/products/auth)
- [Cloud Firestore](https://firebase.google.com/products/firestore)
- [Google Gemini API](https://ai.google.dev/)
- [OpenWeatherMap API](https://openweathermap.org/api)
- [OpenMeteo API]()
- [Geolocator](https://pub.dev/packages/geolocator)
- [Image Picker](https://pub.dev/packages/image_picker)
- [Provider](https://pub.dev/packages/provider)
- USGS USA Government Earthquake API
- Twilio

## Estrutura do Projeto

```
lib/
├── main.dart
├── login_page.dart
├── chat_screen.dart
├── report_page.dart
├── alerts_page.dart
├── history_page.dart
├── service/
│   └── auth_service.dart
```

## Como rodar o projeto

1. **Clone o repositório**
   ```sh
   git clone https://github.com/seu-usuario/seu-repo.git
   cd seu-repo
   ```

2. **Configure o Firebase**
   - Crie um projeto no [Firebase Console](https://console.firebase.google.com/).
   - Ative o **Authentication** (método Email/Senha).
   - Ative o **Cloud Firestore**.
   - Baixe o arquivo `google-services.json` (Android) e/ou `GoogleService-Info.plist` (iOS) e coloque nas pastas corretas do projeto.
   - (Opcional) Para testes, ajuste as regras do Firestore para:
     ```
     service cloud.firestore {
       match /databases/{database}/documents {
         match /{document=**} {
           allow read, write: if true;
         }
       }
     }
     ```

3. **Instale as dependências**
   ```sh
   flutter pub get
   ```

4. **Rode o app**
   ```sh
   flutter run
   ```

## Telas principais

### Cadastro/Login

- Campos: Nome, Sobrenome, E-mail, Senha, PCD (switch).
- Usuário PCD recebe prioridade nos reportes.

### Alertas/Clima Atual
- Tela com os alertas em tempo real no localização selecionada pelo usuário. Demonstrando também o clima nos próximos 5 dias
- Inclui a API USGS USA Government Earthquake API que gera reportes de alertar sísmicos

### Chatbot

- Mensagem inicial personalizada com o nome do usuário.
- Responde dúvidas sobre segurança em eventos climáticos.

### Reportar Evento

- Seleção do tipo de evento.
- Descrição, foto e localização.
- Validação automática via IA.
- Mensagem de sucesso personalizada com o nome do usuário.
- Aviso de prioridade para PCD.

### Histórico e Alertas

- Visualização de reportes enviados e alertas recebidos.

## Observações

- **As chaves de API** (Google Gemini, OpenWeatherMap) devem ser configuradas corretamente.
- **Regras do Firestore** abertas são apenas para testes. Para produção, configure regras seguras.
- O app pode ser expandido para incluir notificações, painel administrativo, etc.

## Licença

MIT

---

[Site do projeto](https://gemini.google.com/share/8599b315dcbd) 🚀
