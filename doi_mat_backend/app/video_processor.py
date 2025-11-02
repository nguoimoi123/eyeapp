# app/video_processor.py
import cv2
import numpy as np
import torch
from torchvision.transforms import ToTensor
from collections import defaultdict
import random

# --- DÁN TOÀN BỘ LỚP OBJECT TRACKER CỦA BẠN VÀO ĐÂY ---
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
            'box': box, 'label': label, 'first_seen': frame_count, 'last_seen': frame_count
        }
        self.disappeared[self.next_object_id] = 0
        self.next_object_id += 1

    def deregister(self, object_id, frame_count):
        obj_data = self.objects[object_id]
        self.lost_objects[object_id] = {
            'label': obj_data['label'], 'last_box': obj_data['box'],
            'last_pos': ((obj_data['box'][0] + obj_data['box'][2]) / 2, (obj_data['box'][1] + obj_data['box'][3]) / 2),
            'lost_frame': frame_count, 'first_seen': obj_data['first_seen'], 'last_seen': obj_data['last_seen']
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
            # ... (copy toàn bộ phần còn lại của hàm update từ script của bạn) ...
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
                    self.objects[object_id].update({'box': box, 'label': label, 'last_seen': frame_count})
                    self.disappeared[object_id] = 0
                    used_row_idxs.add(row); used_col_idxs.add(col)
            
            unused_row_idxs = set(range(0, iou_matrix.shape[0])).difference(used_row_idxs)
            for row in unused_row_idxs:
                object_id = current_object_ids[row]
                self.disappeared[object_id] += 1
                if self.disappeared[object_id] > self.max_disappeared:
                    self.deregister(object_id, frame_count)

            unused_col_idxs = set(range(0, iou_matrix.shape[1])).difference(used_col_idxs)
            if unused_col_idxs:
                new_detections = [detections[i] for i in unused_col_idxs]
                self.lost_objects = {oid: data for oid, data in self.lost_objects.items() if frame_count - data['lost_frame'] <= self.max_lost_age}
                matched_lost_ids = set()
                for det_box, det_label, _ in new_detections:
                    best_match_id = None; min_dist = float('inf')
                    det_cx, det_cy = (det_box[0]+det_box[2])/2, (det_box[1]+det_box[3])/2
                    det_w, det_h = det_box[2]-det_box[0], det_box[3]-det_box[1]
                    for lost_id, lost_data in self.lost_objects.items():
                        if lost_id in matched_lost_ids or lost_data['label'] != det_label: continue
                        lost_cx, lost_cy = lost_data['last_pos']; lost_box = lost_data['last_box']
                        lost_w, lost_h = lost_box[2]-lost_box[0], lost_box[3]-lost_box[1]
                        dist = np.sqrt((det_cx - lost_cx)**2 + (det_cy - lost_cy)**2)
                        size_similarity = 1 - abs(det_w - lost_w)/(det_w + lost_w + 1e-6)
                        if dist < 100 and size_similarity > 0.5 and dist < min_dist:
                            min_dist = dist; best_match_id = lost_id
                    
                    if best_match_id is not None:
                        self.objects[best_match_id] = {'box': det_box, 'label': det_label, 'first_seen': self.lost_objects[best_match_id]['first_seen'], 'last_seen': frame_count}
                        self.disappeared[best_match_id] = 0; matched_lost_ids.add(best_match_id); del self.lost_objects[best_match_id]
                    else:
                        self.register(det_box, det_label, frame_count)
        return self.objects


# --- HÀM TẠO 4 CÂU HỎI (ĐÃ CẢI TIẾN) ---
def create_quiz_from_counts(final_counts):
    questions = []
    if not final_counts or len(final_counts) < 2:
        # Trả về rỗng nếu không đủ đối tượng để tạo câu hỏi
        return questions

    # Lấy danh sách các đối tượng đã được sắp xếp theo số lượng giảm dần
    sorted_counts = sorted(final_counts.items(), key=lambda item: item[1], reverse=True)
    detected_objects = [obj for obj, count in sorted_counts]
    total_animals = sum(final_counts.values())


    # --- Câu 1: Đếm tổng số ---
    options = [str(total_animals)]
    for i in range(1, 4):
        wrong_answer = str(total_animals + i)
        if wrong_answer not in options:
            options.append(wrong_answer)
        if len(options) == 4:
            break
    random.shuffle(options)
    correct_index = options.index(str(total_animals))
    questions.append({
        "question": "Trong video có TẤT CẢ bao nhiêu loài vật?",
        "options": options,
        "correct_answer_index": correct_index
    })

    # --- Câu 2: Đếm một loài vật cụ thể (Vật thể nhiều nhất) ---
    most_common_object, count = sorted_counts[0]
    options = [str(count)]
    # Tạo các đáp án sai xung quanh đáp án đúng
    for i in range(1, 4):
        wrong_answer = str(count + i)
        if wrong_answer not in options:
            options.append(wrong_answer)
        if len(options) == 4:
            break
    random.shuffle(options)
    correct_index = options.index(str(count))
    questions.append({
        "question": f"Trong video có bao nhiêu '{most_common_object}'?",
        "options": options,
        "correct_answer_index": correct_index
    })

    # --- Câu 3: Nhận diện sự có mặt ---
    # Chọn ngẫu nhiên một đối tượng có trong video làm đáp án đúng
    correct_object = random.choice(detected_objects)
    # Lấy các đối tượng khác làm đáp án sai
    wrong_options_pool = [obj for obj in detected_objects if obj != correct_object]
    options = [correct_object]
    while len(options) < 4 and wrong_options_pool:
        options.append(random.choice(wrong_options_pool))
        wrong_options_pool.remove(options[-1])
    random.shuffle(options)
    correct_index = options.index(correct_object)
    questions.append({
        "question": "Loại vật nào sau đây CHẮC CHẮN xuất hiện trong video?",
        "options": options,
        "correct_answer_index": correct_index
    })

    # --- Câu 4: Nhận diện sự vắng mặt ---
    # Lấy một vài đối tượng có trong video
    present_objects = random.sample(detected_objects, k=min(3, len(detected_objects)))
    # Tạo một đối tượng không có trong video (ví dụ)
    all_possible_objects = ['bicycle', 'car', 'motorbike', 'aeroplane', 'bus', 'train', 'truck', 'boat', 'person', 'dog', 'cat', 'horse', 'sheep', 'cow', 'elephant', 'bear', 'zebra', 'giraffe']
    absent_object_candidates = [obj for obj in all_possible_objects if obj not in detected_objects]
    
    if not absent_object_candidates:
        # Nếu không tìm thấy đối tượng vắng mặt, tạo một câu hỏi khác
        least_common_object, count = sorted_counts[-1]
        options = [str(count)]
        for i in range(1, 4):
            wrong_answer = str(count - i) if count - i > 0 else str(count + i)
            if wrong_answer not in options:
                options.append(wrong_answer)
            if len(options) == 4:
                break
        random.shuffle(options)
        correct_index = options.index(str(count))
        questions.append({
            "question": f"Loại vật nào xuất hiện ÍT NHẤT trong video?",
            "options": options,
            "correct_answer_index": correct_index
        })
    else:
        absent_object = random.choice(absent_object_candidates)
        options = present_objects + [absent_object]
        random.shuffle(options)
        correct_index = options.index(absent_object)
        questions.append({
            "question": "Loại vật nào sau đây KHÔNG xuất hiện trong video?",
            "options": options,
            "correct_answer_index": correct_index
        })

    return questions
# --- HÀM XỬ LÝ VIDEO CHÍNH ---
def process_video_for_quiz(video_path, model, voc_classes):
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened(): raise Exception(f"Không thể mở video tại: {video_path}")
    fps = cap.get(cv2.CAP_PROP_FPS)
    tracker = ObjectTracker(max_disappeared=20, iou_threshold=0.4, max_lost_age=50) 
    frame_count = 0; confidence_threshold = 0.5
    frame_skip = max(1, int(fps)) # Xử lý 1 frame mỗi giây
    print(f"Bắt đầu xử lý video: {video_path}")

    while True:
        ret, frame = cap.read()
        if not ret: break
        frame_count += 1
        if frame_count % frame_skip != 0: continue

        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        img_tensor = ToTensor()(rgb_frame).unsqueeze(0).to('cpu')
        with torch.no_grad(): predictions = model(img_tensor)
        
        boxes = predictions[0]['boxes']; scores = predictions[0]['scores']; labels = predictions[0]['labels']
        keep = scores >= confidence_threshold
        boxes = boxes[keep]; scores = scores[keep]; labels = labels[keep]
        detections = [(boxes[i].cpu().numpy(), labels[i].item(), scores[i].item()) for i in range(len(boxes))]
        tracker.update(detections, frame_count)

    cap.release(); print("Hoàn thành xử lý video.")

    # Thống kê
    all_objects = {**tracker.objects, **tracker.lost_objects}
    min_frames = fps * 1 # Lọc đối tượng tồn tại ít nhất 1 giây
    filtered_objects = {oid: data for oid, data in all_objects.items() if (data['last_seen'] - data['first_seen']) >= min_frames}
    final_counts = defaultdict(int)
    for oid, data in filtered_objects.items():
        cls_name = voc_classes[data['label']]
        if cls_name != '__background__': final_counts[cls_name] += 1
    
    print("Kết quả thống kê:", dict(final_counts))
    return create_quiz_from_counts(final_counts)