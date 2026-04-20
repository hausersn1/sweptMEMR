%% Create Stimuli for Swept MEMR
function stim = Make_sweptMEMR_stim()

% Parameters 
fs = 48828.125; % samples/sec
clickatt = 32 + 6; % +6 for HB7 with differential output
ThrowAway = 1; 
numOfTrials = 20; 

totalDur = 4; % approx duration in seconds (x2 for total stim duration, up and down)
bandwidth = 8000; % Hz for noise frequency content
fc = 4500; % Hz, also for noise frequency content, 4500 Hz for 1-8 kHz with BW = 8k

noiseburstdur = 120; % ms
pad = 256; % extra samples after the noise burst and before the next click

clickN = 5; % number of samples in the click
clickLen = 41.92; % ms; desired click window length in seconds

n_baseline_clicks = 5; % number of extra clicks to append at beginning

% Save some things to the stim file: 
stim.fs = fs; 
stim.clickatt = clickatt;
stim.noiseatt = 4 + 6; 
stim.ThrowAway = ThrowAway; 
stim.Averages = numOfTrials; 

stim.totalDur = totalDur; 
stim.clickWin = clickLen; 
stim.bandwidth = bandwidth; 
stim.fc = fc; 

stim.noiseburstdur = noiseburstdur; 
stim.n_baseline_clicks = n_baseline_clicks; 

%% Generate a single click
nSamples = ceil(clickLen * 1e-3  * fs); % total number of samples in a click window

if mod(nSamples,2) ~= 0 % make total number of samples even
    nSamples = nSamples + 1;
end

click = zeros(nSamples,1);

startSample = floor(nSamples/3); % silence before the click onset (samps)
click(startSample:startSample + (clickN-1)) = 0.95;

%% Generate noise shape
noiseSamples = ceil(totalDur * fs); % total 
total_nSamples = pad + nSamples + ceil(noiseburstdur .* fs .* 1e-3) ; % samples per one burst (pad + click + noiseburst )

noiseSamples = round(noiseSamples/total_nSamples) .* total_nSamples; % make this a multiple of total samples

h = linspace(0,54,noiseSamples)';
h(1) = eps;
h = [h;flipud(h)];
h = 10.^(h/20); % noise amplitude in linear units
h = h / max(abs(h)) * 0.95; % rescale to unit amplitude

stim.h = h; 
%% Make the click train
longclick = zeros(total_nSamples, 1); % give extra space for the noise burst and pad
longclick(pad+(1:numel(click)), 1) = click; 

clicksPerTrain = (noiseSamples*2) / total_nSamples; % figure out the number of clicks needed total
clickTrain = repmat(longclick,1,clicksPerTrain); % concatenate all of them together with correct spacing
clickTrain = clickTrain(:); % make it a row vector

stim.singleClick = longclick; 
stim.clicksPerTrain = clicksPerTrain; 

%% Generate noise
rows = size(h,1); % length of noise in samples
cols = numOfTrials + ThrowAway; % total number of trials

noise = zeros(rows,cols); 
for m = 1:cols
    noise_temp = makeNBNoiseFFT(bandwidth, fc, rows/fs, fs, 0);
    noise(:, m) = noise_temp(1:rows,1); % just make sure it's the same length because makeNBN takes a time input in seconds so could be rounding issues
end

Noise = noise .* h; % multiply your noise vector by the shaping

%% Take out chunks for the click
clickIndex = pad+(1:numel(longclick):rows); % find location of click windows
stim.clickIndex = clickIndex; % save where the click windows start

Mask = ones(size(Noise));

for ii= clickIndex
    Mask(ii-pad:ii+numel(click),:) = 0;
end

Noise_masked = Noise .* Mask;

baseline_clicktrain = repmat(longclick, n_baseline_clicks,1); % Add a bunch of baseline clicks at the beginning of the stimulus 

%% Get the final versions of the stimuli with baseline added.
C = [baseline_clicktrain; clickTrain];

N = zeros(numel(C), cols); 
N(numel(baseline_clicktrain)+(1:rows), :) = Noise_masked; 

% Save final forms of noise and click stimuli
stim.C = C; 
stim.N = N; 

%%
% Plot stimulus 
t = 0:(1/fs):(rows+numel(baseline_clicktrain)-1)/fs; 
stim.t = t; 

figure; plot(t, N); hold on; plot(t, C)
xlabel("Time (s)")
ylabel("Amplitude")

end