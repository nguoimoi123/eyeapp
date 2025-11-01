import torch
from torchvision.transforms import ToTensor
from torchvision.models.detection import fasterrcnn_mobilenet_v3_large_fpn
from torchvision.models.detection.faster_rcnn import FastRCNNPredictor
import cv2
import matplotlib.pyplot as plt
from collections import defaultdict
import numpy as np

# --- 1. Load model ---
num_classes = 21  # VOC có 20 lớp + background
model = fasterrcnn_mobilenet_v3_large_fpn(weights=None)
in_features = model.roi_heads.box_predictor.cls_score.in_features
model.roi_heads.box_predictor = FastRCNNPredictor(in_features, num_classes)
model.load_state_dict(torch.load("../../fasterrcnn_mobilenet_weights.pth", map_location="cpu"))
model.eval()

# --- 2. Định nghĩa class names cho VOC dataset ---
VOC_CLASSES = [
    '__background__', 'aeroplane', 'bicycle', 'bird', 'boat', 'bottle', 
    'bus', 'car', 'cat', 'chair', 'cow', 'diningtable', 'dog', 'horse',
    'motorbike', 'person', 'pottedplant', 'sheep', 'sofa', 'train', 'tvmonitor'
]

# --- 3. Mở video ---
video_path = "../video_test/2.mp4"  # <<<< THAY ĐỔI ĐƯỜNG DẪN ĐẾN VIDEO CỦA BẠN
cap = cv2.VideoCapture(video_path)

# Kiểm tra xem video có mở thành công không
if not cap.isOpened():
    print(f"Không thể mở video tại đường dẫn: {video_path}")
    exit()

# Lấy thông tin về video
fps = cap.get(cv2.CAP_PROP_FPS)
width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

print(f"Video: {width}x{height}, {fps} FPS, {total_frames} frames")

# --- 4. Chuẩn bị biến để đếm đối tượng ---
object_counts = defaultdict(int)
total_objects = 0

# --- 5. Xử lý từng frame ---
frame_count = 0
confidence_threshold = 0.5

# Tạo video đầu ra
output_path = "../video_test/output_video.mp4"
fourcc = cv2.VideoWriter_fourcc(*'mp4v')
out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break
    
    frame_count += 1
    print(f"Đang xử lý frame {frame_count}/{total_frames}")
    
    # Chuyển đổi frame từ BGR (OpenCV) sang RGB
    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    
    # Chuyển đổi frame thành tensor
    transform = ToTensor()
    img_tensor = transform(rgb_frame).unsqueeze(0)  # (1, C, H, W)
    
    # Dự đoán
    with torch.no_grad():
        predictions = model(img_tensor)
    
    # Lọc kết quả với ngưỡng confidence
    boxes = predictions[0]['boxes']
    scores = predictions[0]['scores']
    labels = predictions[0]['labels']
    
    # Lọc các detection có confidence >= ngưỡng
    keep = scores >= confidence_threshold
    filtered_boxes = boxes[keep]
    filtered_scores = scores[keep]
    filtered_labels = labels[keep]
    
    # Cập nhật bộ đếm
    for label in filtered_labels:
        class_name = VOC_CLASSES[label.item()]
        object_counts[class_name] += 1
        total_objects += 1
    
    # Vẽ bounding boxes và nhãn lên frame
    for i, (box, score, label) in enumerate(zip(filtered_boxes, filtered_scores, filtered_labels)):
        x1, y1, x2, y2 = box.int().tolist()
        
        # Vẽ bounding box
        cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 0, 255), 2)
        
        # Tạo nhãn với tên class và confidence
        class_name = VOC_CLASSES[label.item()]
        label_text = f'{class_name}: {score:.3f}'
        
        # Thêm nhãn ở góc trên trái của bounding box
        cv2.putText(frame, label_text, (x1, y1 - 5), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 2)
    
    # Hiển thị số lượng đối tượng đã phát hiện trên frame
    cv2.putText(frame, f"Frame: {frame_count}/{total_frames}", (10, 30), 
               cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
    cv2.putText(frame, f"Objects detected: {len(filtered_boxes)}", (10, 60), 
               cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
    
    # Ghi frame vào video đầu ra
    out.write(frame)
    
    # Hiển thị frame (tùy chọn)
    cv2.imshow('Object Detection', frame)
    # Nhấn 'q' để thoát sớm
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# Giải phóng tài nguyên
cap.release()
out.release()
cv2.destroyAllWindows()

# --- 6. In kết quả chi tiết ra console ---
print("\n--- Tổng kết kết quả nhận diện đối tượng ---")
print(f"Tổng số đối tượng đã phát hiện trong toàn bộ video: {total_objects}")
print("\nSố lượng của từng loại đối tượng:")
# Sắp xếp theo số lượng giảm dần
sorted_counts = sorted(object_counts.items(), key=lambda item: item[1], reverse=True)
for class_name, count in sorted_counts:
    if class_name != '__background__':
        print(f"- {class_name}: {count}")

# --- 7. Vẽ biểu đồ thống kê ---
plt.figure(figsize=(12, 8))
# Loại bỏ background khỏi biểu đồ
filtered_counts = {k: v for k, v in object_counts.items() if k != '__background__'}
if filtered_counts:
    objects = list(filtered_counts.keys())
    counts = list(filtered_counts.values())
    
    plt.bar(objects, counts, color='skyblue')
    plt.xlabel('Loại đối tượng')
    plt.ylabel('Số lượng')
    plt.title('Thống kê số lượng các đối tượng trong video')
    plt.xticks(rotation=45, ha='right')
    plt.tight_layout()
    
    # Lưu biểu đồ thành file ảnh
    plt.savefig('object_counts.png')
    print("\nĐã lưu biểu đồ thống kê vào file 'object_counts.png'")
    plt.show()
else:
    print("Không có đối tượng nào được phát hiện trong video.")
