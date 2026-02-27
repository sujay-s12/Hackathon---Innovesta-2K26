
import assemblyai as aai

aai.settings.api_key = "daf4ca973fa349b78a3475f56b05790f"

audio_file = "/Users/praladgurung/SuranaHack/speech-to-text/sample.mp3"


config = aai.TranscriptionConfig(speech_models=["universal-3-pro", "universal-2"], language_detection=True)

transcript = aai.Transcriber(config=config).transcribe(audio_file)

if transcript.status == "error":
  raise RuntimeError(f"Transcription failed: {transcript.error}")

print(transcript.text)