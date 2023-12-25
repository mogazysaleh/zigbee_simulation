%% parameters
fc1 = 915; % carrier frequency for the first band of operation
fc2 = 2450; % carrier frequency for the second band of operation
img_path = "input.jpg";
Eb = 1; % energy of a single bit
Tb1 = 1/fc1; % bit duration for the first band of operation (assumed to equal the carrier period)
Tb2 = 1/fc2; % bit duration for the second band of operation (assumed to equal carrier period)
snr_db = 1; % signal to noise ratio expressed in db;

%% Load data

% load image from path
[img, bits_img, img_size] = load_image(img_path);


%% Transmitters

% BPSK transmitter
tx_BPSK = pskmod(bits_img, 2, InputType="bit");
scatterplot(tx_BPSK);
title('Transmitted BPSK symbols')

% QPSK transmitter
tx_QPSK = pskmod(bits_img, 4, InputType="bit");
scatterplot(tx_QPSK)
title('transmitted QPSK symbols')



%% channel

% AWGN channel
rx_BPSK = awgn(tx_BPSK, snr_db);
rx_QPSK = awgn(tx_QPSK, snr_db);


%% Receivers

% BPSK receiver
scatterplot(rx_BPSK)
title('Received noisy BPSK symbols')
bits_img_BPSK = pskdemod(rx_BPSK, 2, OutputType='bit');

% QPSK receiver
scatterplot(rx_QPSK)
title('Received noisy QPSK symbols')
bits_img_QPSK = pskdemod(rx_QPSK, 4, OutputType='bit');



%% Save data

img_BPSK = save_image(bits_img_BPSK, img_size, 'output_bpsk.jpg');
img_QPSK = save_image(bits_img_QPSK, img_size, 'output_qpsk.jpg');



%% user-defined functions

function modulated_bpsk = modulate_bpsk(bits, Eb)
    % bits: bit sream to be modulated
    % Eb: energy of a single bit

    modulated_bpsk = pskmod(bits, 2)*Eb;
end

function img = save_image(bits_img, img_size, img_path)

    % from bit stream to bit characters
    bits_img = char(bits_img + '0');

    % convert the image from a stream of bits into matrix form
    img = reshape(bin2dec(reshape(bits_img, [], 8)), img_size(1), img_size(2));

    % convert pixel values to uint8
    img = uint8(img);

    % save image
    imwrite(img, img_path);

end

function [img, bits_img, img_size] = load_image(img_path)
    
    % read image from path
    img = imread(img_path);

    % turn the image into greyscale, if it is not in grey scale
    if length(size(img)) > 2
        img = rgb2gray(img);
    end

    % store image size
    img_size = size(img);

    % represent the image as a stream of bit characters
    bits_img = reshape(dec2bin(img), [], 1);

    % Convert the bit characters into bit stream
    bits_img = bits_img - '0';

end



