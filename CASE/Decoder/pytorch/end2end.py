# end2end.py
#
# This is the main training file for the CycleGAN part of the assignment.
#
# Usage:
# ======
#    To train with the default hyper-parameters (saves results to samples_cyclegan/):
#       python cycle_gan.py
#
#    To train with cycle consistency loss (saves results to samples_cyclegan_cycle/):
#       python cycle_gan.py --use_cycle_consistency_loss
#
#
#    For optional experimentation:
#    -----------------------------
#    If you have a powerful computer (ideally with a GPU), then you can obtain better results by
#    increasing the number of filters used in the generator and/or discriminator, as follows:
#      python cycle_gan.py --g_conv_dim=64 --d_conv_dim=64

from __future__ import division
import os
import sys
import warnings

warnings.filterwarnings("ignore")

# Torch imports
import torch
import torch.fft
import torch.nn as nn
import torch.optim as optim

# Numpy & Scipy imports
import numpy as np
import scipy.io

import cv2
# Local imports
from utils import to_var, to_data,spec_to_network_input,network_input_to_spec
from models.model_components import maskCNNModel, classificationHybridModel

SEED = 11

# Set the random seed manually for reproducibility.
np.random.seed(SEED)
torch.manual_seed(SEED)
if torch.cuda.is_available():
    torch.cuda.manual_seed(SEED)


def print_models(Model):
    """Prints model information for the generators and discriminators.
    """
    print("                 Model                ")
    print("---------------------------------------")
    print(Model)
    print("---------------------------------------")


def create_model(opts):
    """Builds the generators and discriminators.
    """

    maskCNN = maskCNNModel(opts)
    # print_models(maskCNN)

    C_XtoY = classificationHybridModel(conv_dim_in=opts.y_image_channel,
                            conv_dim_out=opts.n_classes,
                            # conv_dim_lstm=opts.stft_nfft*opts.scaling_factor)
                            conv_dim_lstm=opts.stft_nfft*4)
    # print_models(C_XtoY)

    if torch.cuda.is_available():
        maskCNN.cuda()
        C_XtoY.cuda()
        print('Models moved to GPU.')

    return maskCNN,C_XtoY


def checkpoint(iteration, mask_CNN, C_XtoY,opts):
    """Saves the parameters of both generators G_YtoX, G_XtoY and discriminators D_X, D_Y.
    """

    mask_CNN_path = os.path.join(opts.checkpoint_dir, str(opts.load_iters+iteration)+ '_maskCNN.pkl')
    torch.save(mask_CNN.state_dict(), mask_CNN_path)

    C_XtoY_path = os.path.join(opts.checkpoint_dir, str(opts.load_iters+iteration)+'_C_XtoY.pkl')
    torch.save(C_XtoY.state_dict(), C_XtoY_path)


def load_checkpoint(opts):
    """Loads the generator and discriminator models from checkpoints.
    """
    maskCNN_path = os.path.join(opts.checkpoint_dir,str(opts.load_iters)+ '_maskCNN.pkl')
    maskCNN = maskCNNModel(opts)

    maskCNN.load_state_dict(torch.load(
        maskCNN_path, map_location=lambda storage, loc: storage),
        strict=False)

    C_XtoY_path = os.path.join(opts.checkpoint_dir,str(opts.load_iters)+ '_C_XtoY.pkl')
    
    C_XtoY = classificationHybridModel(conv_dim_in=opts.x_image_channel,
                            conv_dim_out=opts.n_classes,
                            # conv_dim_lstm=opts.stft_nfft*opts.scaling_factor)
                            conv_dim_lstm=opts.stft_nfft*4)
    
    C_XtoY.load_state_dict(torch.load(
        C_XtoY_path, map_location=lambda storage, loc: storage),
        strict=False)

    if torch.cuda.is_available():
        maskCNN.cuda()
        C_XtoY.cuda()
        print('Models moved to GPU.')

    return maskCNN, C_XtoY


def merge_images(sources, targets, batch_size, image_channel):
    """Creates a grid consisting of pairs of columns, where the first column in
    each pair contains images source images and the second column in each pair
    contains images generated by the CycleGAN from the corresponding images in
    the first column.
    """
    _, _, h, w = sources.shape
    row = int(np.sqrt(batch_size))
    column = int(batch_size / row)
    merged = np.zeros([image_channel, row * h, column * w * 2])
    for idx, (s, t) in enumerate(zip(sources, targets)):
        i = idx // column
        j = idx % column
        merged[:, i * h:(i + 1) * h, (j * 2) * w:(j * 2 + 1) * w] = s
        merged[:, i * h:(i + 1) * h, (j * 2 + 1) * w:(j * 2 + 2) * w] = t
    return merged.transpose(1, 2, 0)


