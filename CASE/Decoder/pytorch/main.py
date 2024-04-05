"""Main script for project."""
from __future__ import print_function
from utils import generate_dataset, create_dir, set_gpu, print_opts
import config
import datasets.data_loader as data_loader
import end2end,end2end_contrastive,end2end_outdoor

import os
import sys
from datetime import datetime


def main(opts):
    """Loads the data, creates checkpoint and sample directories, and starts the training loop.
    """
    [files_train, files_test
     ] = generate_dataset(opts.root_path, opts.data_dir, opts.ratio_bt_train_and_test,
                          opts.position_list,opts.node_list, opts.code_list, opts.snr_list, opts.bw_list, opts.sf_list,
                          opts.instance_list, opts.sorting_type, opts.packet_list)
    # Create train and test dataloaders for images from the two domains X and Y

    training_dataloader_X, testing_dataloader_X = data_loader.lora_loader(
        opts, files_train, files_test, False)
    training_dataloader_Y, testing_dataloader_Y = data_loader.lora_loader(
        opts, files_train, files_test, True)

    # Create checkpoint and sample directories
    create_dir(opts.checkpoint_dir)
    if not opts.server:
        create_dir(opts.sample_dir)
        create_dir(opts.testing_dir)

    # Start training
    # set_gpu(opts.free_gpu_id)

    # select the model

    if  opts.network == 'end2end':
        end2end.training_loop(training_dataloader_X, training_dataloader_Y, testing_dataloader_X,
                               testing_dataloader_Y, opts)
    if  opts.network == 'end2end_contrastive':
        end2end_contrastive.training_loop(training_dataloader_X, training_dataloader_Y, testing_dataloader_X,
                               testing_dataloader_Y, opts)
    if  opts.network == 'end2end_outdoor':
        end2end_outdoor.training_loop(training_dataloader_X, training_dataloader_Y, testing_dataloader_X,
                               testing_dataloader_Y, opts)
if __name__ == "__main__":
    # parse arguments

    parser = config.create_parser()
    opts = parser.parse_args()
    if opts.server:
        opts.root_path='/mnt/home/renyidon/data/mobicom2021_server'
    if opts.coding_config==1:
        opts.sf_list=list(range(7, 11))
        opts.scaling_factor=16
    elif opts.coding_config==2:
        opts.sf_list=list(range(8, 12))
        opts.scaling_factor=8
    elif opts.coding_config==3:
        opts.sf_list=list(range(9, 13))
        opts.scaling_factor=4


    opts.sampling_ratio=opts.fs // opts.bw
    opts.n_classes = len(opts.sf_list)
    opts.stft_nfft =   opts.y_spectrogram*opts.sampling_ratio

    opts.stft_window=2048//opts.scaling_factor
    opts.stft_overlap=1024//opts.scaling_factor
    opts.symbol_length=(2**17)//opts.scaling_factor
    # opts.symbol_length=2**15

    opts.snr_list=list(range(opts.min_snr,-10))

    opts.dir_comment = opts.dir_comment + "_" + str(opts.coding_config)+"_" + str(opts.y_spectrogram)+ "_" + str(opts.scaling_factor)+ "_" + str(opts.scaling_for_imaging_loss) + "_" + str(opts.scaling_for_classification_loss)+ "_" + str(opts.scaling_for_contrastive_loss)

    
    print("dir comment is {}".format(opts.dir_comment))
    opts.evaluations_path=os.path.join(opts.root_path,opts.evaluations_dir)

    opts.sample_dir = os.path.join(opts.evaluations_path, opts.dir_comment + "_" + opts.sample_dir)

    opts.checkpoint_dir = os.path.join(opts.evaluations_path, opts.dir_comment + "_" + opts.checkpoint_dir)

    opts.testing_dir = os.path.join(opts.evaluations_path, opts.dir_comment + "_" + opts.testing_dir)

    opts.dir_comment_result=opts.dir_comment
    if opts.load:
        opts.sample_dir += ("_" +opts.load)
        opts.testing_dir += ("_" +opts.load)
        opts.dir_comment_result += ("_" +opts.load)

    print_opts(opts)

    main(opts)
