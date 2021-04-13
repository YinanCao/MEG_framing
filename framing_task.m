whichrun = info.whichrun;
SubName_frame = SubName;
if practice
    SubName_frame = 'fake';
    JND = 0.12;
    nTrials = 10;
end

load([log_dir,SubName_frame,'_framing_design.mat']);
N_perrun = size(framing_design,1);
for run = 1:size(framing_design,3) % randomize with run
    framing_design(:,:,run) = framing_design(randperm(N_perrun),:,run);
end
TrialFrame.framing_design = framing_design;

if ~practice
    load([log_dir,SubName,'_contrast_JND.mat'])
    JND = Quest.Quantile_JND;
    nTrials = N_perrun;
end

tmp = [-2,-1,0,1,2]*JND + 0.5;
tmp(tmp>1) = 1;
tmp(tmp<0.15) = 0.15;
info.gabor_contrast_set = tmp;

%---------------
% Start the task
%---------------
drawtext_realign(window, '3-Option Decision-Making', 'center', white, info)
drawtext_realign(window, 'Bitte machen Sie sich bereit', center_y + 175, white, info)
Screen('Flip', window);

if realframing
    WaitSecs(1);
else
    waiting_screen;
end

ITI = [0.75, 1.25];
TrialFrame.iti = min(ITI) + abs(diff(ITI))*rand(1,nTrials);
TrialFrame.iti(1) = 5; % first trial long fixation
TrialFrame.deadline = info.framing_rspdl;
TrialFrame.FBD = info.feedbackdur;
TrialFrame.sensoryDur = info.frame_sensorydur;
TrialFrame.frame_dur = info.frame_dur;
TrialFrame.decision_delay = info.frame_decision_delay;
TrialFrame.stimoff2rsp = info.stimoff2rsp;