def save_samples(iteration, fixed_Y, fixed_X, mask_CNN, opts):
    """Saves samples from both generators X->Y and Y->X.
    """
    fake_Y = mask_CNN(fixed_X)

    Y, fake_Y = to_data(fixed_Y), to_data(fake_Y)

    merged = merge_images(Y, fake_Y, opts.batch_size, opts.y_image_channel)

    path = os.path.join(opts.sample_dir,
                        'sample-{:06d}-Y.png'.format(iteration))
    merged = np.abs(merged[:, :, 0] + 1j * merged[:, :, 1])
    merged = (merged - np.amin(merged)) / (np.amax(merged) - np.amin(merged)) * 255
    merged = cv2.flip(merged, 0)
    cv2.imwrite(path, merged)
    print('Saved {}'.format(path))


def save_samples_separate(iteration, fixed_Y, fixed_X, mask_CNN, opts,
                          name_X_test, labels_Y_test,saved_dir):
    """Saves samples from both generators X->Y and Y->X.
    """
    fake_Y = mask_CNN(fixed_X)

    fixed_Y, fake_Y,fixed_X = to_data(fixed_Y), to_data(fake_Y), to_data(fixed_X)

    for batch_index in range(opts.batch_size):
        try:
            path_src = os.path.join(saved_dir,name_X_test[batch_index])
            groundtruth_image = (
                np.squeeze(fixed_Y[batch_index, :, :, :]).transpose(1, 2, 0))

            groundtruth_image = np.abs(groundtruth_image[:, :, 0] + 1j * groundtruth_image[:, :, 1])
            groundtruth_image = (groundtruth_image - np.amin(groundtruth_image)) / (np.amax(groundtruth_image) - np.amin(groundtruth_image)) * 255
            groundtruth_image = cv2.flip(groundtruth_image, 0)
            cv2.imwrite(path_src + '_groundtruth_'+str(iteration)+'.png', groundtruth_image)

            fake_image = (
                np.squeeze(fake_Y[batch_index, :, :, :]).transpose(1, 2, 0))
            fake_image = np.abs(fake_image[:, :, 0] + 1j * fake_image[:, :, 1])
            fake_image = (fake_image - np.amin(fake_image)) / (np.amax(fake_image) - np.amin(fake_image)) * 255
            fake_image = cv2.flip(fake_image, 0)
            cv2.imwrite(path_src + '_fake_'+str(iteration)+'.png', fake_image)

            raw_image = (
                np.squeeze(fixed_X[batch_index, :, :, :]).transpose(1, 2, 0))
            raw_image = np.abs(raw_image[:, :, 0] + 1j * raw_image[:, :, 1])
            raw_image = (raw_image - np.amin(raw_image)) / (np.amax(raw_image) - np.amin(raw_image)) * 255
            raw_image = cv2.flip(raw_image, 0)
            cv2.imwrite(path_src + '_raw_'+str(iteration)+'.png', raw_image)
        except:
            e = sys.exc_info()[1]
            print(e)
    # print('Saved {}'.format(path))


