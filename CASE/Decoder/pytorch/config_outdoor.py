import argparse
import numpy as np

def create_parser():
    """Creates a parser for command-line arguments.
    """
    parser = argparse.ArgumentParser()

    # Model hyper-parameters
    parser.add_argument('--free_gpu_id',
                        type=int,
                        default=3,
                        help='The selected gpu.')

    parser.add_argument('--x_image_channel', type=int, default=2)
    parser.add_argument('--y_image_channel', type=int, default=2)
    parser.add_argument('--conv_kernel_size', type=int, default=3)
    parser.add_argument('--conv_padding_size', type=int, default=1)
    parser.add_argument('--lstm_dim', type=int, default=400)  # For mask_CNN model
    parser.add_argument('--fc1_dim', type=int, default=600)  # For mask_CNN model

    parser.add_argument('--sf',
                        type=int,
                        default=12,
                        help='The spreading factor.')
    parser.add_argument('--bw',
                        type=int,
                        default=125000,
                        help='The bandwidth.')
    parser.add_argument('--fs',
                        type=int,
                        default=1000000,
                        help='The sampling rate.')

    parser.add_argument(
        '--server',
        action='store_true',
        default=True,
        help='Choose whether to include the cycle consistency term in the loss.'
    )
    parser.add_argument(
        '--save_demo',
        action='store_true',
        default=False,
        help='Choose whether to include the cycle consistency term in the loss.'
    )

    parser.add_argument(
        '--normalization',
        action='store_true',
        default=True,
        help='Choose whether to include the cycle consistency term in the loss.'
    )
    
    parser.add_argument(
        '--init_zero_weights',
        action='store_true',
        default=False,
        help=
        'Choose whether to initialize the generator conv weights to 0 (implements the identity function).'
    )

    # Training hyper-parameters
    parser.add_argument(
        '--train_iters',
        type=int,
        default=0,
        help=
        'The number of training iterations to run (you can Ctrl-C out earlier if you want).'
    )
    parser.add_argument(
        '--load_iters',
        type=int,
        default=100000,
        help=
        'The number of training iterations to run (you can Ctrl-C out earlier if you want).'
    )
    parser.add_argument('--batch_size',
                        type=int,
                        default=16,
                        help='The number of images in a batch.')

    parser.add_argument(
        '--num_workers',
        type=int,
        default=1,
        help='The number of threads to use for the DataLoader.')
    parser.add_argument('--lr',
                        type=float,
                        default=0.0002,
                        help='The learning rate (default 0.0003)')
    parser.add_argument('--sorting_type',
                        type=int,
                        default=5,
                        choices=[5,8],
                        help='The index for the selected domain.')
    parser.add_argument('--scaling_for_imaging_loss',
                        type=int,
                        default=64,
                        help='The scaling factor for the imaging loss')
    parser.add_argument('--scaling_for_classification_loss',
                        type=int,
                        default=1,
                        help='The scaling factor for the classification loss')
    parser.add_argument('--scaling_for_contrastive_loss',
                        type=int,
                        default=0,
                        help='The scaling factor for the contrastive loss')
    parser.add_argument('--y_spectrogram',
                        type=int,
                        default=64,
                        help='The number of images in a batch.')
    parser.add_argument('--scaling_factor',
                        type=int,
                        default=4,
                        help='The number of images in a batch.')
    parser.add_argument('--coding_config',
                        type=int,
                        default=3,
                        help='The number of images in a batch.')
    parser.add_argument('--min_snr',
                        type=int,
                        default=-40,
                        help='The number of images in a batch.')
    parser.add_argument('--beta1', type=float, default=0.5)
    parser.add_argument('--beta2', type=float, default=0.999)

    # Data sources
    parser.add_argument(
        '--root_path',
        type=str,
        # default='/srv/node/sdb1/lcn/mobisys2021/benchmark/',
        default='D:\\mobicom2021_server',
        help='Choose the root path to the dataset.')
    parser.add_argument('--evaluations_dir',
                        type=str,
                        default='evaluations',
                        help='Choose the root path to rf signals.')
    parser.add_argument('--data_dir',
                        type=str,
                        default='lora_outdoor_new',
                        help='Choose the root path to rf signals.',
                        choices=['simu_config','phase_indoor_config','indoor_cross_domain','lora_outdoor','lora_outdoor_trace','lora_outdoor_new'])

    parser.add_argument('--network', type=str, default='end2end_outdoor',choices=['end2end','end2end_contrastive','end2end_outdoor'])

    parser.add_argument('--feature_name',
                        type=str,
                        default='chirp',
                        choices=['chirp'])
    parser.add_argument('--groundtruth_code',
                        type=str,
                        default='-27',
                        choices=['35','-27'])
    # data_domain,'_',SNR,'_',SF,'_',BW,'_',instance,'_',code_word_fft,'_',code_word_label,'_',timestamp_index,'.mat'
    parser.add_argument(
        "--position_list",
        nargs='+',
        default=list(range(1, 22)),
        # default=[1],
        type=int)
    parser.add_argument(
        "--node_list",
        nargs='+',
        default=list(range(1, 22)),
        # default=[1],
        type=int)
    parser.add_argument("--code_list",
                        nargs='+',
                        # default=[round(i,1) for i in list(np.arange(0.1,128.1,0.1))],
                        default=[0,1,2],
                        type=float)
    # parser.add_argument("--snr_list", nargs='+', default=list(range(-50, 21)), type=int)
    parser.add_argument(
        "--bw_list",
        nargs='+',
        default=[125000],
        # default=[125000,250000,500000],
        type=int)
    parser.add_argument(
        "--sf_list",
        nargs='+',
        # default=[7],
        default=list(range(7, 13)),
        type=int)
    #[snr=-50:21] lora_indoor_platform:43200, instance=[1:101]
    parser.add_argument(
        "--instance_list",
        nargs='+',
        default=list(range(1, 41)),
        type=int)
    parser.add_argument(
        "--packet_list",
        nargs='+',
        default=list(range(1, 51)),
        type=int)
    parser.add_argument(
        '--ratio_bt_train_and_test',
        type=float,
        default=0,
        help='The ratio between the train and the test dataset')

    # Saving directories and checkpoint/sample iterations
    parser.add_argument('--checkpoint_dir',
                        type=str,
                        default='checkpoints')
    parser.add_argument('--dir_comment', type=str, default='bit2')
    parser.add_argument('--sample_dir', type=str, default='samples')
    parser.add_argument('--testing_dir', type=str, default='testing')
    parser.add_argument('--load', type=str, default='pre_trained')
    # parser.add_argument('--load', type=str, default=None)
    parser.add_argument('--log_step', type=int, default=200)
    parser.add_argument('--sample_every', type=int, default=20000)
    parser.add_argument('--checkpoint_every', type=int, default=5000)

    return parser