clear; clc; close all;

SubName = 'MSi';
gabor_triangle_rotation = 'L';
EL_flag = 0;
trigger_flag = 0;

debug = 1;

%---------------
% initialization:
global_variables;
%---------------

%---------------
% Design matrix:
%---------------
% orientation = 6, location = 3, rep = 4;
Trial.gabor_orientation_set = -75:30:75;
n_orientations = length(Trial.gabor_orientation_set);
design = [];
validity = 1;
trigger_id = 10; % sensory loc triggers starts with 11
for loc = 1:3
    for ori = 1:n_orientations
        trigger_id = trigger_id + 1;
        for rep = 1:4
            design = [design; validity,loc,ori,trigger_id];
            
        end
    end
end
validity = 0; % target trials
targ_trial_ori = randperm(n_orientations);
k = 1;
for loc = 1:3
    trigger_id = trigger_id + 1;
    for rep = 1:2
        ori = targ_trial_ori(k);
        design = [design; validity,loc,ori,trigger_id];
        k = k + 1;
    end
end

while 1 % not too close in time
    design = design(randperm(size(design,1)),:);
    idx = find(design(:,1)==0);
    if sum(diff(idx)<=6) == 0 && min(idx)>2
        break;
    end
end
nTrials = size(design,1);
Trial.design = design;

%---------------
% Start the task
%---------------
DrawFormattedText(window, 'Bitte machen Sie sich bereit', 'center', center_y + 175, white);
Screen('Flip', window);
waiting_screen;

% ET calibration:
if info.ET
    disp('ET calibrating')
    [el, info] = ELconfig_yc(window,[SubName,'_SL',num2str(session),num2str(run)], info, screenNumber);
    % Calibrate the eye tracker
    el.callback = [];
    EyelinkDoTrackerSetup(el);
end
disp('ET calibration done! >>>>>>>>>>')

ITI = [0.85, 1.1];
Trial.iti = min(ITI) + abs(diff(ITI))*rand(1,nTrials);
Trial.stimdur = 0.35;
stimFrames = round(Trial.stimdur/ifi);
Trial.deadline = 0.7;
Trial.FBD = 0.2;
Trial.timeout = 0.5;

timing = [];

for trial = 1:nTrials
    
    % fixation presentation before stimulus onset
    Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]);
    Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
    start_fix = Screen('Flip', window);
    trigger(info.fix_trig) % >>>>>>>>>>>
    if info.ET
        Eyelink('command', 'record_status_message "TRIAL %d/%d"', trial, nTrials);
        Eyelink('message', 'TRIALID %d', trial);
        Eyelink('message', num2str(info.fix_trig));
    end
    fixFrames = round(Trial.iti(trial)/ifi);
    
    % Gabor:
    contrast = 1;
    location = design(trial,2);
    orientation = Trial.gabor_orientation_set(design(trial,3));
    [textureIndexTarg,dstRect] = create_gabor(window, Gabor, contrast, location);
    stim_trig = design(trial,end);
    valid_trial = design(trial,1);
    
    % present stimulus:
    if valid_trial
        Screen('DrawTextures', window, textureIndexTarg, [], dstRect, orientation);
        Screen('FrameOval', window, Gabor.holder_c, dstRect, Gabor.outlineWidth);
        Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]);
        Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
        stimOnset = Screen('Flip', window, start_fix + (fixFrames - .5)*ifi);
        trigger(stim_trig) % >>>>>>>>>>>
        if info.ET
            Eyelink('message', num2str(stim_trig));
        end
    else
        nflicker = 6;
        fix_dot_contrast = ones(1,stimFrames);
        fix_dot_contrast(end-nflicker+1:end) = rand(1,nflicker);
        vbl = start_fix + (fixFrames - .5)*ifi;
        for frame_i = 1:stimFrames
            Screen('DrawTextures', window, textureIndexTarg, [], dstRect, orientation);
            Screen('FrameOval', window, Gabor.holder_c, dstRect, Gabor.outlineWidth);
            Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]);
            Screen('FillOval', window, fix_dot_contrast(frame_i),...
                CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
            vbl = Screen('Flip', window, vbl + .5*ifi);
            if frame_i==1, stimOnset = vbl; trigger(stim_trig); 
                if info.ET
                    Eyelink('message', num2str(stim_trig));
                end
            end
        end
    end
    
    % Stimulus ends:
    Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]);
    Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
    stimOff = Screen('Flip', window, stimOnset + (stimFrames - .5)*ifi);
    trigger(stim_trig) % >>>>>>>>>>>
    if info.ET
        Eyelink('message', num2str(stim_trig));
    end
    
    endrt = GetSecs;
    
    if ~valid_trial
        start = stimOff;
        flush_kbqueues(info.kbqdev);
        [keyIsDown, secs, press_key, deltaSecs] = KbCheck(-3,2);
        while ( (press_key(LH)==0  && press_key(RH)==0) && GetSecs-start<Trial.deadline)
            [keyIsDown, secs, press_key, deltaSecs] = KbCheck(-3,2);
            endrt = secs;
        end
        if press_key(LH) || press_key(RH)
            DrawFormattedText(window,'Correct','center',center_y-50,green);
        else
            DrawFormattedText(window,'Missed','center',center_y-50,red);
        end
        
        response_func;
        Trial.answer{trial} = rsp;
        
        Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]);
        Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
        start_FB = Screen('Flip',window);
        WaitSecs(Trial.FBD);
        Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]);
        Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
        Screen('Flip', window);
        % time out:
        WaitSecs(Trial.timeout);
    end
    
    timing = [timing; start_fix,stimOnset,stimOff,endrt,valid_trial];
    Screen('Close', textureIndexTarg);
    
end



Screen('CloseAll');
