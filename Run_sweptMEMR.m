%Script Designed to collect swept MEMRs for a given subject using the
%ER10X and TDT hardware
%Created by: Sam Hauser
%Updated: 04/2026
%
%Based on code found in dpOAE_main.m from ARDC_Acquisition and Shawn
%Goodman's version of swept MEMR.

%%%%%%%%%%%%%%%%%%%
%Currently this is just a copy of the OAE code, but will use this framework
%to start the swept MEMR code, which should be similar in terms of playing
%a stimulus and recording the response. Should be possible to do binaural
%stimulation for ipsi/contra recordings
%%%%%%%%%%%%%%%%%%%%

%% Set up data storage and subject info

% Measure-General info
info.name = 'sweptMEMR';
info.version = 'v01';

% Visit info
if exist('C:\Experiments\SNAPacoustics\NEW_OAES\current_visit.mat','file')
    load('C:\Experiments\SNAPacoustics\NEW_OAES\current_visit.mat', 'visit')
    ask = questdlg(sprintf('Is this subject %s?', visit.subj.ID), ...
        'Check Subject', 'Yes', 'No', 'No');
else
    ask = 'No';
end

if strcmp(ask, 'No')
    cd C:\Experiments\SNAPacoustics\NEW_OAES\
    startVisit
    cd C:\Experiments\SNAPacoustics\sweptMEMR\
end

subj = visit.subj;
info.room = visit.room;
info.univ = visit.univ;
info.researcher = visit.researcher;


% Get ear info
subj.ear = questdlg('Which ear?', 'Ear', 'L', 'R', 'R');

% Get date/time
datetag = datestr(clock);
info.date = datetag;
datetag(strfind(datetag,' ')) = '_';
datetag(strfind(datetag,':')) = '-';

% Make directory to save results
paraDir = 'C:\Experiments\SNAPacoustics\sweptMEMR\Results\';
respDir = strcat(paraDir,filesep,visit.subj.ID,filesep);
addpath(genpath(paraDir));
if(~exist(respDir,'dir'))
    mkdir(respDir);
end

fname = strcat(respDir, info.name, '_', ...
    subj.ID, '_', subj.ear, '_', datetag, '.mat');

%% Plays clicks and noise, records response
% Initializing TDT
fig_num=99;
GB_ch=1;
FS_tag = 3;
Fs = 48828.125;
[f1RZ,RZ,~]=load_play_circuit(FS_tag,fig_num,GB_ch);

% Initialize ER-10X  (Also needed for ER-10C for calibrator)
initializeER10X;

%% DO FULL BAND FIRST
stim = Make_sweptMEMR_stim;

pause(3);

tic;

%Set the delay of the sound
invoke(RZ, 'SetTagVal', 'onsetdel',0); % onset delay is in ms
playrecTrigger = 1;

%% Set attenuation and play
resplength = numel(stim.t);
resp = zeros(stim.Averages, resplength);

invoke(RZ, 'SetTagVal', 'attA', stim.clickatt );
invoke(RZ, 'SetTagVal', 'attB', stim.noiseatt);
invoke(RZ, 'SetTagVal', 'nsamps', resplength);

for n = 1: (stim.Averages + stim.ThrowAway)

    buffdataL = stim.C;
    buffdataR = stim.N(:,n);

    % Check for clipping and load to buffer
    if(any(abs(buffdataL(:)) > 1) || any(abs(buffdataR(:)) > 1))
        error('What did you do!? Sound is clipping!! Cannot Continue!!\n');
    end

    %Load the 2ch variable data into the RZ6:
    %invoke(RZ, 'WriteTagVEX', 'datain', 0, 'I16', (buffdata*2^15));
    invoke(RZ, 'WriteTagVEX', 'datainL', 0, 'F32', buffdataL);
    invoke(RZ, 'WriteTagVEX', 'datainR', 0, 'F32', buffdataR);
    pause(1.5);

    %Start playing from the buffer:
    invoke(RZ, 'SoftTrg', playrecTrigger);
    currindex = invoke(RZ, 'GetTagVal', 'indexin');
    while(currindex < resplength)
        currindex=invoke(RZ, 'GetTagVal', 'indexin');
    end

    vin = invoke(RZ, 'ReadTagVex', 'dataout', 0, resplength,...
        'F32','F64',1);
    %Accumluate the time waveform - no artifact rejection
    if (n > stim.ThrowAway)
        %                 response = zeros(size(vin));
        %                 response(1:end-filtdelay) = vin(filtdelay+1:end);
        %                 resp(L, n-stim.ThrowAway, k, :) = response;
        resp(n-stim.ThrowAway, :) = vin;
    end

    % Get ready for next trial
    invoke(RZ, 'SoftTrg', 8); % Reset OAE buffer

    fprintf(1, 'Done with Trial # %d \n', n);
end


pause(2);



%% Info for conversion.. no averaging or conversion done online

mic_sens = 0.05; % V / Pa-RMS
mic_gain = db2mag(36);
P_ref = 20e-6; % Pa-RMS

DR_onesided = 1;

stim.mat2Pa = 1 / (DR_onesided * mic_gain * mic_sens * P_ref);


%% Save results

data.info = info;
data.stim = stim;
data.info.subj = subj;
data.resp.AllBuffs = resp;
data.resp.testDur_s = toc;

save(fname,'data');

%% Close and clean up
close_play_circuit(f1RZ, RZ);
closeER10X;