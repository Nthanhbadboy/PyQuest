# PyQuest — Gemini Live voice experiment

This branch adds an experimental push-to-talk voice path for the Kai and Lumi tutor personas.

## Build for a private Android test

From the repository root:

```powershell
cd app
flutter pub get
flutter run --dart-define=GEMINI_API_KEY=YOUR_GEMINI_API_KEY
```

Replace the placeholder locally; do not commit a real key or paste it into a public issue or chat. A Dart define is embedded in the app binary and can be extracted. This is acceptable only for a private, short-lived experiment. Before any public distribution, use a server-side session/token flow and rotate any key that may have been exposed.

## How to try it

1. Open a tutor panel.
2. In the voice card, choose **Kai** or **Lumi**.
3. Tap **Nói với Kai/Lumi**, grant microphone permission, and speak Vietnamese or English.
4. Tap **Dừng để nghe câu trả lời**.
5. Check the transcript, spoken reply, and character expression. Repeat with the other character.

This first pass is deliberately push-to-talk: it records 16 kHz mono PCM, sends it to Gemini Live, then plays the returned 24 kHz audio after the model completes the turn. It is not yet continuous full-duplex conversation or interruption/barge-in playback.

## Acceptance checklist

- [ ] `flutter pub get` succeeds.
- [ ] `flutter analyze --no-fatal-infos` succeeds.
- [ ] Existing Flutter tests pass.
- [ ] Android asks for microphone permission only when voice is started.
- [ ] A real Vietnamese utterance is transcribed and receives a real Gemini Live spoken response.
- [ ] Repeat for English and for both Kai and Lumi.
- [ ] Denied microphone permission, missing key, network failure, and quota/model errors are shown without crashing the tutor panel.
- [ ] Verify usage/quota in Google AI Studio; do not assume free unlimited use.

No claim of runtime success should be made until the real-device checklist has been run with a valid key.