import torch
from torchvision.transforms import ToTensor
from torchvision.models.detection import fasterrcnn_mobilenet_v3_large_fpn
from torchvision.models.detection.faster_rcnn import FastRCNNPredictor
import cv2
import numpy as np
from collections import defaultdict
import matplotlib.pyplot as plt

# --- 1. Lớp Object Tracker CẢI TIẾN với Re-ID + ghi lại thời gian tồn tại ---
class ObjectTracker:
    def __init__(self, max_disappeared=10, iou_threshold=0.5, max_lost_age=50):
        self.next_object_id = 0
        self.objects = {}  
        self.disappeared = {}
        self.lost_objects = {}
        self.max_disappeared = max_disappeared
        self.max_lost_age = max_lost_age
        self.iou_threshold = iou_threshold

    def _calculate_iou(self, boxA, boxB):
        xA = max(boxA[0], boxB[0]); yA = max(boxA[1], boxB[1])
        xB = min(boxA[2], boxB[2]); yB = min(boxA[3], boxB[3])
        inter_area = max(0, xB - xA) * max(0, yB - yA)
        if inter_area == 0: return 0
        boxA_area = (boxA[2] - boxA[0]) * (boxA[3] - boxA[1])
        boxB_area = (boxB[2] - boxB[0]) * (boxB[3] - boxB[1])
        return inter_area / float(boxA_area + boxB_area - inter_area)

    def register(self, box, label, frame_count):
        self.objects[self.next_object_id] = {
            'box': box, 
            'label': label, 
            'first_seen': frame_count,   # ✅ Ghi lại frame đầu tiên
            'last_seen': frame_count
        }
        self.disappeared[self.next_object_id] = 0
        self.next_object_id += 1

    def deregister(self, object_id, frame_count):
        obj_data = self.objects[object_id]
        box = obj_data['box']
        cx, cy = (box[0] + box[2]) / 2, (box[1] + box[3]) / 2
        self.lost_objects[object_id] = {
            'label': obj_data['label'],
            'last_box': box,
            'last_pos': (cx, cy),
            'lost_frame': frame_count,
            'first_seen': obj_data['first_seen'],  # ✅ Giữ lại thời điểm bắt đầu
            'last_seen': obj_data['last_seen']
        }
        del self.objects[object_id]
        del self.disappeared[object_id]

    def update(self, detections, frame_count):
        if len(detections) == 0:
            for object_id in list(self.disappeared.keys()):
                self.disappeared[object_id] += 1
                if self.disappeared[object_id] > self.max_disappeared:
                    self.deregister(object_id, frame_count)
            return self.objects

        if len(self.objects) == 0:
            for box, label, _ in detections:
                self.register(box, label, frame_count)
        else:
            current_object_ids = list(self.objects.keys())
            current_objects = [self.objects[id]['box'] for id in current_object_ids]
            iou_matrix = np.zeros((len(current_objects), len(detections)))
            for i, obj_box in enumerate(current_objects):
                for j, (det_box, _, _) in enumerate(detections):
                    iou_matrix[i, j] = self._calculate_iou(obj_box, det_box)

            rows = iou_matrix.max(axis=1).argsort()[::-1]
            cols = iou_matrix.argmax(axis=1)[rows]
            used_row_idxs = set(); used_col_idxs = set()

            for (row, col) in zip(rows, cols):
                if row in used_row_idxs or col in used_col_idxs: 
                    continue
                if iou_matrix[row, col] > self.iou_threshold:
                    object_id = current_object_ids[row]
                    box, label, _ = detections[col]
                    self.objects[object_id].update({
                        'box': box,
                        'label': label,
                        'last_seen': frame_count
                    })
                    self.disappeared[object_id] = 0
                    used_row_idxs.add(row)
                    used_col_idxs.add(col)
            
            unused_row_idxs = set(range(0, iou_matrix.shape[0])).difference(used_row_idxs)
            for row in unused_row_idxs:
                object_id = current_object_ids[row]
                self.disappeared[object_id] += 1
                if self.disappeared[object_id] > self.max_disappeared:
                    self.deregister(object_id, frame_count)

            unused_col_idxs = set(range(0, iou_matrix.shape[1])).difference(used_col_idxs)
            if unused_col_idxs:
                new_detections = [detections[i] for i in unused_col_idxs]
                self.lost_objects = {
                    oid: data for oid, data in self.lost_objects.items()
                    if frame_count - data['lost_frame'] <= self.max_lost_age
                }

                matched_lost_ids = set()
                for det_box, det_label, _ in new_detections:
                    best_match_id = None
                    min_dist = float('inf')
                    det_cx, det_cy = (det_box[0]+det_box[2])/2, (det_box[1]+det_box[3])/2
                    det_w, det_h = det_box[2]-det_box[0], det_box[3]-det_box[1]

                    for lost_id, lost_data in self.lost_objects.items():
                        if lost_id in matched_lost_ids or lost_data['label'] != det_label:
                            continue
                        lost_cx, lost_cy = lost_data['last_pos']
                        lost_box = lost_data['last_box']
                        lost_w, lost_h = lost_box[2]-lost_box[0], lost_box[3]-lost_box[1]
                        dist = np.sqrt((det_cx - lost_cx)**2 + (det_cy - lost_cy)**2)
                        size_similarity = 1 - abs(det_w - lost_w)/(det_w + lost_w + 1e-6)
                        if dist < 100 and size_similarity > 0.5 and dist < min_dist:
                            min_dist = dist
                            best_match_id = lost_id
                    
                    if best_match_id is not None:
                        self.objects[best_match_id] = {
                            'box': det_box,
                            'label': det_label,
                            'first_seen': self.lost_objects[best_match_id]['first_seen'],
                            'last_seen': frame_count
                        }
                        self.disappeared[best_match_id] = 0
                        matched_lost_ids.add(best_match_id)
                        del self.lost_objects[best_match_id]
                    else:
                        self.register(det_box, det_label, frame_count)

        return self.objects

