import torch
from torchvision.transforms import ToTensor
from torchvision.models.detection import fasterrcnn_mobilenet_v3_large_fpn
from torchvision.models.detection.faster_rcnn import FastRCNNPredictor
from PIL import Image
import matplotlib.pyplot as plt
import cv2
import numpy as np

# --- 0. Kiểm tra và thiết lập device ---
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
print(f"Using device: {device}")

if torch.cuda.is_available():
    print(f"GPU: {torch.cuda.get_device_name(0)}")
    print(f"GPU Memory: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB")

# --- 1. Load model và chuyển sang GPU ---
num_classes = 21  # VOC có 20 lớp + background
model = fasterrcnn_mobilenet_v3_large_fpn(weights=None)
in_features = model.roi_heads.box_predictor.cls_score.in_features
model.roi_heads.box_predictor = FastRCNNPredictor(in_features, num_classes)

# Load weights và chuyển model sang device
model.load_state_dict(torch.load("fasterrcnn_mobilenet_weights.pth", map_location=device))
model.to(device)
model.eval()

# --- 2. Định nghĩa class names cho VOC dataset ---
VOC_CLASSES = [
    '__background__', 'aeroplane', 'bicycle', 'bird', 'boat', 'bottle', 
    'bus', 'car', 'cat', 'chair', 'cow', 'diningtable', 'dog', 'horse',
    'motorbike', 'person', 'pottedplant', 'sheep', 'sofa', 'train', 'tvmonitor'
]

<<<<<<< HEAD:train_test/test_faster_RCNN.py
# --- 3. Load ảnh test ---
img = Image.open("3.jpg").convert("RGB")
transform = ToTensor()
img_tensor = transform(img).unsqueeze(0)  # (1, C, H, W)

# --- 4. Dự đoán ---
with torch.no_grad():
    predictions = model(img_tensor)

# --- 5. Lọc kết quả với ngưỡng confidence ---
confidence_threshold = 0.5
boxes = predictions[0]['boxes']
scores = predictions[0]['scores']
labels = predictions[0]['labels']

# Lọc các detection có confidence >= ngưỡng
keep = scores >= confidence_threshold
filtered_boxes = boxes[keep]
filtered_scores = scores[keep]
filtered_labels = labels[keep]

print(f"Found {len(filtered_boxes)} detections with confidence >= {confidence_threshold}")

# --- 6. Hiển thị hình với bounding boxes và nhãn ---
fig, ax = plt.subplots(1, figsize=(12, 8))
ax.imshow(img)

for i, (box, score, label) in enumerate(zip(filtered_boxes, filtered_scores, filtered_labels)):
    x1, y1, x2, y2 = box
