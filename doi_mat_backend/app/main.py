# app/main.py
from fastapi import FastAPI, File, UploadFile, HTTPException, Request
from fastapi.responses import JSONResponse
from app.services import ObjectDetectionService
from app.models import PredictionResponse, DescriptionResponse, QuizResponse # <-- Import QuizResponse
from app.video_processor import process_video_for_quiz # <-- Import hàm xử lý
import mimetypes
import os
import uuid
import shutil

# Khởi tạo FastAPI app
app = FastAPI(
    title="Đôi Mắt Thông Minh API",
    description="API for detecting and describing objects in images and videos.", # <-- Cập nhật mô tả
    version="1.0.0"
)


# Khởi tạo service (tải model chỉ một lần)
# Đảm bảo đường dẫn đến file model là chính xác
MODEL_PATH = "fasterrcnn_mobilenet_weights.pth" 
detection_service = ObjectDetectionService(model_path=MODEL_PATH)

# Tạo thư mục tạm cho video nếu chưa có
TEMP_VIDEO_DIR = "temp_videos"
os.makedirs(TEMP_VIDEO_DIR, exist_ok=True)

def generate_description(labels: list[str]) -> str:
    """Hàm tạo câu mô tả đơn giản"""
    if not labels:
        return "Mình không thấy gì đặc biệt trong ảnh này."
    
    unique_labels = list(set(labels))
    
    if len(unique_labels) == 1:
        return f"Trong ảnh này có một {unique_labels[0]}."
    else:
        description = "Trong ảnh này có " + ", ".join(unique_labels[:-1]) + f" và một {unique_labels[-1]}."
        return description

def is_image_file(file: UploadFile) -> bool:
    """
    Kiểm tra xem một file có phải là ảnh không.
    Ưu tiên kiểm tra content_type, nếu không được thì kiểm tra đuôi file.
    """
    # 1. Kiểm tra content_type trước
    if file.content_type and file.content_type.startswith("image/"):
        return True
    
    # 2. Nếu content_type không phải là ảnh, kiểm tra đuôi file
    if file.filename:
        guess = mimetypes.guess_type(file.filename)
        if guess and guess[0] and guess[0].startswith("image/"):
            return True
            
    return False

@app.post("/describe", response_model=DescriptionResponse)
async def describe_image(request: Request, file: UploadFile = File(...)):
    """
    Nhận một ảnh, nhận diện và tạo ra một câu mô tả tự nhiên.
    """
    print(f"Request received for /describe")
    print(f"File received: filename='{file.filename}', content_type='{file.content_type}'")

    # <<<< SỬA ĐỔI ĐIỀU KIỆN KIỂM TRA NÀY >>>
    if not is_image_file(file):
        print("Error: File is not an image or has an unsupported type.")
        raise HTTPException(status_code=400, detail="File provided is not an image or has an unsupported type.")
    
    try:
        image_bytes = await file.read()
        print(f"Image size: {len(image_bytes)} bytes")
        results = detection_service.predict_from_image_bytes(image_bytes)

        if results is None:
            print("Error: Failed to process the image.")
            raise HTTPException(status_code=500, detail="Failed to process the image.")

        labels = [item['label'] for item in results if item['label'] != '__background__']
        description = generate_description(labels)
        
        return DescriptionResponse(description=description, objects=labels)
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# <<<< CŨNG CẦN SỬA ENDPOINT /PREDICT >>>
@app.post("/predict", response_model=PredictionResponse)
async def predict_image(request: Request, file: UploadFile = File(...)):
    """
    Nhận một ảnh, nhận diện các vật thể và trả về bounding boxes.
    """
    print(f"Request received for /predict")
    print(f"File received: filename='{file.filename}', content_type='{file.content_type}'")

    # <<<< SỬA ĐỔI ĐIỀU KIỆN KIỂM TRA NÀY >>>
    if not is_image_file(file):
        print("Error: File is not an image or has an unsupported type.")
        raise HTTPException(status_code=400, detail="File provided is not an image or has an unsupported type.")

    try:
        image_bytes = await file.read()
        results = detection_service.predict_from_image_bytes(image_bytes)
        
        if results is None:
            raise HTTPException(status_code=500, detail="Failed to process the image.")
            
        return PredictionResponse(objects=results)
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/")
def read_root():
    return {"message": "Welcome to the Đôi Mắt Thông Minh API!"}

def is_video_file(file: UploadFile) -> bool:
    """Kiểm tra xem một file có phải là video không."""
    if file.content_type and file.content_type.startswith("video/"):
        return True
    if file.filename:
        guess = mimetypes.guess_type(file.filename)
        if guess and guess[0] and guess[0].startswith("video/"):
            return True
    return False

@app.post("/analyze_video", response_model=QuizResponse)
async def analyze_video(file: UploadFile = File(...)):
    """
    Nhận một video, phân tích và tạo ra các câu hỏi đố.
    """
    print(f"Request received for /analyze_video")
    print(f"File received: filename='{file.filename}', content_type='{file.content_type}'")

    if not is_video_file(file):
        print("Error: File is not a video or has an unsupported type.")
        raise HTTPException(status_code=400, detail="File provided is not a video or has an unsupported type.")

    # Tạo một tên file duy nhất để tránh xung đột
    temp_file_id = str(uuid.uuid4())
    temp_filename = f"{temp_file_id}_{file.filename}"
    temp_filepath = os.path.join(TEMP_VIDEO_DIR, temp_filename)

    try:
        # Lưu file video tạm thời
        with open(temp_filepath, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        print(f"Video saved temporarily at: {temp_filepath}")

        # Gọi hàm xử lý video, truyền vào model và class names đã có
        quiz_questions = process_video_for_quiz(
            video_path=temp_filepath, 
            model=detection_service.model, # <-- Truyền model instance
            voc_classes=detection_service.VOC_CLASSES # <-- Truyền class names
        )
        
        return QuizResponse(questions=quiz_questions)

    except Exception as e:
        print(f"An unexpected error occurred during video processing: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        # Dọn dẹp file tạm sau khi xử lý xong
        if os.path.exists(temp_filepath):
            os.remove(temp_filepath)
            print(f"Temporary video file removed: {temp_filepath}")