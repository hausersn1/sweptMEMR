%Script Designed to collect swept MEMRs for a given subject using the
%Interacoustics Titan
%Created by: Sam Hauser
%Updated: 08/2025
%Figure size changed by SH on 12/2023
%Based on code found in dpOAE_main.m from ARDC_Acquisition and Shawn
%Goodman's version of swept MEMR. 

%%%%%%%%%%%%%%%%%%%
%Currently this is just a copy of the OAE code, but will use this framework
%to start the swept MEMR code, which should be similar in terms of playing
%a stimulus and recording the response. Should be possible to do binaural
%stimulation for ipsi/contra recordings
%%%%%%%%%%%%%%%%%%%%

%% Start Code 
clear all;
clc;
close all;

% Set up directories to Titan hardware
addpath([pwd '\i3'])
load TransducerCalIOWA.mat

%Be sure to update the dataPath as needed. All data will be saved here.
dataPath = 'C:\Users\ARDC User\Desktop\DATA';

%check to make sure dataPath exists
if(exist(dataPath,'dir')==0)
    mkdir(dataPath);
end

orig_path = pwd;
%% Load calibration file
[file, pathname]  = uigetfile([dataPath, '\Calib*.mat']);
load([pathname, file])

%% Initialize Parameters:

[filename, researcher, start_time] = get_fname('MEMR',dataPath);
filename = char(filename);

click = calibData.stim_click; 
click = click(find(click>0, 1):end, 1);

%creating a new trial
%fs = 44100;
stim = makeSweptMEMRstim(click); 
fs = stim.fs; 
Interface = OAE_Interface(fs);

dB = [80, 100]; % will need to figure out how to calibrate level 

% Add filter for FPL
delay = 128; 
filt_click = zeros(size(stim.clickStimulus)); %not really filter, just delay
filt_click(delay+1:end,1) = stim.clickStimulus(1:end-128,1); 
filt_noise = filter(calibData.b_Pfor, 1, stim.NoiseStimulus) * db2mag(dB(2)-calibData.dBFPL_ideal); %* db2mag(FPL1k_1) * db2mag(105-FPL1k_1); % * db2mag(-scaledB);

click_mV = filt_click; 
noise_mV = filt_noise; 



press = zeros(100,1);

% %Check that probe is in the ear: 
% try
%     while(max(press)<50)
%             disp('Place probe in ear')
%             Interface.SetPressure(50,20,0);
%             press = Interface.pressure;
%     end        
%     Interface.SetPressure(0,20,0);
%     disp('Probe in ear!')
% catch
%     error('Cannot set pressure. Is device turned on and connected?')
% end

% % Loop for running based on the number of trials desired
% mV_amp = get_mV_MEMR(dB); 
% click = stim.clickStimulus; 
% response = zeros(size(stim.NoiseStimulus)); 
%
ntrials = 8; 
disp('Playing Stimulus') 

Interface.StartTrialMEMR(click_mV, noise_mV, ntrials);

% Wait for 20% extra
while ~Interface.IsDone
    pause(0.05);
end

Interface.StopTrial();

response = Interface.response';



% %% Instead of Loop, feed in whole stim at once. 
% % Loop for running based on the number of trials desired
% 
% disp('Playing Stimulus') 
% 
% noise = noiseByTrial(:); 
% clicks = repmat(click, stim.numOfTrials,1); 
% 
% Interface.StartTrialMEMR(clicks, noise, mV_amp);
%     
% % Wait for 20% extra
% while ~Interface.IsDone
%     pause(0.05);
% end
%      
% Interface.StopTrial();
% 
% response_all = Interface.response';
% 
% response = reshape(response_all, numel(click), stim.numOfTrials); 
%  

%% Save
cd(dataPath)
MEMR.stim = stim; 
MEMR.resp = response; 
save([filename,'.mat'],'-struct','MEMR');

cd(orig_path);





% 
% cd(dataPath)
% save([filename,'.mat'],'-struct','oae_data');
% 
% cd(orig_path);

%% Quick Plot of DPgram from mat file (make this a function later)

%plt_dp([filename,'.mat'], dataPath);
