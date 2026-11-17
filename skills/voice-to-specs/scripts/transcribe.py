import whisper
import os
import sys
import argparse
import subprocess


def convert_to_wav(file_path):
    """
    Converts any audio/video file to a 16kHz mono WAV using ffmpeg.
    Returns the path to the converted WAV file, or the original path if already WAV.
    """
    if file_path.lower().endswith(".wav"):
        return file_path
    wav_path = os.path.splitext(file_path)[0] + ".wav"
    print(f"Converting {file_path} to WAV...")
    subprocess.run(
        ["ffmpeg", "-i", file_path, "-ar", "16000", "-ac", "1", "-y", wav_path],
        check=True,
    )
    print(f"Converted to {wav_path}")
    return wav_path


def transcribe_audio(file_path, model_size="base"):
    """
    Converts an audio/video file to WAV via ffmpeg, then transcribes it using Whisper.

    Args:
        file_path (str): The path to the audio/video file.
        model_size (str): The size of the model to use (e.g., "tiny", "base", "small", "medium", "large").
    """
    if not os.path.isfile(file_path):
        print(f"Error: file not found: {file_path}")
        sys.exit(1)

    wav_path = convert_to_wav(file_path)

    print(f"Loading model: {model_size}...")
    model = whisper.load_model(model_size)

    print(f"Transcribing file: {wav_path}...")
    result = model.transcribe(wav_path, verbose=True)

    print("-" * 50)
    print("Transcription complete:")
    print(result["text"])
    print("-" * 50)

    output_filename = os.path.splitext(file_path)[0] + ".txt"
    with open(output_filename, "w") as f:
        f.write(result["text"])
    print(f"Transcription saved to {output_filename}")

    if wav_path != file_path:
        os.remove(wav_path)
        print(f"Cleaned up {wav_path}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Transcribe audio files using Whisper.")
    parser.add_argument("files", nargs="+", help="Path(s) to audio file(s) to transcribe")
    parser.add_argument("--model", default="base", help="Whisper model size (tiny, base, small, medium, large)")
    args = parser.parse_args()

    for audio_file in args.files:
        transcribe_audio(audio_file, model_size=args.model)
