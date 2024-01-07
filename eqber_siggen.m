%% EQBER_SIGGEN - Generate a noisy, channel-filtered signal to be equalized
% This script generates a noisy, channel-filtered signal to be processed by a
% linear equalizer, a DFE equalizer, and an MLSE equalizer.  The channel state
% information is retained between blocks of signal data.  

%   Copyright 1996-2016 The MathWorks, Inc.


% Generate a PSK signal
msg = randi([0 M-1],nBits,1);
txSig = pskmod(msg, 2);

% Pass the signal through the channel
[filtSig,chanState] = filter(chnl,1,txSig,chanState);

% Add AWGN to the signal
SNR = EbNo(EbNoIdx) + 10*log10(Rb/Fs);
noisySig = awgn(filtSig,SNR,'measured');