
%% EQBER_ADAPTIVE - Simulation of linear and DFE equalizers
% This script runs a simulation loop for either a linear or a DFE equalizer.  It
% uses the RLS algorithm to initially set the weights, then uses LMS thereafter
% to minimize execution time.  It plots the equalized signal spectrum, then
% generates and plots BER results over a range of Eb/No values. It also fits a
% curve to the simulated BER points, and plots the burst error performance of
% the linear and DFE equalizers. The adaptive equalizer objects automatically
% retain their state between invocations of their "equalize" method.
%
% This script uses another script, <eqber_siggen.html eqber_siggen> to
% generate a noisy, channel-filtered signal.

%   Copyright 1996-2004 The MathWorks, Inc.


% Set parameters based on linear or DFE equalizer setting
if (strcmpi(eqType, 'linear'))
    refTap    = linEq.ReferenceTap; % set reference tap
    eq        = linEq;         % set RLS equalizer for first data block
    hSpecPlot = hLinSpec;      % set spectrum plot line handle
elseif (strcmpi(eqType, 'dfe'))
    refTap    = dfeEq.ReferenceTap;
    eq        = dfeEq;
    hSpecPlot = hDfeSpec;
end

firstErrPlot = true;   % for burst error plot - reset for each eq method

% Main simulation loop
for EbNoIdx = 1 : length(EbNo)
    
    % Initialize channel and error collection parameters 
    chanState = [];
    numErrs   = 0;
    numBits   = 0;
    firstBlk = true;  % RLS for first data block, LMS thereafter
    
    while (numErrs < maxErrs && numBits < maxBits)
        
        eqber_siggen;  % generate a noisy, channel-filtered signal
        
        if (numErrs < maxErrs)
            
            % Equalize the signal with an adaptive equalizer.  Use a
            % truncated version of the transmitted signal as the training
            % signal.  Train the tap weights only for the first block.
            trainSig = txSig;
            if (firstBlk)
                PreD = eq(noisySig,trainSig,true);
            else
                PreD = eq(noisySig,trainSig,false);

                % Plot the spectrum of the equalized signal
                hSpecPlot = eqber_graphics('sigspec', eqType, hSpecPlot, ...
                  nBits, PreD);
                
                % Demodulate the signal
                demodSig = (1-sign(real(PreD)))/2;
                
                range1 = 1 : length(msg)-refTap+1;
                range2 = refTap : length(demodSig);
                [currErrs, ratio] = biterr(msg(range1), demodSig(range2));
                numErrs = numErrs + currErrs;       % cumulative
                numBits = numBits + length(range1); % cumulative
                BER(EbNoIdx) = numErrs / numBits;
                
                % Plot the burst error performance for this data block
                [hErrs, hText1, hText2] = eqber_graphics('bursterrors', eqType, ...
                  mlseType, firstErrPlot, msg(range1), demodSig(range2), ...
                  nBits, hErrs, hText1, hText2);
                firstErrPlot = false;
            end
        end
                
        % Update the BER plot
        [hBER, hLegend, legendString] = eqber_graphics('simber', eqType, ...
            mlseType, firstBlk, EbNoIdx, EbNo, BER, hBER, hLegend, ...
            legendString);
        firstBlk = false;  % done processing first data block
        
    end     % end of simulation while loop
    
    % Fit a plot to the new BER points
    hFit = eqber_graphics('fitber', eqType, mlseType, hFit, EbNoIdx, EbNo, BER);
    
    % Reset the RLS equalizer for the next Eb/No. 
    release(eq)
end     % end of 'for EbNoIdx' loop