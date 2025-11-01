from doi_mat_backend.app.train_test.voc_dataset import VOCDataset
from torch.utils.data import DataLoader
from torchvision.transforms import ToTensor
from torchvision.models.detection import fasterrcnn_mobilenet_v3_large_fpn, FasterRCNN_MobileNet_V3_Large_FPN_Weights
import torch
from torchvision.models.detection.faster_rcnn import FastRCNNPredictor
from tqdm.autonotebook import tqdm

def collate_fn(batch):
    images, labels = zip(*batch)
    return list(images), list(labels)

def train():
    device = torch.device("cuda") if torch.cuda.is_available() else "cpu"
    num_epochs = 100
    batch_size = 5
    transform = ToTensor()
    train = VOCDataset(root='./VOC2012', year='2012', image_set='train', download=False, transform=transform)
    
    train_dataloader = DataLoader(
        dataset=train,
        batch_size=batch_size,
        shuffle=True,
        num_workers=4,
        collate_fn=collate_fn
    )
    
    model = fasterrcnn_mobilenet_v3_large_fpn(
    weights=FasterRCNN_MobileNet_V3_Large_FPN_Weights.DEFAULT,
    weights_backbone=None
    )
    
    in_features = model.roi_heads.box_predictor.cls_score.in_features
    model.roi_heads.box_predictor = FastRCNNPredictor(in_features, num_classes=len(train.categories))
    model.to(device=device)
    
    optimizer = torch.optim.SGD(model.parameters(), lr=1e-3, momentum=0.9)
    
    for epoch in range(num_epochs):
        model.train()
        progress_bar = tqdm(train_dataloader, colour="cyan")
        for images, labels in progress_bar:
            images = [image.to(device) for image in images]
            labels = [{k: v.to(device) for k, v in target.items()} for target in labels]

            losses = model(images, labels)
            final_loss = sum(loss for loss in losses.values())
            
            optimizer.zero_grad()
            final_loss.backward()
            optimizer.step()
            
            progress_bar.set_description("Epoch {}/{}. Loss: {:.4f}".format(epoch+1, num_epochs, final_loss.item()))
    torch.save(model.state_dict(), "fasterrcnn_mobilenet_weights.pth")
if __name__ == '__main__':
    train()
