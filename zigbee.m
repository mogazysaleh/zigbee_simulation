%% parameters
fc1 = 915; % carrier frequency for the first band of operation
fc2 = 2450; % carrier frequency for the second band of operation
img_path = "cameraman.tif";
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


%rayleigh channel
rayleighchan = comm.RayleighChannel(...
                "SampleRate", fc2, ...
                'PathDelays', [0 1e-20], ...
                'AveragePathGains', [4 6], ...
                'NormalizePathGains', true, ...
                'MaximumDopplerShift', 0.01, ...
                'RandomStream', 'mt19937ar with seed', ...
                'Seed', 22, ...
                'PathGainsOutputPort', false);

rayleighchan.ChannelFiltering=true;
rx_BPSK_rey = rayleighchan(tx_BPSK);
rx_QPSK_rey = rayleighchan(tx_QPSK);

%rician channel
ricianchan = comm.RicianChannel(...
                "SampleRate", fc2, ...
                'PathDelays', [0 1e-3], ...
                'AveragePathGains', [2 1], ...
                'MaximumDopplerShift', 0.01, ...
                'PathGainsOutputPort', false);

ricianchan.ChannelFiltering=true;
rx_BPSK_rice = ricianchan(tx_BPSK);
rx_QPSK_rice = ricianchan(tx_QPSK);

%% Receivers

% BPSK receiver
scatterplot(rx_BPSK)
title('Received noisy BPSK symbols')
bits_img_BPSK = pskdemod(rx_BPSK, 2, OutputType='bit');

scatterplot(rx_BPSK_rey)
title('Received noisy reyleigh BPSK symbols')
bits_img_BPSK_rey=pskdemod(rx_BPSK_rey, 2, OutputType='bit');

scatterplot(rx_BPSK_rice)
title('Received noisy rician BPSK symbols')
bits_img_BPSK_rice=pskdemod(rx_BPSK_rice, 2, OutputType='bit');

% QPSK receiver
scatterplot(rx_QPSK)
title('Received noisy QPSK symbols')
bits_img_QPSK = pskdemod(rx_QPSK, 4, OutputType='bit');

scatterplot(rx_QPSK_rey)
title('Received noisy reyleigh QPSK symbols')
bits_img_QPSK_rey=pskdemod(rx_QPSK_rey, 4, OutputType='bit');

scatterplot(rx_QPSK_rice)
title('Received noisy rician QPSK symbols')
bits_img_QPSK_rice=pskdemod(rx_QPSK_rice, 4, OutputType='bit');

%% Save data

img_BPSK = save_image(bits_img_BPSK, img_size, 'output_bpsk.jpg');
img_BPSK_rey = save_image(bits_img_BPSK_rey, img_size, 'output_bpsk_rey.jpg');
img_BPSK_rice = save_image(bits_img_BPSK_rice, img_size, 'output_bpsk_rice.jpg');

img_QPSK = save_image(bits_img_QPSK, img_size, 'output_qpsk.jpg');
img_QPSK_rey = save_image(bits_img_QPSK_rey, img_size,'output_qpsk_rey.jpg');
img_QPSK_rice = save_image(bits_img_QPSK_rice, img_size,'output_qpsk_rice.jpg');

%% Graph BER vs. SNR

SNR = -10:0.01:50;
BER_BPSK = [];
BER_QPSK = [];

for i = 1:length(SNR)

    % pass through channel
    rx_BPSK = awgn(tx_BPSK, SNR(i));
    rx_QPSK = awgn(tx_QPSK, SNR(i));

    % demodulate
    data_BPSK = pskdemod(rx_BPSK, 2);
    data_QPSK = pskdemod(rx_QPSK, 4, OutputType='bit');

    % calculate BER
    [x, ber_BPSK] = symerr(bits_img, data_BPSK);
    [x, ber_QPSK] = symerr(bits_img, data_QPSK);

    % append to BER arrays
    BER_BPSK = [BER_BPSK ber_BPSK];
    BER_QPSK = [BER_QPSK ber_QPSK];
end

% Plot BER vs. SNR of BPSK
figure;

subplot(1, 2, 1);
semilogy(SNR, BER_BPSK)
title('SNR vs. BER of BPSK (Simulated)');
xlabel('SNR (dB)')
ylabel('BER')

subplot(1, 2, 2);
semilogy(SNR, 0.5 * erfc(sqrt(10.^(SNR / 10))));
title('SNR vs. BER of BPSK (Theoretical)');
xlabel('SNR (dB)')
ylabel('BER')


% Plot BER vs. SNR of QPSK
figure;

subplot(1, 2, 1);
semilogy(SNR, BER_QPSK)
title('SNR vs. BER of QPSK (Simualted)')
xlabel('SNR (dB)')
ylabel('BER')


subplot(1, 2, 2);
semilogy(SNR, 0.5 * erfc(sqrt(10.^(SNR / 10))));
title('SNR vs. BER of QPSK (Theoretical)')
xlabel('SNR (dB)')
ylabel('BER')

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



