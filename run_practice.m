clear; clc; close all;

log_dir = '/home/usera/Documents/MEG_framing_data/';

SubName = 'YC';

if ~exist([log_dir,SubName,'_framing_design.mat'],'file')
    meg_trialrand2;
end

gabor_triangle_rotation = 'L';
EL_flag = 0;
trigger_flag = 1;
debug = 0;
practice = 1;

%---------------
% initialization:
global_variables;
%---------------

% HideCursor;
info.whichsess = 1;
info.whichrun = 1;

% ET calibration:
if info.ET
    disp('ET calibrating')
    [el, info] = ELconfig_yc(window,[SubName,'_',num2str(info.whichsess),num2str(info.whichrun)],info,screenNumber);
    % Calibrate the eye tracker
    el.callback = [];
    EyelinkDoTrackerSetup(el);
end
disp('ET calibration done! >>>>>>>>>>')

% Start Eyelink recording
if info.ET
    disp('ET recording >>>>>>>>>')
    Eyelink('StartRecording');
    WaitSecs(0.1);
    Eyelink('message', 'Start recording Eyelink');
    trigger(info.eyelinkstart);
end

JND_quest;
%motor_localizer;
%sensory_localizer;
%framing_task;

% Save Eyelink data
if info.ET
    disp('>>> attempting to save ET data >>>')
    time_str = strrep(mat2str(fix(clock)),' ','_');
    eyefilename = fullfile([log_dir,time_str,'_',info.edfFile]);
    Eyelink('CloseFile');
    Eyelink('WaitForModeReady', 500);
    try
        status = Eyelink('ReceiveFile', info.edfFile, eyefilename);
        disp(['File ' eyefilename ' saved to disk']);
    catch
        warning(['File ' eyefilename ' not saved to disk']);
    end
    Eyelink('StopRecording');
end

% Close and clear all
Screen('CloseAll');
ShowCursor;
fclose('all');
Priority(0);
sca;