for trial = 1:nTrials
    
    if ismember(trial,[41,81]) 
        drawtext_realign(window, '10 s break', 'center', white, info)
        Screen('Flip', window);
        WaitSecs(10);
        TrialFrame.iti(trial) = 3; % longer fixation after break
    end
    
    tic
    % draw gabors:
    txt_id = []; dstRect = [];
    contrast_TLR = info.gabor_contrast_set(framing_design(trial,1:3,whichrun));
    orientat_TLR = info.framing_orientation(framing_design(trial,4:6,whichrun));
    [~,o_level] = ismember(orientat_TLR,Gabor.gabor_orientation_set);
    c_level = framing_design(trial,1:3,whichrun);
    frame_cue = framing_design(trial,8,whichrun);
    f_level   = frame_cue;
    for loc = 1:3
        [txt_id(loc), dstRect(:,loc)] = create_gabor(window, Gabor, contrast_TLR(loc), loc);
    end

    % fixation presentation before stimulus onset
    Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]);
    Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
    start_fix = Screen('Flip', window);
    trig_id = info.fix_trig;
    trigger(trig_id); disp(['fix trig == ',num2str(trig_id)])
    if info.ET
        Eyelink('command', 'record_status_message "TRIAL %d/%d"', trial, nTrials);
        Eyelink('message', 'TRIALID %d', trial);
        Eyelink('message', num2str(trig_id));
    end
    fixFrames = round(TrialFrame.iti(trial)/ifi);
    
    stim_trig_trial = [info.frame_c(c_level),info.frame_o(o_level),info.frame_f(f_level)];
    for stim_trig_k = 1:length(stim_trig_trial)
        WaitSecs(0.005);
        trig_id = stim_trig_trial(stim_trig_k);
        trigger(trig_id);
        disp(['stim trig == ',num2str(trig_id)])
    end

    % sensory phase:
    Screen('DrawTextures', window, txt_id, [], dstRect, orientat_TLR);
    Screen('FrameOval', window, Gabor.holder_c, dstRect, Gabor.outlineWidth);
    Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]);
    Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
    sensory_on = Screen('Flip', window, start_fix + (fixFrames - .5)*ifi);
    
    % frame cue on:
    frame_color_set = {red; blue};
    frame_text_set = {'low','high'};
    Screen('DrawTextures', window, txt_id, [], dstRect, orientat_TLR);
    Screen('FrameOval', window, Gabor.holder_c, dstRect, Gabor.outlineWidth);
    info.usecolor = 0;
    if info.usecolor
        Rotated_fixation(window,fix_rect,center_x,center_y,frame_color_set{frame_cue},[0,90]);
        Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
    else
        drawtext_realign(window, frame_text_set{frame_cue}, 'center', white, info)
    end
    frame_on = Screen('Flip', window, sensory_on + (round(TrialFrame.sensoryDur/ifi) - .5)*ifi);
    
    trig_id = info.frame_on_trig;
    trigger(trig_id); disp(['frame on trig == ',num2str(trig_id)])
    
    % frame cue off:
    Screen('DrawTextures', window, txt_id, [], dstRect, orientat_TLR);
    Screen('FrameOval', window, Gabor.holder_c, dstRect, Gabor.outlineWidth);
    Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]);
    Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
    frame_off = Screen('Flip', window, frame_on + (round(TrialFrame.frame_dur/ifi) - .5)*ifi);
    trig_id = info.delayon_trig;
    trigger(trig_id); disp(['delay on trig == ',num2str(trig_id)])
    
    % decision delay period:
    Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]);
    Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
    delay_off = Screen('Flip', window, frame_off + (round(TrialFrame.decision_delay/ifi) - .5)*ifi);
    
    % response rotation: delay_off to rsp_on = 150 ms gap
    Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]+45);
    Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
    rsp_on = Screen('Flip', window, delay_off + (round(TrialFrame.stimoff2rsp/ifi) - .5)*ifi);
    
    trig_id = info.frame_rspon_trig;
    trigger(trig_id); disp(['rsp on trig == ',num2str(trig_id)])
    
    start = rsp_on;
    flush_kbqueues(info.kbqdev);
    [keyIsDown, secs, press_key, deltaSecs] = KbCheck(-3,2);
    while ( press_key(LH)==0  && press_key(RH)==0 && ...
            press_key(LF)==0  && press_key(RF)==0 && ...
            GetSecs-start<TrialFrame.deadline)
        [keyIsDown, secs, press_key, deltaSecs] = KbCheck(-3,2);
        endrt = secs;
    end
    response_func;

    Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]+45);
    if strcmp(rsp,info.rsp_names{framing_design(trial,7,whichrun)})
       fb_color = 1; rsp_correct = 1;
    else
       fb_color = 2; rsp_correct = 2;
    end
    if strcmp(rsp,'I')
        drawtext_realign(window,'Missed',center_y-info.fb_pix,red,info)
        rsp_correct = 3;
    end
    Screen('FillOval', window, info.fb_color_set{fb_color},...
        CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
    feedbackOn = Screen('Flip', window);
    
    WaitSecs(TrialFrame.FBD);
    % postpone the feedback trigger a bit.
    trig_id = fb_trig_set(rsp_correct);
    trigger(trig_id); disp(['fb trig == ',num2str(trig_id)])
    
    Rotated_fixation(window,fix_rect,center_x,center_y,dark_grey,[0,90]+45);
    Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
    Screen('Flip', window);
    WaitSecs(info.intertrial_gap);
    
    Screen('Close', txt_id)
    
    TrialFrame.answer{trial} = rsp;
    TrialFrame.correct(trial) = rsp_correct;
    TrialFrame.RT(trial) = endrt - start;
    TrialFrame.time(trial,:) = [start_fix,sensory_on,frame_on,frame_off,delay_off,rsp_on,endrt,feedbackOn];
    
    trueanswer_loc = framing_design(trial,7,whichrun);
    TrialFrame.key_variables(trial,:) = [contrast_TLR, orientat_TLR, frame_cue, trueanswer_loc];
    
    toc;
end
