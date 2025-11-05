# app/services.py
import torch
from torchvision.transforms import ToTensor
from torchvision.models.detection import fasterrcnn_mobilenet_v3_large_fpn
from torchvision.models.detection.faster_rcnn import FastRCNNPredictor
from torchvision.ops import nms
from PIL import Image
import io

VOC_CLASSES = [
    '__background__', 'aeroplane', 'bicycle', 'bird', 'boat', 'bottle',
    'bus', 'car', 'cat', 'chair', 'cow', 'diningtable', 'dog', 'horse',
    'motorbike', 'person', 'pottedplant', 'sheep', 'sofa', 'train', 'tvmonitor'
]

class ObjectDetectionService:
    def __init__(self, model_path: str, use_half: bool = True):
        """
        ✅ Load model 1 lần, cho phép dùng FP16 để giảm RAM nếu có GPU.
        """
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.use_half = use_half and (self.device.type == "cuda")
        self.model = self._load_model(model_path)
        self.transform = ToTensor()
        self.VOC_CLASSES = VOC_CLASSES

    def _load_model(self, model_path: str):
        """✅ Load model vào GPU/CPU và chuyển sang FP16 nếu có thể"""
        num_classes = len(VOC_CLASSES)
        model = fasterrcnn_mobilenet_v3_large_fpn(weights=None)
        in_features = model.roi_heads.box_predictor.cls_score.in_features
        model.roi_heads.box_predictor = FastRCNNPredictor(in_features, num_classes)

        # Load trọng số
        model.load_state_dict(torch.load(model_path, map_location=self.device))
        model.to(self.device)

        # ✅ Chuyển sang FP16 nếu có GPU (giảm RAM ~40-50%)
        if self.use_half:
            model = model.half()

        model.eval()
        print(f"✅ Model loaded on {self.device} | FP16 = {self.use_half}")
        return model

    @torch.no_grad()  # ✅ Tắt gradient → giảm RAM + tăng tốc
    def predict_from_image_bytes(self, image_bytes: bytes, confidence_threshold: float = 0.5):
        try:
            # 1. Load ảnh
            image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
            img_tensor = self.transform(image).unsqueeze(0).to(self.device)

            # ✅ Nếu model dùng FP16 thì ảnh cũng phải FP16
            if self.use_half:
                img_tensor = img_tensor.half()

            # 2. Dự đoán
            outputs = self.model(img_tensor)[0]

            boxes = outputs['boxes']
            scores = outputs['scores']
            labels = outputs['labels']

            # 3. Lọc confidence
            keep = scores >= confidence_threshold
            boxes = boxes[keep]
            scores = scores[keep]
            labels = labels[keep]

            if len(boxes) == 0:
                return []

            # 4. Non-Max Suppression (NMS)
            keep_idx = nms(boxes, scores, iou_threshold=0.5)
            boxes = boxes[keep_idx].tolist()
            scores = scores[keep_idx].tolist()
            labels = labels[keep_idx].tolist()

            # 5. Format kết quả
            results = [
                {
                    "box": boxes[i],
                    "label": self.VOC_CLASSES[labels[i]],
                    "score": float(scores[i])
                }
                for i in range(len(boxes))
            ]

            return results

        except Exception as e:
            print(f"❌ Prediction error: {e}")
            return None
