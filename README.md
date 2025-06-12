
# Spotify Clone (Flutter + Firebase)

A fully-functional Spotify clone built using **Flutter**, powered by **Firebase**.  
This app offers a seamless music streaming experience with real-time features, beautiful UI, and performance-optimized audio playback.

## Features

- **Authentication**
  - Sign up & login using Firebase Auth.
  - Secure and persistent session management.

- **Music Library**
  - download and stream audio files via Firestore connected with dropbox to upload songs.
  - Organized by albums, songs.

- **Like System**
  - Like/unlike songs and albums with Firestore updates.
  - Personalized liked songs screen.

- **Recent Songs**
  - Tracks and stores recently played songs for each user.

- **Search Functionality**
  - Real-time search for songs and albums.
  - Efficient querying with responsive UI.

- **Audio Playback**
  - Background audio playback using `just_audio` & `just_audio_background`.
  - Full support for notification controls and lockscreen.

- **Mini Player**
  - Interactive bottom mini-player with playback state and navigation.

- **Playlists & Repeat Mode**
  - Create and manage playlists.
  - Enable/disable repeat mode per song.

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Auth, Firestore,  Firestore connected with dropbox)
- **Audio**: just_audio, just_audio_background
- **State Management**: [Specify: Riverpod, Bloc, etc.]
- **Design**: Material 3, Custom Widgets

## Screenshots
<img src="https://github.com/user-attachments/assets/d135c53c-337b-4075-af67-cd76baf85444" width="150"/>
<img src="https://github.com/user-attachments/assets/fc01cf8f-3420-423f-98e6-ed44ae0ad61b" width="150"/>
<img src="https://github.com/user-attachments/assets/16e165b2-3dba-4278-98f4-b16adf94e60e" width="150"/>
<img src="https://github.com/user-attachments/assets/4b64f237-7da4-4a8d-a832-c1c73431a817" width="150"/>
<img src="https://github.com/user-attachments/assets/7681d136-740b-43fa-904c-a1970a15384b" width="150"/>
<img src="https://github.com/user-attachments/assets/3ca4728c-f748-4487-b455-71fa101a1b57" width="150"/>
<img src="https://github.com/user-attachments/assets/a7d47017-625c-423d-a3eb-fc832c173341" width="150"/>
<img src="https://github.com/user-attachments/assets/05ecf929-9ddb-48e2-b612-4664b9b5ad58" width="150"/>
<img src="https://github.com/user-attachments/assets/1fcf104f-0aa9-480b-ae58-103e2269abd5" width="150"/>
<img src="https://github.com/user-attachments/assets/97a89f73-a364-4ed8-b7b5-a5f7f51b3f5f" width="150"/>

## Getting Started

1. Clone the repo
2. Run `flutter pub get`
3. Configure Firebase (Google Services files)
4. Run the app on your emulator or device

```bash
flutter run


