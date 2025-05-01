# NeuroKick - macOS Audio Recorder with Local LLM Analysis

A simple macOS audio recording application created with Swift.

## Features

- Record audio from the built-in microphone
- Play back recorded audio
- Save recordings as .m4a files

## Requirements

- macOS 11.0+
- Xcode 13.0+
- Swift 5.5+

## Local LLM Setup (Required for Analysis Features)

This application uses a local LLM (Google Gemma 2B) via the Ollama server for transcription analysis and summarization. To enable these features, follow these one-time setup steps on your machine:

1.  **Install Ollama:**
    If you use Homebrew:
    ```bash
    brew install ollama
    ```
    Alternatively, download from the [Ollama website](https://ollama.com/).

2.  **Download the Gemma 2B Model:**
    Open your terminal and run:
    ```bash
    ollama pull gemma:2b
    ```
    This will download the necessary model files (approx. 1.7GB).

3.  **Run the Ollama Server:**
    The Ollama server needs to be running in the background for the app to connect. If you installed via Homebrew, it might already be running as a service. You can ensure it's running by opening your terminal and typing:
    ```bash
    ollama serve
    ```
    If it's already running, you'll see an "address already in use" error, which is fine. If it starts, keep this terminal window open while using the NeuroKick app.

## How to Use

1.  Ensure the Ollama server is running (see step 3 above).
2.  Open `MacAudioRecorder.xcodeproj` in Xcode.
3.  Select a target simulator or connected device.
4.  Build and run the application (⌘-R).

Now you can use the "Workplace Analysis", "Behavioural Analysis", and "General Summary" buttons, which will utilize the local Gemma 2B model.

## Project Structure

- `AppDelegate.swift`: Main application delegate
- `AudioRecorder.swift`: Audio recording functionality
- `MainViewController.swift`: Main view controller for the application
- `MainMenu.xib`: Main menu interface
