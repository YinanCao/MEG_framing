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
% Start the task
%---------------
DrawFormattedText(window, 'Bitte machen Sie sich bereit', 'center', center_y + 175, white);
Screen('Flip', window);
waiting_screen;

motor_cue_name = {'Left Hand','Right Hand','Foot'};
cue_id = repmat([1;2;footid],30,1);
nTrials = length(cue_id);
cue_id = cue_id(randperm(nTrials));

Trial.motor_text_cue_dur = 0.3;
Trial.motordelay = 1;
Trial.motor_loc_deadline = 1;
ITI = [0.75, 1.5];
Trial.motoriti = min(ITI) + abs(diff(ITI))*rand(1,nTrials);
Trial.pre_FB = 0.3;
Trial.FBD = 0.2;
Trial.timeout = 2;

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
    fixFrames = round(Trial.motoriti(trial)/ifi);
    
    
    % response cue text:
    DrawFormattedText(window, motor_cue_name{cue_id(trial)}, 'center', center_y-50, white);
    Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]);
    Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
    cueOn = Screen('Flip', window, start_fix + (fixFrames - .5)*ifi);
    WaitSecs(Trial.motor_text_cue_dur);
    
    % delay period:
    Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]);
    Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
    cueOff = Screen('Flip', window);
    
    % go signal:
    delayFrames = round(Trial.motordelay/ifi);
    Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[45,90+45]);
    Screen('FillOval', window, green, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
    motorGo = Screen('Flip', window, cueOff + (delayFrames - .5)*ifi);
    
    % response & feedback:
    start = motorGo;
    flush_kbqueues(info.kbqdev);
    [keyIsDown, secs, press_key, deltaSecs] = KbCheck(-3,2);
    while ( press_key(LH)==0  && press_key(RH)==0 && ...
            press_key(LF)==0  && press_key(RF)==0 && ...
            GetSecs-start < Trial.motor_loc_deadline )
        [keyIsDown, secs, press_key, deltaSecs] = KbCheck(-3,2);
        endrt = secs;
    end
    response_func; % >>>>>>>>>>
    if ~isnan(rsp_code)
        if rsp_code == cue_id(trial)
            DrawFormattedText(window,'Correct','center',center_y-50,green);
        else
            DrawFormattedText(window,'Wrong','center',center_y-50,red);
        end
    else
        DrawFormattedText(window,'Missed','center',center_y-50,red);
    end
    Trial.answer{trial} = rsp;
    
    WaitSecs(Trial.pre_FB);
    Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]);
    Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
    Screen('Flip', window);
    WaitSecs(Trial.FBD);
    
    Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]);
    Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
    Screen('Flip', window);
    
    WaitSecs(Trial.timeout);
    
end


