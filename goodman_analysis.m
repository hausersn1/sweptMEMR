% %% analyze MEMR --------------------------------------------------------
% stabilityCheck = 0;
% MEMR_mem = runme(Clicks,nClicks,indx,time,fs,stabilityCheck);
% % analyze ear canal stability
% stabilityCheck = 1; % inc stands for incident
% MEMR_inc = runme(Clicks,nClicks,indx,time,fs,stabilityCheck);
%
% MEMR_mem.elicitor = elicitor;
% MEMR_inc.elicitor = elicitor;
% MEMR_mem.RMS = RMS; % rms of the elicitor Pa
% MEMR_mem.RMSC = RMSC; % rms of the click Pa
% MEMR_mem.RMST = RMST; % rms time vector Pa
% MEMR_mem.pSPL = pSPL; % click peak in pSPL
% MEMR_mem.rmsSPL = rmsSPL; % click rms in SPL
%
%
% % ----------- functions -------------- %
% function [MEMR] = runme(Clicks,nClicks,indx,time,fs,stabilityCheck)
% timeChunk = zeros(1,nClicks);
% for jj=1:nClicks % loop across each click position in the sweep
%     timeChunk(1,jj) = time(indx(jj)); % the temporal postion of each click position
% end
% timeChunk = timeChunk * 8; % this gives the correct 50 ms interval between clicks
% % time went from 0 to 1, but actually, the length is 8 seconds
% nSweeps = size(Clicks,2); % number of sweeps
%
% % Window all clicks and save into a matrix C --------------------------
% % round trip travel time between ear canal probe and eardrum:
% % depends on depth of insertion, but probably 1.5-2.5 cm
% % assume speed of sound is 34400 cm/s
% % round((1/((34400/1.5)))*fs)*2
% % 8-12 samples
% winN = 14; % number of samples to reduce (before reflection comes back)
% if stabilityCheck == 1 % this is for incident part of the click -----
%     clickN = winN*2+1; % number of analysis samples in each (windowed click)
%     h = hann(clickN); % make a hann window to window the edges
%     H = repmat(h,1,nSweeps);
%     C = zeros(clickN,nSweeps,nClicks); % initialize matrix of windowed clicks (C for clicks)
%     Cn = zeros(clickN,nSweeps,nClicks); % initialize noise matrix
%     for ii=1:nClicks % loop across each click position (1-160)
%         q = Clicks(indx(ii)-winN:indx(ii)+winN,:);
%         q = q .* H;
%         C(:,:,ii) = q;
%
%         qn = Clicks(indx(ii)+1000-winN:indx(ii)+1000+winN,:); % window for noise estimate
%         Cn(:,:,ii) = qn; % matrix of clicks
%     end
% else % this is for the reflected (MEMR) part of the click -----------
%     clickN = 100 + winN; % number of analysis samples in each (windowed click)
%     h = hann(winN*2); % make a hann window to window the edges
%     h = h(1:winN);
%     H = repmat(h,1,nSweeps);
%     C = zeros(clickN,nSweeps,nClicks); % initialize matrix of windowed clicks (C for clicks)
%     Cn = zeros(clickN+winN,nSweeps,nClicks);
%     for ii=1:nClicks % loop across each click position (1-160)
%         q = Clicks(indx(ii):indx(ii)+clickN-1,:); % reflected part of the sweep starting 14 samples after incident click
%         qn = Clicks(indx(ii)-winN:indx(ii)+clickN-1,:); % *** include the incident part! ***
%         q(1:winN,:) = q(1:winN,:) .* H;
%         qn(1:winN,:) = qn(1:winN,:) .* H;
%         q = flipud(q);
%         qn = flipud(qn);
%         q(1:winN,:) = q(1:winN,:) .* H;
%         qn(1:winN,:) = qn(1:winN,:) .* H;
%         q = flipud(q);
%         qn = flipud(qn);
%
%         C(:,:,ii) = q; % matrix of clicks
%         Cn(:,:,ii) = qn; % matrix of clicks
%     end
%
% end
%
% fmin = 100; % minimum frequency to analyze (Hz)
% fmax = 4000; % maximym frequency to analyze (Hz)
%
% % Convert clicks into the frequency domain ----------------------------
% nfft = 960; % size of fft--chosen to give 100-Hz bin width
% frequency = (0:1:nfft-1)'*(fs/nfft); % frequency vector
% [~,indx1] = min(abs(fmin-frequency)); % index of minimum frequency
% [~,indx2] = min(abs(fmax-frequency)); % index of maximum frequency
% freq = frequency(indx1:indx2);
% nFreqs = length(freq); % number of frequencies to analyze
% originalN = size(squeeze(C(:,1,:)),1);
% scale = originalN / 2;
%
% CFT = zeros(nFreqs,nSweeps,nClicks); % initialize matrix of Fourier transformed clicks
% CFTn = zeros(nFreqs,nSweeps,nClicks); % initialize noise matrix
% TREND = zeros(nFreqs,nSweeps,nClicks); % initialize saved matrix of trend line
% TRENDn = zeros(nFreqs,nSweeps,nClicks);
% W = zeros(nFreqs,nSweeps,nClicks); % initialize weighting matrix (downweight bad samples)
% Wn = zeros(nFreqs,nSweeps,nClicks);
%
% warning off
% for ii=1:nSweeps % loop across 15 sweeps
%     % for signal
%     cc = squeeze(C(:,ii,:));
%
%     FT = fft(cc,nfft); % contains all sweeps at all frequencies for a given click position
%     FT = FT(indx1:indx2,:); % keep only the frequencies of interest
%     FT = FT ./ scale; % scale the magnitude appropriately
%     CFT(:,ii,:) = complex(FT); % Fourier transform of C, cut to frequencies of interest
%
%     % for noise
%     ccn = squeeze(Cn(:,ii,:));
%     FT = fft(ccn,nfft); % contains all sweeps at all frequencies for a given click position
%     FT = FT(indx1:indx2,:); % keep only the frequencies of interest
%     CFTn(:,ii,:) = complex(FT); % Fourier transform of C, cut to frequenc6ies of interest
% end
%
% if stabilityCheck ~=5 % this is hack to make this always happen
%     % find long-term ipsilateral trends and extract them ---------
%     [CFT,TREND,W] = memrDetrend(CFT);
%     [CFTn,TRENDn,Wn] = memrDetrend(CFTn);
%     for jj=1:nFreqs
%         dummy = squeeze(TREND(jj,:,:));
%         dummy = dummy.';
%         dummy = dummy(:);
%         dummy = dummy ./ dummy(1);
%         dummy = abs(dummy - 1) + 1;
%         %dummy = 20*log10(dummy);
%         Trend(:,jj) = dummy;
%
%         dummy = squeeze(TRENDn(jj,:,:));
%         dummy = dummy.';
%         dummy = dummy(:);
%         dummy = dummy ./ dummy(1);
%         dummy = abs(dummy - 1) + 1;
%         %dummy = 20*log10(dummy);
%         Trendn(:,jj) = dummy;
%     end
%
%     % Magnitude and phase analysis together --------------------------
%     x = (0:1:nClicks-1);
%     Z = zeros(nClicks,nFreqs);
%     Z_sm = zeros(nClicks,nFreqs);
%     % want to begin and end at the same place, so need to make a "knot"
%     % condition at the ends
%     xxx = (1:1:nClicks*3)-nClicks;
%     for jj=1:nFreqs
%         m = squeeze(CFT(jj,:,:)); % size m = 160 x 15
%         w = squeeze(W(jj,:,:));
%         Mr = real(m); % matrix of 15 sweeps at one click
%         Mi = imag(m);
%         sumw = sum(w,1); % take the weighted mean at one click (and one frequency)
%         mr = sum(Mr(:,:).*w,1)./ sumw;
%         mi = sum(Mi(:,:).*w,1)./ sumw;
%         % smooth the response (effectively lowpass filter)
%         mrrr = [mr,mr,mr];
%         miii = [mi,mi,mi];
%         www = [sumw,sumw,sumw];
%         sm = 0.001; % was 0.0001; % was 0.00001;  smoothing factor (smaller numbers are more smooth)
%         ppr = csaps(xxx,mrrr,sm,[],www); % piecewise polynomial real coefficients
%         ppi = csaps(xxx,miii,sm,[],www); % piecewise polynomial imaginary coefficients
%         mr_sm = ppval(ppr,x); % evaluate only at the original x values
%         mi_sm = ppval(ppi,x);
%
%         z = mr + 1i*mi;
%         Z(:,jj) = z; % raw Z
%         z_sm = mr_sm + 1i*mi_sm; % smoothed raw Z
%
%         %figure
%         %plot(z)
%         %hold on
%         %plot(z_sm,'r')
%         %plot(z_sm(end),'r.')
%         %plot(z_sm(1),'r*')
%
%
%         % calculate length of curve -- this is problematic because it
%         % doesn't return to where started. Calculating the tip is also
%         % problematic. Probably don't use.
%         t = x * 0.05; % time vector
%         %             dy = gradient(imag(z_sm)./gradient(t));
%         %             dx = gradient(real(z_sm)./gradient(t));
%         %             d = sqrt(dy.^2 + dx.^2);
%         %             [dmax,dmaxIndx] = max(d);
%         %             k = ones(size(d));
%         %             k(dmaxIndx+1:end) = -1;
%         %             D = cumsum(d.*k);
%
%         baseline = mean([z_sm(1:3),z_sm(end-2:end)]);
%         d = z_sm ./ baseline; % normalize z_sm
%         d1 = abs(d-1)+1; % the combined mag+phase change
%         d2 = abs(abs(d)-1)+1; % magnitude only change
%
%         Z_sm(:,jj) = z_sm;
%         D(:,jj) = d;
%         D1(:,jj) = d1; % use this!
%         D2(:,jj) = d2;
%     end
%
% end
%
% % average over these frequencies:
% lowCutoffHz = 500;
% highCutoffHz = 1500;
% [~,lowIndx] = min(abs(freq -lowCutoffHz));
% [~,highIndx] = min(abs(freq -highCutoffHz));
%
% % rather than a straight average, zero out extreme values
% DD1 = D1(:,lowIndx:highIndx);
% peaks = max(DD1,[],1);
% doPlotAR = 0;
% multiplier = "mild";
% [rejectIndx,nRejects] = AR(peaks,multiplier,doPlotAR);
% ww1 = ones(size(peaks));
% ww1(rejectIndx) = 0;
% d = sum(D(:,lowIndx:highIndx).*ww1,2) / sum(ww1);
% d1 = sum(D1(:,lowIndx:highIndx).*ww1,2) / sum(ww1);
% d2 = sum(D2(:,lowIndx:highIndx).*ww1,2) / sum(ww1);
% if ~isempty(rejectIndx)
%     %keyboard
% end
%
% trend =  sum(Trend(:,lowIndx:highIndx).*ww1,2) / sum(ww1);
% trendn =  sum(Trendn(:,lowIndx:highIndx).*ww1,2) / sum(ww1);
% timeTrend = (0:1:length(trend)-1)' * 0.05;
%
%
% % EXTRACT THE NEEDED METRICS ------------------------------------------
% if stabilityCheck ~= 1
%     % peak delay -------------------
%     sm = 1; % smoothing factor (smaller numbers are more smooth)
%     n = 160; % number of clicks
%     x = linspace(0,8,n)'; % x-axis for smoothing (click number)
%     w = ones(size(x)); % weighting factor
%     pp = csaps(x,d1,sm,[],w); % piecewise polynomial object
%     dfdx = fnder(pp); % take derivative and solve for zero slope
%     peakXX = fnzeros(dfdx); % peak location in seconds
%     peakXX = peakXX(1,:);
%
%     try
%
%         peakYY = ppval(pp,peakXX);
%         [~,peakIndx] = max(peakYY);
%         peakX = peakXX(peakIndx);
%         peakY = peakYY(peakIndx);
%
%         % if isempty(peakN)
%         %     peakN = 1;
%         % end
%         % peakX = peakX(peakN); % function returns two outputs (both the same) take the first
%         % peakY = ppval(pp,peakNf); % max average activation
%         delay = peakX-4; % reflex delay in seconds. Peak of the noise occurred at t=4 seconds
%     catch ME
%         keyboard
%     end
%     %dY = ppval(dfdx,x);
%
%     % thresholds ------------------
%     %   use the Q concept: reduce 12 from peak
%     d1_scaled = (d1-1)./(peakY-1);
%     thd = 10.^(-12/20); % threshold is "Q12", or 12 dB down from peak
%     d1_scaled = d1_scaled - thd;
%     sm = 1; % smoothing factor (smaller numbers are more smooth)
%     pp = csaps(x,d1_scaled,sm,[],w); % piecewise polynomial object
%     z2 = fnzeros(pp);
%     Thd = z2(1,:); % threshold times
%     try
%         ons = Thd(find(Thd<peakX));
%         thdOnsetTime = max(ons);
%         offs = Thd(find(Thd>peakX));
%         thdOffsetTime = min(offs);
%         %thdOnsetTime = Thd(1); % onset threshold
%         %thdOffsetTime = Thd(2); % offset threshold
%     catch ME
%         thdOnsetTime = NaN;
%         thdOffsetTime = NaN;
%     end
%     % convert threshold times to thresholds re: nominal elicitor level
%     % noise went from 45 to 115 in 4 seconds (17.5 dB/s)
%     % y = mx + b
%     % stimLevel = 17.5x + 45
%     % but also account for reflex delay
%     try
%         % issue is whether or not to include delay. Theoretically it
%         % seems right, but practically it causes problems, including
%         % extra noise and issues with occasional negative delays.
%         elicitorLevel = 17.5*x + 40; % convert time in seconds to elicitor level in dB SPL rms
%         elicitorLevel = [elicitorLevel(1:80);flipud(elicitorLevel(1:80))];
%         ThdLvl(1) = 17.5*thdOnsetTime + 40;
%         ThdLvl(2) = -17.5*(thdOffsetTime-4) + 110;
%         thdOnsetLvl = ThdLvl(1); % onset threshold re: stim level
%         thdOffsetLvl = ThdLvl(2); % offset threshold re: stim level
%
%         % if thdOffsetLvl > 95
%         %     keyboard
%         % end
%
%         %ThdLvl(1) = 17.5*(Thd(1)-delay) + 45;
%         %thdOnsetLvl = ThdLvl(1); % onset threshold re: stim level
%         %ThdLvl(2) = -17.5*(Thd(2)-4-delay) + 115;
%         %thdOffsetLvl = ThdLvl(2); % offset threshold re: stim level
%         %elicitorLevel = 17.5*(x-delay) + 45;
%     catch ME
%         ThdLvl(1) = NaN;
%         thdOnsetLvl = NaN; % onset threshold re: stim level
%         ThdLvl(2) = NaN;
%         thdOffsetLvl = NaN; % offset threshold re: stim level
%         %elicitorLevel = 17.5*(x-delay) + 45;
%         elicitorLevel = 17.5*x + 40; % convert time in seconds to elicitor level in dB SPL rms
%         elicitorLevel = [elicitorLevel(1:80);flipud(elicitorLevel(1:80))];
%     end
%     % go back and get threshold amplitudes from non-scaled d1
%     sm = 1; % smoothing factor (smaller numbers are more smooth)
%     n = 160; % number of clicks
%     x = linspace(0,8,n)'; % x-axis for smoothing (click number)
%     w = ones(size(x)); % weighting factor
%     pp = csaps(x,d1,sm,[],w); % piecewise polynomial object
%     thdAmp = ppval(pp,thdOnsetTime);
%
%     % hysteresis ---------------------
%     try
%         pp = csaps(x,d1,sm,[],w); % piecewise polynomial object
%         hh = fnint(pp); % integrate the smoothed spline
%         A = ppval(hh,thdOnsetTime);
%         B = ppval(hh,peakX);
%         C = ppval(hh,thdOffsetTime);
%         aucLeft = B-A; % area under the curve left
%         aucRight = C-B; % area under the curve right
%         hyst = aucRight / aucLeft; % hysteresis as a ratio of area under the curves
%         if hyst < 0
%             keyboard
%         end
%         hysteresis = hyst;
%     catch
%         hysteresis = NaN;
%     end
%     % Calculate the slopes ------------------
%     try
%         peak_index = round(peakX /.05);
%         index_xa = round(thdOnsetTime / .05);
%         index_xb = round(thdOffsetTime / .05);
%         part1_x = x(index_xa:peak_index);
%         part1_y = d1(index_xa:peak_index);
%         part2_x = x(peak_index+1:index_xb);
%         part2_y = d1(peak_index+1:index_xb);
%         slope_ascending = polyfit(part1_x,part1_y,1);
%         slope_descending = polyfit(part2_x,part2_y,1);
%         slopeUp = slope_ascending(1);
%         slopeDn = slope_descending(1);
%     catch
%         slopeUp = NaN;
%         slopeDn = NaN;
%     end
% end
% %---------------------------------------------------------------------------
%
% MEMR.Trend = Trend;
% MEMR.Trendn = Trendn;
% MEMR.trend = trend;
% MEMR.trendn = trendn;
% MEMR.timeTrend = timeTrend;
% MEMR.D = D;
% MEMR.D1 = D1;
% MEMR.D2 = D2;
% MEMR.d = d;
% MEMR.d1 = d1;
% MEMR.d2 = d2;
% MEMR.x = x;
% MEMR.t = t;
% MEMR.freq = freq;
% MEMR.Z = Z;
% MEMR.Z_sm = Z_sm;
% if stabilityCheck ~=1
%     MEMR.peakTime = peakX;
%     MEMR.peakAmp = peakY;
%     MEMR.delay = delay;
%     MEMR.thdOnsetTime = thdOnsetTime;
%     MEMR.thdOffsetTime = thdOffsetTime;
%     MEMR.thdOnsetLvl = thdOnsetLvl;
%     MEMR.thdOffsetLvl = thdOffsetLvl;
%     MEMR.hysteresis = hysteresis;
%     MEMR.slopeUp = slopeUp;
%     MEMR.slopeDn = slopeDn;
%     MEMR.thd = thd;
%     MEMR.thdAmp = thdAmp;
%     MEMR.elicitorLevel = elicitorLevel;
% end
% end
% function [CFT,TREND,W] = memrDetrend(CFT)
% nFreqs = size(CFT,1);
% for ii=1:nFreqs % do this individually for each frequency
%     cc = squeeze(CFT(ii,:,:)); % pick the current frequency
%     mr = real(cc); % the real part
%     mr = mr'; % transpose
%     [rows,cols] = size(mr); % use this later to reshape ack
%     mr = mr(:); % force to a single column
%     mi = imag(cc); % now do the same for the imaginary part
%     mi = mi';
%     mi = mi(:);
%     x = (1:1:length(mr))'; % x-axis vector for spline fitting
%     w = ones(size(mr)); % weighting vector (set to ones)
%
%     doPlotAR = 0;
%     multiplier = "mild";
%     %[rejectIndx,nRejects] = newAR2(mr',multiplier,doPlotAR);
%     [rejectIndx,nRejects] = AR(mr',multiplier,doPlotAR);
%
%
%     w(rejectIndx) = 0; % downweight noisy samples to zero
%
%     % was 0.00000000001;
%     smoothing = 0.000000001; % smoothing factor--0 is a straight line, 1 is cubic spline
%     ppr = csaps(x,mr,smoothing,[],w); % piecewise polynomial real coefficients
%     ppi = csaps(x,mi,smoothing,[],w); % piecewise polynomial imaginary coefficients
%     mr_sm = ppval(ppr,x);
%     mi_sm = ppval(ppi,x);
%
%     %         figure
%     %         plot(mr.*w,'b.')
%     %         hold on
%     %         plot(mr_sm,'r')
%     %         keyboard
%
%     trend = mr_sm+1i*mi_sm;
%     offset = mean(trend); % mean location before detrending
%     mrfixed = mr - mr_sm; % "fixed", i.e., detrended version of mr
%     mifixed = mi - mi_sm;
%     mrfixed = reshape(mrfixed,rows,cols);
%     mifixed = reshape(mifixed,rows,cols);
%     trend = reshape(trend,rows,cols);
%     w = reshape(w,rows,cols);
%     z = mrfixed + 1i*mifixed + offset; % add the offset back in to the complex form
%     CFT(ii,:,:) = z.';
%     TREND(ii,:,:) = trend.';
%     W(ii,:,:) = w.';
% end
% end
% function b = bpf()
% % FIR Window Bandpass filter designed using the FIR1 function.
% Fs = 96000;  % Sampling Frequency
% Fstop1 = 700;              % First Stopband Frequency
% Fpass1 = 1000;             % First Passband Frequency
% Fpass2 = 3500;            % Second Passband Frequency
% Fstop2 = 4500;            % Second Stopband Frequency
% Dstop1 = 0.001;           % First Stopband Attenuation
% Dpass  = 0.057501127785;  % Passband Ripple
% Dstop2 = 0.001;           % Second Stopband Attenuation
% flag   = 'scale';         % Sampling Flag
% % Calculate the order from the parameters using KAISERORD.
% [N,Wn,BETA,TYPE] = kaiserord([Fstop1 Fpass1 Fpass2 Fstop2]/(Fs/2), [0 ...
%     1 0], [Dstop1 Dpass Dstop2]);
% if mod(N,2)~=0
%     N = N + 1;
% end
% % Calculate the coefficients using the FIR1 function.
% b  = fir1(N, Wn, TYPE, kaiser(N+1, BETA), flag);
% b = b(:);
% end
%