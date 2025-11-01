from torchvision.datasets import VOCDetection
from torchvision.transforms import ToTensor
import torch
from pprint import pprint

class VOCDataset(VOCDetection):
    def __init__(self, root, year, image_set, download, transform):
        super().__init__(root, year, image_set, download, transform)
        self.categories = VOC_CLASSES = ["background", "aeroplane", "bicycle", "bird", "boat", "bottle", "bus", "car", "cat", "chair", "cow", "diningtable", "dog", "horse", "motorbike", "person", "pottedplant", "sheep", "sofa", "train", "tvmonitor"]

    def __getitem__(self, item):
        image, data = super().__getitem__(item)
        target = {}
        all_bboxes = []
        all_labels = []
        for obj in data['annotation']['object']:
            xmin = int(obj['bndbox']['xmin'])
            ymin = int(obj['bndbox']['ymin'])
            xmax = int(obj['bndbox']['xmax'])
            ymax = int(obj['bndbox']['ymax'])
            all_bboxes.append([xmin, ymin, xmax, ymax])
            all_labels.append(self.categories.index(obj['name']))
        all_bboxes = torch.FloatTensor(all_bboxes)
        all_labels = torch.LongTensor(all_labels)
        target = {'boxes': all_bboxes,
                  'labels': all_labels}
        return image, target
if __name__ == '__main__':
    transfrom = ToTensor()
    dataset = VOCDataset(root='./VOC2012', year='2012', image_set='train', download=False, transform=transfrom)
    image, lable = dataset[1000]
    pprint(image)
    pprint(lable)
