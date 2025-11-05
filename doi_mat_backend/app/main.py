from fastapi import FastAPI, File, UploadFile, HTTPException, Request
from fastapi.responses import JSONResponse
from app.services import ObjectDetectionService
from app.models import PredictionResponse, DescriptionResponse, QuizResponse
from app.video_processor import process_video_for_quiz
import mimetypes
import uuid
import os
import shutil

app = FastAPI(
    title="Đôi Mắt Thông Minh API",
    description="API for detecting and describing objects in images and videos.",
    version="1.0.0"
)

MODEL_PATH = "fasterrcnn_mobilenet_weights.pth"
detection_service = None  # Lazy load

TEMP_VIDEO_DIR = "temp_videos"
os.makedirs(TEMP_VIDEO_DIR, exist_ok=True)

def get_detection_service():
    """Chỉ load model lần đầu tiên khi có request."""
    global detection_service
    if detection_service is None:
        print("🔄 Loading model to RAM ...")
        detection_service = ObjectDetectionService(
            model_path=MODEL_PATH,
            use_half=True  # FP16 - giảm RAM nếu có GPU
        )
    return detection_service

def is_image_file(file: UploadFile) -> bool:
    if file.content_type and file.content_type.startswith("image/"):
        return True
    if file.filename:
        mime = mimetypes.guess_type(file.filename)[0]
        if mime and mime.startswith("image/"):
            return True
    return False

@app.get("/")
def root():
    return {"message": "Welcome to the Đôi Mắt Thông Minh API!"}

@app.post("/describe", response_model=DescriptionResponse)
async def describe_image(file: UploadFile = File(...)):
    if not is_image_file(file):
        raise HTTPException(status_code=400, detail="File is not an image.")
    try:
        service = get_detection_service()
        image_bytes = await file.read()
        results = service.predict_from_image_bytes(image_bytes)
        labels = [item['label'] for item in results if item['label'] != '__background__']

        if not labels:
            description = "Mình không thấy gì đặc biệt trong ảnh này."
        else:
            unique = list(set(labels))
            if len(unique) == 1:
                description = f"Trong ảnh này có một {unique[0]}."
            else:
                description = "Trong ảnh này có " + ", ".join(unique[:-1]) + f" và một {unique[-1]}."
        return DescriptionResponse(description=description, objects=labels)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/predict", response_model=PredictionResponse)
async def predict_image(file: UploadFile = File(...)):
    if not is_image_file(file):
        raise HTTPException(status_code=400, detail="File is not an image.")
    try:
        service = get_detection_service()
        image_bytes = await file.read()
        results = service.predict_from_image_bytes(image_bytes)
        return PredictionResponse(objects=results)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def is_video_file(file: UploadFile) -> bool:
    if file.content_type and file.content_type.startswith("video/"):
        return True
    if file.filename:
        mime = mimetypes.guess_type(file.filename)[0]
        if mime and mime.startswith("video/"):
            return True
    return False

@app.post("/analyze_video", response_model=QuizResponse)
async def analyze_video(file: UploadFile = File(...)):
    if not is_video_file(file):
        raise HTTPException(status_code=400, detail="File is not a valid video.")

    temp_id = str(uuid.uuid4())
    temp_filename = f"{temp_id}_{file.filename}"
    temp_path = os.path.join(TEMP_VIDEO_DIR, temp_filename)

    try:
        with open(temp_path, "wb") as f:
            shutil.copyfileobj(file.file, f)

        service = get_detection_service()
        quiz = process_video_for_quiz(
            video_path=temp_path,
            model=service.model,
            voc_classes=service.VOC_CLASSES
        )
        return QuizResponse(questions=quiz)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)