=======
def detect_objects_image(image_path, confidence_threshold=0.5, show_result=True):
    """
    Hàm phát hiện vật thể trong ảnh
>>>>>>> 79ce1df83bf5d74c34efd7b4237b385e53f243ce:test_faster_RCNN.py
    
    Args:
        image_path (str): Đường dẫn đến file ảnh
        confidence_threshold (float): Ngưỡng confidence để lọc kết quả
        show_result (bool): Có hiển thị kết quả hay không
    
    Returns:
        dict: Kết quả detection gồm boxes, scores, labels
    """
    # --- 3. Load ảnh test và chuyển sang GPU ---
    img = Image.open(image_path).convert("RGB")
    transform = ToTensor()
    img_tensor = transform(img).unsqueeze(0).to(device)  # (1, C, H, W) trên GPU

    # --- 4. Dự đoán ---
    with torch.no_grad():
        predictions = model(img_tensor)

    # Chuyển predictions về CPU để xử lý
    predictions = [{k: v.cpu() for k, v in p.items()} for p in predictions]

    # --- 5. Lọc kết quả với ngưỡng confidence ---
    boxes = predictions[0]['boxes']
    scores = predictions[0]['scores']
    labels = predictions[0]['labels']

    # Lọc các detection có confidence >= ngưỡng
    keep = scores >= confidence_threshold
    filtered_boxes = boxes[keep]
    filtered_scores = scores[keep]
    filtered_labels = labels[keep]

    print(f"Found {len(filtered_boxes)} detections with confidence >= {confidence_threshold}")

    # --- 6. Hiển thị hình với bounding boxes và nhãn ---
    if show_result:
        fig, ax = plt.subplots(1, figsize=(12, 8))
        ax.imshow(img)

        for i, (box, score, label) in enumerate(zip(filtered_boxes, filtered_scores, filtered_labels)):
            x1, y1, x2, y2 = box.numpy()  # Chuyển tensor thành numpy array
            
            # Vẽ bounding box
            rect = plt.Rectangle((x1, y1), x2-x1, y2-y1, 
                                fill=False, color='red', linewidth=2)
            ax.add_patch(rect)
            
            # Tạo nhãn với tên class và confidence
            class_name = VOC_CLASSES[label]
            label_text = f'{class_name}: {score:.3f}'
            
            # Thêm nhãn ở góc trên trái của bounding box
            ax.text(x1, y1 - 5, label_text, 
                    fontsize=10, color='white', weight='bold',
                    bbox=dict(boxstyle="round,pad=0.3", facecolor='red', alpha=0.8))

        plt.title(f'Object Detection Results - {len(filtered_boxes)} objects detected (Device: {device})')
        plt.axis('off')
        plt.tight_layout()
        plt.show()

    # --- 7. In kết quả chi tiết ra console ---
    print("\n--- Detailed Detection Results ---")
    for i, (box, score, label) in enumerate(zip(filtered_boxes, filtered_scores, filtered_labels)):
        class_name = VOC_CLASSES[label]
        print(f"Object {i+1}: {class_name} (confidence: {score:.3f})")
        print(f"  Bounding box: [{box[0]:.1f}, {box[1]:.1f}, {box[2]:.1f}, {box[3]:.1f}]")

    # Trả về kết quả dưới dạng dictionary
    result = {
        'boxes': filtered_boxes,
        'scores': filtered_scores,
        'labels': filtered_labels,
        'class_names': [VOC_CLASSES[label] for label in filtered_labels]
    }
    
    return result

def detect_objects_video(video_path, confidence_threshold=0.5):
    cap = cv2.VideoCapture(video_path)
    
    # Properties
    frame_width = int(cap.get(3))
    frame_height = int(cap.get(4))
    fps = cap.get(cv2.CAP_PROP_FPS)

    # Writer
    fourcc = cv2.VideoWriter_fourcc(*'XVID')
    out = cv2.VideoWriter('output.mp4', fourcc, fps, (frame_width, frame_height))
    
    
    while cap.isOpened():
        flag, frame = cap.read()
        if not flag:
            break
        image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        image = np.transpose(image, (2, 0, 1))/255
        image = [torch.from_numpy(image).float()]
        model.eval()
        with torch.no_grad():
            output = model(image)[0]
            bboxes = output['boxes']
            scores = output['scores']
            labels = output['labels']
            for bbox, label, score in zip(bboxes, labels, scores):
                if score > confidence_threshold:
                    xmin, ymin, xmax, ymax = bbox
                    cv2.rectangle(frame, (int(xmin), int(ymin)), (int(xmax), int(ymax)), (0, 0, 255), 3)
                    category = VOC_CLASSES[label]
                    cv2.putText(frame, category, (int(xmin), int(ymin)), cv2.FONT_HERSHEY_SIMPLEX ,
                            1, (0, 255, 0), 3, cv2.LINE_AA)
        out.write(frame)
    cap.release()
    out.release()
# --- Sử dụng hàm ---
if __name__ == "__main__":
    # Gọi hàm detect_objects với đường dẫn ảnh
    # detection_result = detect_objects_image("image.png", confidence_threshold=0.5, show_result=True)
    
    detection_result = detect_objects_video("video.mp4", confidence_threshold=0.5)
    
    # --- 8. Cleanup GPU memory ---
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
        print(f"\nGPU memory cleared. Current memory usage: {torch.cuda.memory_allocated() / 1024**2:.1f} MB")