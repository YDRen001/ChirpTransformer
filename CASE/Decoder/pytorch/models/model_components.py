# models.py
#
# This file contains the models used for both parts of the assignment:
#
#   - DCGenerator       --> Used in the vanilla GAN
#   - CycleGenerator    --> Used in the CycleGAN
#   - DCDiscriminator   --> Used in both the vanilla GAN and CycleGAN
#
# For the assignment, you are asked to create the architectures of these three networks by
# filling in the __init__ methods in the DCGenerator, CycleGenerator, and DCDiscriminator classes.
# Note that the forward passes of these models are provided for you, so the only part you need to
# fill in is __init__.

import torch
import torch.nn as nn
import torch.nn.functional as F


class classificationHybridModel(nn.Module):
    """Defines the architecture of the discriminator network.
       Note: Both discriminators D_X and D_Y have the same architecture in this assignment.
    """

    def __init__(self, conv_dim_in=2,conv_dim_out=128,conv_dim_lstm=1024):
        super(classificationHybridModel, self).__init__()

        self.out_size=conv_dim_out
        self.conv1 = nn.Conv2d(conv_dim_in, 16, (3, 3), stride=(2, 2), padding=(1, 1))
        self.pool1=nn.MaxPool2d((4,2), stride=(4, 2))

        self.dense = nn.Linear(conv_dim_lstm*2, conv_dim_out*64)

        self.fcn1 = nn.Linear(conv_dim_out*64, conv_dim_out*8)
        # self.fcn1 = nn.Linear(conv_dim_lstm*4, conv_dim_out*4)
        self.fcn2 = nn.Linear(8 * conv_dim_out, conv_dim_out)
        
        self.softmax=nn.Softmax(dim=1)
        self.drop1 = nn.Dropout(0.2)
        self.drop2 = nn.Dropout(0.5)
        self.act = nn.ReLU()

    def forward(self, x):
        out = self.act(self.conv1(x))
        out = self.pool1(out)
        out = out.view(out.size(0), -1)

        out=self.act(self.dense(out))
        out=self.drop2(out)

        out = self.act(self.fcn1(out))
        out=self.drop1(out)

        # out = self.softmax(self.fcn2(out))
        out = self.fcn2(out)
        return out


# Revised from Voice-filter model, consider to delete embedder (Or use noise embedder, since different code has different
# spectrogram, and we have no idea what's the code in the input spectrogram)

class maskCNNModel(nn.Module):
    def __init__(self, opts):
        super(maskCNNModel, self).__init__()
        self.opts = opts

        self.conv = nn.Sequential(
            # cnn1
            nn.ZeroPad2d((3, 3, 0, 0)),
            nn.Conv2d(opts.x_image_channel, 64, kernel_size=(1, 7), dilation=(1, 1)),
            nn.BatchNorm2d(64), nn.ReLU(),

            # cnn2
            nn.ZeroPad2d((0, 0, 3, 3)),
            nn.Conv2d(64, 64, kernel_size=(7, 1), dilation=(1, 1)),
            nn.BatchNorm2d(64), nn.ReLU(),

            # cnn3
            nn.ZeroPad2d(2),
            nn.Conv2d(64, 64, kernel_size=(5, 5), dilation=(1, 1)),
            nn.BatchNorm2d(64), nn.ReLU(),

            # cnn4
            nn.ZeroPad2d((2, 2, 4, 4)),
            nn.Conv2d(64, 64, kernel_size=(5, 5), dilation=(2, 1)),  # (9, 5)
            nn.BatchNorm2d(64), nn.ReLU(),

            # cnn5
            nn.ZeroPad2d((2, 2, 8, 8)),
            nn.Conv2d(64, 64, kernel_size=(5, 5), dilation=(4, 1)),  # (17, 5)
            nn.BatchNorm2d(64), nn.ReLU(),

            # cnn6
            nn.ZeroPad2d((2, 2, 16, 16)),
            nn.Conv2d(64, 64, kernel_size=(5, 5), dilation=(8, 1)),  # (33, 5)
            nn.BatchNorm2d(64), nn.ReLU(),

            # # cnn7
            # nn.ZeroPad2d((2, 2, 32, 32)),
            # nn.Conv2d(64, 64, kernel_size=(5, 5), dilation=(16, 1)),  # (65, 5)
            # nn.BatchNorm2d(64), nn.ReLU(),

            # cnn8
            nn.Conv2d(64, 8, kernel_size=(1, 1), dilation=(1, 1)),
            nn.BatchNorm2d(8), nn.ReLU(),
        )

        self.lstm = nn.LSTM(
            # 8 * opts.image_height + opts.embedding,
            # 8 * int(opts.stft_nfft/2+1),
            opts.y_spectrogram*8,
            opts.lstm_dim,
            batch_first=True,
            bidirectional=True)

        self.fc1 = nn.Linear(2 * opts.lstm_dim, opts.fc1_dim)
        # self.fc1 = nn.Linear(1024, opts.fc1_dim)
        self.fc2 = nn.Linear(opts.fc1_dim, opts.y_spectrogram*opts.y_image_channel)

    def forward(self, x):
        # B: batch, L: image width, H: image height C: channel, here C = 2, correspond to real and imag number
        # x: [B, C, H, W] [B, 2, 128, 129]
        out = x.transpose(2, 3).contiguous()
        # out: [B, C, W, H]
        out = self.conv(out)
        # out: [B, 8, W, H]
        out = out.transpose(1, 2).contiguous()
        # out: [B, W, 8, H]
        out = out.view(out.size(0), out.size(1), -1)
        # out: [B, W, 8*H]

        out, _ = self.lstm(out)  # [B, W, 2*lstm_dim]
        out = F.relu(out)

        out = self.fc1(out)  # out: [B, W, fc1_dim]
        out = F.relu(out)
        out = self.fc2(out)  # out: [B, W, 2*H] , fc2_dim == H
        out = out.view(out.size(0), out.size(1), self.opts.y_image_channel, -1)  # [B, W, 2, H]
        out = torch.sigmoid(out)
        out = out.transpose(1, 2).contiguous()
        out = out.transpose(2, 3).contiguous()
        # out: [B, 2, H, W]
        # out: [4, 2, 128, 129]
        #fake_Y_spectrum = images_X_spectrum * mask
        out = out * x
        return out