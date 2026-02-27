import assemblyai as aai
from fastapi import FastAPI, HTTPException, File, UploadFile
from groq import Groq
import json
import os
from google.cloud import vision
from typing import List


app = FastAPI()

os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "/Users/praladgurung/Downloads/gen-lang-client-0857302608-37b199444409.json"

aai.settings.api_key = "daf4ca973fa349b78a3475f56b05790f"
client = Groq(api_key="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")

@app.post("/process-meeting")
async def process_meeting(file: UploadFile = File(...)):
    contents = await file.read()

    with open("temp_audio", "wb") as f:
        f.write(contents)

    config = aai.TranscriptionConfig(speech_models=["universal-2"])
    transcript = aai.Transcriber(config=config).transcribe("temp_audio")

    if transcript.status == "error":
        raise HTTPException(status_code=500, detail=transcript.error)

    summary = summarize_transcript(transcript.text)

    # Return both transcript and summary together
    return {
        "transcript": transcript.text,
        **summary
    }



def summarize_transcript(transcript: str) -> dict:
    prompt = f"""
You are a professional meeting summarizer. Analyze the transcript below and return ONLY a valid JSON object with no extra text, no markdown, no code fences.

The JSON must have exactly these keys:
- "minutes": array of strings — bulleted chronological summary of what happened
- "key_discussion_points": array of strings — main topics discussed
- "decisions": array of objects with keys "decision" (string) and "speaker" (string or null if unknown)
- "action_items": array of objects with keys "task" (string), "owner" (string or null), "deadline" (string or null)

Transcript:
{transcript}

Return only raw JSON.
"""

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[{"role": "user", "content": prompt}]
    )

    raw = response.choices[0].message.content.strip()

    if raw.startswith("```"):
        raw = raw.split("```")[1]
        if raw.startswith("json"):
            raw = raw[4:]
        raw = raw.strip()

    return json.loads(raw)

def images_to_text(image_urls: list[str]) -> str:
    client = vision.ImageAnnotatorClient()
    all_text = []

    for url in image_urls:
        image = vision.Image(source=vision.ImageSource(image_uri=url))
        response = client.document_text_detection(image=image)
        text = response.full_text_annotation.text
        if text:
            all_text.append(text)

    return "\n".join(all_text)

@app.post("/process-images")
async def process_images(files: List[UploadFile] = File(...)):
    client = vision.ImageAnnotatorClient()
    all_text = []

    for file in files:
        contents = await file.read()
        image = vision.Image(content=contents)
        response = client.document_text_detection(image=image)
        text = response.full_text_annotation.text
        if text:
            all_text.append(text)

    if not all_text:
        raise HTTPException(status_code=400, detail="No text found in images")

    raw_text = "\n".join(all_text)
    result = summarize_transcript(raw_text)
    return result