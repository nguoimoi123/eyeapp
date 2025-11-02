import socket
from datetime import datetime
import io
import torch
import json  # Thêm import này
from torchvision import transforms
from torchvision.models.detection import fasterrcnn_mobilenet_v3_large_fpn
from torchvision.models.detection.faster_rcnn import FastRCNNPredictor
from PIL import Image

# Danh sách các lớp trong bộ VOC
VOC_CLASSES = [
    '__background__', 'aeroplane', 'bicycle', 'bird', 'boat', 'bottle', 
    'bus', 'car', 'cat', 'chair', 'cow', 'diningtable', 'dog', 'horse',
    'motorbike', 'person', 'pottedplant', 'sheep', 'sofa', 'train', 'tvmonitor'
]

# ================================================================
# 🔹 1️⃣ HÀM KHỞI TẠO MODEL (load trọng số)
# ================================================================
def load_model(weights_path: str):
    print("🔄 Đang khởi tạo mô hình Faster R-CNN...")

    # ⚠️ Đổi pretrained → weights=None để tránh cảnh báo
    model = fasterrcnn_mobilenet_v3_large_fpn(weights=None)

    # ⚙️ Đặt đúng số lớp bạn đã huấn luyện
    num_classes = 21  # ← Sửa số này theo model của bạn
    in_features = model.roi_heads.box_predictor.cls_score.in_features
    model.roi_heads.box_predictor = FastRCNNPredictor(in_features, num_classes)

    # 🧠 Load trọng số
    model.load_state_dict(torch.load(weights_path, map_location="cpu"))
    model.eval()

    print(f"✅ Model đã load trọng số từ: {weights_path}\n")
    return model


# ================================================================
# 🔹 2️⃣ HÀM DỰ ĐOÁN TRÊN FRAME JPEG BYTES
# ================================================================
def predict_frame(model, jpeg_bytes: bytes, threshold=0.5):
    image = Image.open(io.BytesIO(jpeg_bytes)).convert("RGB")

    transform = transforms.Compose([
        transforms.ToTensor(),
    ])
    tensor = transform(image).unsqueeze(0)

    with torch.no_grad():
        preds = model(tensor)[0]

    boxes = preds["boxes"]
    scores = preds["scores"]
    labels = preds["labels"]

    detected = []
    for box, score, label in zip(boxes, scores, labels):
        if score >= threshold:
            detected.append({
                "label": int(label),
                "score": float(score),
                "box": [float(x) for x in box.tolist()]
            })
    return detected


# ================================================================
# 🔹 3️⃣ HÀM CHẠY SERVER UDP NHẬN FRAME TỪ FLUTTER
# ================================================================
def start_udp_server(model, host="0.0.0.0", port=9999):
    BUFFER_SIZE = 65536
    server = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    server.bind((host, port))

    print(f"🚀 UDP Server đang chạy trên {host}:{port}")
    print("⏳ Đang chờ nhận dữ liệu từ Flutter...\n")

    try:
        while True:
            data, addr = server.recvfrom(BUFFER_SIZE)
            timestamp = datetime.now().strftime("%H:%M:%S")

            print(f"[{timestamp}] 📩 Nhận {len(data)} bytes từ {addr}")
            print("📦 Data mẫu:", data[:20])

            # --- Thực hiện dự đoán ---
            try:
                detections = predict_frame(model, data)
                print(f"🎯 Số object phát hiện: {len(detections)}")

                for i, det in enumerate(detections[:5]):  # Giới hạn in 5 kết quả đầu
                    print(
                        f"  #{i+1}: Label={det['label']}, "
                        f"Score={det['score']:.2f}, "
                        f"Box={det['box']}"
                    )
                
                # === THÊM ĐOẠN CODE GỬI KẾT QUẢ VỀ CHO CLIENT ===
                # Chuyển đổi label từ số sang chuỗi
                response_detections = []
                for det in detections:
                    label_index = det['label']
                    label_name = VOC_CLASSES[label_index] if label_index < len(VOC_CLASSES) else "unknown"
                    
                    response_detections.append({
                        "label": label_name,
                        "score": det['score'],
                        "box": det['box']
                    })
                
                # Tạo response JSON
                response = {
                    "object_count": len(detections),
                    "detections": response_detections
                }
                
                # Chuyển đổi thành JSON và gửi về cho client
                response_json = json.dumps(response).encode('utf-8')
                server.sendto(response_json, addr)
                print(f"📤 Đã gửi kết quả về cho {addr}")
                # === KẾT THÚC ĐOẠN CODE THÊM ===
                
            except Exception as e:
                print(f"⚠️ Lỗi khi predict: {e}")

            print("-" * 70)

    except KeyboardInterrupt:
        print("\n🛑 Dừng server.")
    finally:
        server.close()
        print("🔒 Socket đã đóng.")


# ================================================================
# 🔹 4️⃣ MAIN ENTRY
# ================================================================
if __name__ == "__main__":
    # ✅ Thay đường dẫn bằng trọng số bạn đã huấn luyện
    model_path = "fasterrcnn_mobilenet_weights.pth"

    model = load_model(model_path)
    start_udp_server(model)