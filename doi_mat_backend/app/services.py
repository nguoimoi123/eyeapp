# app/services.py
import torch
from torchvision.transforms import ToTensor
from torchvision.models.detection import fasterrcnn_mobilenet_v3_large_fpn
from torchvision.models.detection.faster_rcnn import FastRCNNPredictor
from torchvision.ops import nms
from PIL import Image
import io

# Danh sách các lớp trong bộ VOC
VOC_CLASSES = [
    '__background__', 'aeroplane', 'bicycle', 'bird', 'boat', 'bottle', 
    'bus', 'car', 'cat', 'chair', 'cow', 'diningtable', 'dog', 'horse',
    'motorbike', 'person', 'pottedplant', 'sheep', 'sofa', 'train', 'tvmonitor'
]

class ObjectDetectionService:
    def __init__(self, model_path: str):
        """Khởi tạo model khi service được tạo"""
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.model = self._load_model(model_path)
        self.transform = ToTensor()

    def _load_model(self, model_path: str):
        """Tải model từ file .pth"""
        num_classes = len(VOC_CLASSES)
        model = fasterrcnn_mobilenet_v3_large_fpn(weights=None)
        in_features = model.roi_heads.box_predictor.cls_score.in_features
        model.roi_heads.box_predictor = FastRCNNPredictor(in_features, num_classes)
        model.load_state_dict(torch.load(model_path, map_location=self.device))
        model.to(self.device)
        model.eval()
        print("✅ Model loaded successfully!")
        return model

    def predict_from_image_bytes(self, image_bytes: bytes, confidence_threshold: float = 0.5):
        """Dự đoán đối tượng từ ảnh (bytes) → trả về danh sách box, label, score"""
        try:
            # 1️⃣ Đọc ảnh từ bytes
            image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
            img_tensor = self.transform(image).unsqueeze(0)

            # 2️⃣ Chạy model để lấy kết quả
            with torch.no_grad():
                predictions = self.model(img_tensor.to(self.device))

            pred_boxes = predictions[0]['boxes']
            pred_scores = predictions[0]['scores']
            pred_labels = predictions[0]['labels']

            # 3️⃣ Lọc confidence thấp
            mask = pred_scores >= confidence_threshold
            boxes = pred_boxes[mask]
            scores = pred_scores[mask]
            labels = pred_labels[mask]

            if len(boxes) == 0:
                return []

            # 4️⃣ Áp dụng Non-Max Suppression (NMS)
            keep = nms(boxes, scores, iou_threshold=0.5)

            final_boxes = boxes[keep].tolist()
            final_scores = scores[keep].tolist()
            final_labels = labels[keep].tolist()

            # 5️⃣ Chuẩn hóa kết quả
            results = [
                {
                    "box": final_boxes[i],
                    "label": VOC_CLASSES[final_labels[i]],
                    "score": float(final_scores[i])
                }
                for i in range(len(final_boxes))
            ]
            return results

        except Exception as e:
            print(f"❌ Error during prediction: {e}")
            return None
