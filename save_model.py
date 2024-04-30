import torch

class NoOpModule(torch.nn.Module):

    def forward(self, input_data):
        return torch.tensor(0)

model = torch.jit.script(NoOpModule())
torch.jit.save(model, "model/model.pt")

# tar -czvf model.tar.gz model
# aws s3 cp model.tar.gz s3://instance-transfer/model.tar.gz