def training_loop(training_dataloader_X, training_dataloader_Y, testing_dataloader_X,
                  testing_dataloader_Y, opts):
    """Runs the training loop.
        * Saves checkpoint every opts.checkpoint_every iterations
        * Saves generated samples every opts.sample_every iterations
    """
    loss_spec = torch.nn.MSELoss(reduction='mean')
    loss_class = nn.CrossEntropyLoss()
    # code_word_fft,'_',code_word_label,'_',SNR,'_',SF,'_',BW,'_',instance,'.mat'
    output_label_index=3
    output_label_offset=min(opts.sf_list)
    instance_label_index=5
    snr_label_index=2
    if opts.load:
        mask_CNN,C_XtoY = load_checkpoint(opts)
    else:
        mask_CNN,C_XtoY = create_model(opts)

    # Create optimizers
    g_params = list(mask_CNN.parameters()) + list(C_XtoY.parameters())
    g_optimizer = optim.Adam(g_params, opts.lr, [opts.beta1, opts.beta2])

    iter_X = iter(training_dataloader_X)
    iter_Y = iter(training_dataloader_Y)

    test_iter_X = iter(testing_dataloader_X)
    test_iter_Y = iter(testing_dataloader_Y)

    # Get some fixed data from domains X and Y for sampling. These are images that are held
    # constant throughout training, that allow us to inspect the model's performance.
    #fixed_X, name_X_fixed = test_iter_X.next()
    fixed_X, name_X_fixed = next(test_iter_X)
    fixed_X = to_var(fixed_X)

    #fixed_Y, name_Y_fixed = test_iter_Y.next()
    fixed_Y, name_Y_fixed = next(test_iter_Y)
    fixed_Y = to_var(fixed_Y)

    fixed_X_spectrum_raw = torch.stft(input=fixed_X, n_fft=opts.stft_nfft, hop_length=opts.stft_overlap,
                                  win_length=opts.stft_window,pad_mode='constant')
    fixed_X_spectrum = spec_to_network_input(fixed_X_spectrum_raw,opts)
    print("Fixed {}".format(fixed_X_spectrum.shape))

    fixed_Y_spectrum_raw = torch.stft(input=fixed_Y, n_fft=opts.stft_nfft, hop_length=opts.stft_overlap,
                                  win_length=opts.stft_window,pad_mode='constant')
    fixed_Y_spectrum = spec_to_network_input(fixed_Y_spectrum_raw,opts)

    iter_per_epoch = min(len(iter_X), len(iter_Y))

    for iteration in range(1, opts.train_iters + 1):
        # print('Iteration [{:5d}'.format(iteration))
        # Reset data_iter for each epoch
        if iteration % iter_per_epoch == 0:
            iter_X = iter(training_dataloader_X)
            iter_Y = iter(training_dataloader_Y)

        #images_X, name_X = iter_X.next()
        images_X, name_X = next(iter_X)
        labels_X_mapping = list(
            map(lambda x: int(x.split('_')[output_label_index]), name_X))
        images_X, labels_X = to_var(images_X), to_var(
            torch.tensor(labels_X_mapping))

        #images_Y, name_Y = iter_Y.next()
        images_Y, name_Y = next(iter_Y)
        labels_Y_mapping = list(
            map(lambda x: int(x.split('_')[output_label_index]), name_Y))
        images_Y, labels_Y = to_var(images_Y), to_var(
            torch.tensor(labels_Y_mapping))

        # ============================================
        #            PRE_PRECESSING
        # ============================================
        images_X_spectrum_raw = torch.stft(input=images_X, n_fft=opts.stft_nfft, hop_length=opts.stft_overlap,
                                           win_length=opts.stft_window,pad_mode='constant');
        images_X_spectrum = spec_to_network_input(images_X_spectrum_raw,opts)

        images_Y_spectrum_raw = torch.stft(input=images_Y, n_fft=opts.stft_nfft, hop_length=opts.stft_overlap,
                                           win_length=opts.stft_window,pad_mode='constant');
        
        images_Y_spectrum = spec_to_network_input(images_Y_spectrum_raw,opts)
        
        #########################################
        ##    TRAIN THE NETWORK               ##
        #########################################

        # 1. Noise reducer by masking
        fake_Y_spectrum = mask_CNN(images_X_spectrum)
        g_y_pix_loss = loss_spec(fake_Y_spectrum, images_Y_spectrum)

        # 2. LoRa Decoding by classification
        labels_X_estimated=C_XtoY(fake_Y_spectrum)
        g_y_class_loss=loss_class(labels_X_estimated,labels_X-output_label_offset)

        g_optimizer.zero_grad()
        G_Image_loss = opts.scaling_for_imaging_loss * g_y_pix_loss
        G_Class_loss = opts.scaling_for_classification_loss*g_y_class_loss
        G_Y_loss = G_Image_loss+G_Class_loss
        G_Y_loss.backward()
        g_optimizer.step()

        # Print the log info
        if iteration % opts.log_step == 0:
            print(
                'Iteration [{:5d}/{:5d}] | G_Y_loss: {:6.4f}| G_Image_loss: {:6.4f}| G_Class_loss: {:6.4f}'
                    .format(iteration, opts.train_iters,
                            G_Y_loss.item(),
                            G_Image_loss.item(),
                            G_Class_loss.item()))

        # Save the generated samples
        if (iteration % opts.sample_every == 0) and (not opts.server):
            # save_samples(iteration, fixed_Y_spectrum, fixed_X_spectrum, mask_CNN, opts)
            save_samples_separate(iteration, fixed_Y_spectrum, fixed_X_spectrum,
                              mask_CNN, opts, name_X_fixed, name_Y_fixed,opts.sample_dir)
        # Save the model parameters
        if iteration % opts.checkpoint_every == 0:
            checkpoint(iteration, mask_CNN, C_XtoY,opts)

    test_iter_X = iter(testing_dataloader_X)
    test_iter_Y = iter(testing_dataloader_Y)
    iter_per_epoch_test = min(len(test_iter_X), len(test_iter_Y))

    error_matrix = np.zeros([len(opts.snr_list), 1], dtype=float)
    error_matrix_count = np.zeros([len(opts.snr_list), 1], dtype=int)
    error_matrix_info = []
    # spectrum_diff = np.zeros([len(opts.snr_list),fixed_X_spectrum.shape[2],fixed_X_spectrum.shape[3]], dtype=float)
    instance_counter=1

    for iteration in range(iter_per_epoch_test):
        #images_X_test, name_X_test = test_iter_X.next()
        images_X_test, name_X_test = next(test_iter_X)
        ## True code
        snr_X_test_mapping = list(
            map(lambda x: int(x.split('_')[snr_label_index]), name_X_test))

        instance_X_test_mapping = list(
            map(lambda x: int(x.split('_')[instance_label_index]), name_X_test))
        ## True label
        labels_X_test_mapping = list(
            map(lambda x: int(x.split('_')[output_label_index]), name_X_test))


        images_X_test, labels_X_test = to_var(images_X_test), to_var(
            torch.tensor(labels_X_test_mapping))

        #images_Y_test, labels_Y_test = test_iter_Y.next()
        images_Y_test, labels_Y_test = next(test_iter_Y)
        images_Y_test = to_var(images_Y_test)


        images_X_test_spectrum_raw = torch.stft(input=images_X_test, n_fft=opts.stft_nfft,
                                            hop_length=opts.stft_overlap, win_length=opts.stft_window,pad_mode='constant');
        images_X_test_spectrum = spec_to_network_input(images_X_test_spectrum_raw,opts)

        images_Y_test_spectrum_raw = torch.stft(input=images_Y_test, n_fft=opts.stft_nfft,
                                            hop_length=opts.stft_overlap, win_length=opts.stft_window,pad_mode='constant');
        images_Y_test_spectrum = spec_to_network_input(images_Y_test_spectrum_raw,opts)

        if (not opts.server) and (opts.save_demo) and (iteration % opts.sample_every == 0):
            save_samples_separate(iteration, images_Y_test_spectrum, images_X_test_spectrum, mask_CNN, opts, name_X_test, labels_Y_test,opts.testing_dir)

        fake_Y_test_spectrum = mask_CNN(images_X_test_spectrum)

        labels_X_estimated = C_XtoY(fake_Y_test_spectrum)
        _, labels_X_test_estimated=torch.max(labels_X_estimated,1)
        test_right_case = (labels_X_test_estimated == labels_X_test-output_label_offset)
        
        # spectrum_diff_groundtruth=network_input_to_spec(images_Y_test_spectrum)
        # spectrum_diff_denoised=network_input_to_spec(fake_Y_test_spectrum)
        for batch_index in range(opts.batch_size):
            try:
                snr_index = opts.snr_list.index(snr_X_test_mapping[batch_index])
                error_matrix[snr_index] += test_right_case[batch_index].cpu().data.numpy()
                error_matrix_count[snr_index] += 1
                error_matrix_info.append([instance_X_test_mapping[batch_index],snr_X_test_mapping[batch_index],labels_X_test_estimated[batch_index].cpu().data.int(),labels_X_test[batch_index].cpu().data.int()])
                
                # spectrum_diff_groundtruth_one=spectrum_diff_groundtruth[batch_index,:,:].cpu().data.numpy()
                # spectrum_diff_denoised_one=spectrum_diff_denoised[batch_index,:,:].cpu().data.numpy()
                # spectrum_diff[snr_index,:,:]+=np.abs(spectrum_diff_groundtruth_one-spectrum_diff_denoised_one)
                instance_counter+=1
            except:
                e = sys.exc_info()[1]
                print(e)
        if iteration % opts.log_step == 0:
            print('Testing Iteration [{:5d}/{:5d}]'
                  .format(iteration, iter_per_epoch_test))
    error_matrix = np.divide(error_matrix, error_matrix_count)
    error_matrix_info=np.array(error_matrix_info)
    # spectrum_diff=np.divide(spectrum_diff, instance_counter)
    
    # scipy.io.savemat(opts.root_path + '/crossposition_node_'+str(opts.node_list[0]) +'_10k_'+  opts.dir_comment_result+'.mat',
    scipy.io.savemat(opts.root_path + '/simu_' + opts.dir_comment_result+ '_'+str(opts.load_iters)+'.mat',
        dict(error_matrix=error_matrix,
        error_matrix_count=error_matrix_count,
        # spectrum_diff=spectrum_diff,
        error_matrix_info=error_matrix_info,
        snr_list=opts.snr_list))