%% Create Stimuli 
function stim = Make_sweptMEMR_stim()

fs = 48828.125; % samples/sec

clickatt = 30 + 6; % + 6 for HB7 with differential output
ThrowAway = 1; 
numOfTrials = 20; 

totalDur = 4; % seconds (x2 for total stim duration, up and down)
bandwidth = 8000; % Hz
fc = 4500; % 1-8 kHz

noiseburstdur = 120; % ms

%% Generate a single click
clickN = 5; % number of samples in the click
clickLen = 41.92; % ms; desired stimulus length in seconds
nSamples = ceil(clickLen * 1e-3  * fs); % total number of samples
if mod(nSamples,2) ~= 0 % make total number of samples even
    nSamples = nSamples + 1;
end

click = zeros(nSamples,1);

startSample = floor(nSamples/3); % silence before the click onset (samps)
click(startSample:startSample + (clickN-1)) = 0.95;

%% Generate noise shape
noiseSamples = ceil(totalDur * fs); % total 
total_nSamples = nSamples + ceil(noiseburstdur .* fs .* 1e-3) + 256; 

h = linspace(0,54,noiseSamples)';
h(1) = eps;
h = [h;flipud(h)];
h = 10.^(h/20); % noise amplitude in linear units
h = h / max(abs(h)) * 0.95; % rescale to unit amplitude

%% Make the click train
longclick = zeros(total_nSamples, 1); % give extra space for the noise burst
longclick(256+(1:numel(click)), 1) = click; 

clicksPerTrain = floor((noiseSamples*2) / total_nSamples);
clickTrain = repmat(longclick,1,clicksPerTrain);
clickTrain = clickTrain(:);


%% Generate noise
rows = size(h,1); % length of noise in samples
cols = numOfTrials + ThrowAway;

for m = 1:cols
    noise(:, m) = makeNBNoiseFFT(bandwidth, fc, totalDur.*2, fs, 0);
end

Noise = noise .* h; % multiply your noise vector by the shaping

 
C = zeros(rows, 1); 
C(1:numel(clickTrain), 1) = clickTrain; 

%% Take out chunks for the click

holeN1 = startSample + 256;  % number of hole samples before the click
holeN2 = numel(click)-startSample; % number of hole samples for after the click

clickIndx = find(clickTrain>.01); % location of clicks; will only correctly for 1 sample clicks

Mask = ones(size(Noise));
for ii=1:length(clickIndx)
    Mask(clickIndx(ii)-holeN1+1:clickIndx(ii)+holeN2,:) = 0;
end

N = Noise .* Mask;

% Plot stimulus so far
t = 0:(1/fs):(rows-1)/fs; 
figure; plot(t, N); hold on; plot(t, C)


% Values to save as stim
stim.N = N; 
stim.C = C; 

stim.fs = fs; 

stim.clickatt = clickatt;
stim.noiseatt = 18; 
stim.ThrowAway = ThrowAway; 
stim.numOfTrials = numOfTrials; 

stim.totalDur = totalDur; 
stim.bandwidth = bandwidth; 
stim.fc = fc; 

stim.noiseburstdur = noiseburstdur; 


end