# --- 2. Load model ---
num_classes = 21
model = fasterrcnn_mobilenet_v3_large_fpn(weights=None)
in_features = model.roi_heads.box_predictor.cls_score.in_features
model.roi_heads.box_predictor = FastRCNNPredictor(in_features, num_classes)
model.load_state_dict(torch.load("../../fasterrcnn_mobilenet_weights.pth", map_location="cpu"))
model.eval()

# --- 3. Class names ---
VOC_CLASSES = [
    '__background__', 'aeroplane', 'bicycle', 'bird', 'boat', 'bottle', 
    'bus', 'car', 'cat', 'chair', 'cow', 'diningtable', 'dog', 'horse',
    'motorbike', 'person', 'pottedplant', 'sheep', 'sofa', 'train', 'tvmonitor'
]

# --- 4. Video setup ---
video_path = "../video_test/4.mp4"
cap = cv2.VideoCapture(video_path)
if not cap.isOpened():
    print(f"Không thể mở video tại: {video_path}")
    exit()

fps = cap.get(cv2.CAP_PROP_FPS)
width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

tracker = ObjectTracker(max_disappeared=20, iou_threshold=0.4, max_lost_age=50) 
unique_objects = {}
frame_count = 0
confidence_threshold = 0.5

output_path = "../video_test/output_tracked_video_improved2.mp4"
fourcc = cv2.VideoWriter_fourcc(*'mp4v')
out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))

# --- 5. Xử lý video ---
while True:
    ret, frame = cap.read()
    if not ret:
        break

    frame_count += 1
    print(f"Đang xử lý frame {frame_count}/{total_frames}")

    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    img_tensor = ToTensor()(rgb_frame).unsqueeze(0)

    with torch.no_grad():
        predictions = model(img_tensor)

    boxes = predictions[0]['boxes']
    scores = predictions[0]['scores']
    labels = predictions[0]['labels']
    keep = scores >= confidence_threshold
    
    detections = [(boxes[i].cpu().numpy(), labels[i].cpu().numpy(), scores[i].cpu().numpy())
                  for i in range(len(boxes[keep]))]

    tracked_objects = tracker.update(detections, frame_count)

    for object_id, data in tracked_objects.items():
        box = data['box'].astype(int)
        label_idx = data['label']
        class_name = VOC_CLASSES[label_idx]
        if object_id not in unique_objects:
            unique_objects[object_id] = class_name
        cv2.rectangle(frame, (box[0], box[1]), (box[2], box[3]), (0, 255, 0), 2)
        label_text = f"{class_name} [ID {object_id}]"
        cv2.putText(frame, label_text, (box[0], box[1]-10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0,255,0), 2)

    cv2.putText(frame, f"Frame: {frame_count}", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0,255,0), 2)
    cv2.putText(frame, f"Unique objects: {len(unique_objects)}", (10, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0,255,0), 2)

    out.write(frame)
    cv2.imshow('Object Tracking with Re-ID', frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
out.release()
cv2.destroyAllWindows()

# --- 6. Thống kê kết quả ---
print("\n--- Tổng kết kết quả ---")

# Gộp cả các object đã bị mất
all_objects = {**tracker.objects, **tracker.lost_objects}

# Lọc đối tượng xuất hiện quá ngắn
min_duration = 10  # giây
min_frames = fps * min_duration

filtered_objects = {
    oid: data for oid, data in all_objects.items()
    if (data['last_seen'] - data['first_seen']) >= min_frames
}

final_counts = defaultdict(int)
for oid, data in filtered_objects.items():
    cls_name = VOC_CLASSES[data['label']]
    if cls_name != '__background__':
        final_counts[cls_name] += 1

# In ra console chi tiết
print(f"Tổng số đối tượng thực tế đã phát hiện (sau lọc): {len(filtered_objects)}")
print("\nChi tiết:")
for oid, data in filtered_objects.items():
    duration = (data['last_seen'] - data['first_seen']) / fps
    cls_name = VOC_CLASSES[data['label']]
    print(f"- ID {oid:02d} | {cls_name:12s} | tồn tại: {duration:.2f}s")

print("\nTổng hợp số lượng theo loại:")
for cls_name, count in sorted(final_counts.items(), key=lambda x: x[1], reverse=True):
    print(f"- {cls_name}: {count}")

# Vẽ biểu đồ
if final_counts:
    plt.figure(figsize=(12, 8))
    plt.bar(final_counts.keys(), final_counts.values(), color='skyblue')
    plt.xlabel('Loại đối tượng')
    plt.ylabel('Số lượng')
    plt.title('Thống kê số lượng đối tượng (sau khi lọc <0.5s)')
    plt.xticks(rotation=45, ha='right')
    plt.tight_layout()
    plt.savefig('unique_object_counts_filtered.png')
    print("\n✅ Đã lưu biểu đồ: unique_object_counts_filtered.png")
    plt.show()
