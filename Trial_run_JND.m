%  fixation presentation before stimulus onset
Rotated_fixation(window, fix_rect, center_x, center_y,dark_grey,[0,90]);
Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
[start_delay] = Screen('Flip', window);
WaitSecs(TrialJND.BRD(trial));

%   Get the threshold from the QUEST
w_q = num2str(TrialJND.Which_quest(trial));
eval(['tr=QuestQuantile(Quest.q' w_q '(q_counter' w_q '));']);
eval(['Quest.Quantile' w_q '(q_counter' w_q ')=QuestQuantile(Quest.q' w_q '(q_counter' w_q '));']);
eval(['Quest.Mean' w_q '(q_counter' w_q ')=QuestMean(Quest.q' w_q '(q_counter' w_q '));']);
eval(['Quest.Mode' w_q '(q_counter' w_q ')=QuestMode(Quest.q' w_q '(q_counter' w_q '));']);
eval(['q_counter' w_q '=q_counter' w_q '+1']);

if 10^(tr) < TrialJND.Gabor_contrast(trial)
    tr = log10(TrialJND.Gabor_contrast(trial));
    eval(['Quest.Quantile' w_q '(q_counter' w_q '-1)=tr;']);
end

if TrialJND.Gabor_position(trial) =='R' % 1 for left and 2 for right
    TrialJND.contrast_right(trial)= (10.^(tr));
    TrialJND.contrast_left(trial)= TrialJND.Gabor_contrast(trial);
    TrialJND.contrast(trial,2)=(10.^(tr));
    TrialJND.contrast(trial,1)=TrialJND.Gabor_contrast(trial);
else %'L'
    TrialJND.contrast_left(trial)= (10.^(tr));
    TrialJND.contrast_right(trial)= TrialJND.Gabor_contrast(trial);
    TrialJND.contrast(trial,1)=(10.^(tr));
    TrialJND.contrast(trial,2)=TrialJND.Gabor_contrast(trial);
end

% store some date
TrialJND.log10_tr(trial)=tr;
TrialJND.contrast_tr(trial)=10.^tr;
TrialJND.contrast_B(trial)=TrialJND.Gabor_contrast(trial);
TrialJND.JND_contrast(trial)= TrialJND.contrast_tr(trial)-TrialJND.contrast_B(trial);
TrialJND.JND_log10contrast(trial)= TrialJND.log10_tr(trial)-log10(TrialJND.contrast_B(trial));
eval(['Quest.JND_contrast' w_q '(q_counter' w_q '-1)=TrialJND.JND_contrast(trial);']);
eval(['Quest.JND_log10contrast' w_q '(q_counter' w_q '-1)=TrialJND.JND_log10contrast(trial);']);

% Stimulus presentation
create_gabor_JND;
Rotated_fixation(window, fix_rect, center_x, center_y,dark_grey,[0,90]);
Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
[TrialJND.stimulus_on(trial)]=Screen('Flip', window);
TrialJND.real_BRD(trial)=TrialJND.stimulus_on(trial)-start_delay;
WaitSecs(TrialJND.SD(trial)); % Duration of the stimulus presentation

% Gap from Stimulus off to response cue on
Rotated_fixation(window, fix_rect, center_x, center_y,dark_grey,[0,90]);
Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
[TrialJND.stimulus_off(trial)]=Screen('Flip', window);
WaitSecs(TrialJND.StRCD);

% response cue
Rotated_fixation(window, fix_rect, center_x, center_y,dark_grey,[45,135]);
Screen('FillOval', window, white, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
[TrialJND.response_cue_on(trial)] = Screen('Flip', window);
TrialJND.real_SD(trial) = TrialJND.stimulus_off(trial)-TrialJND.stimulus_on(trial);
TrialJND.real_StRCD(trial) = TrialJND.response_cue_on(trial)-TrialJND.stimulus_off(trial);
start = TrialJND.response_cue_on(trial);
flush_kbqueues(info.kbqdev);

[keyIsDown, secs, press_key, deltaSecs] = KbCheck();
endrt = GetSecs;
while (press_key(LH)==0  && press_key(RH)==0 && GetSecs-start<TrialJND.RCD)
    [keyIsDown, secs, press_key, deltaSecs] = KbCheck();
    endrt = GetSecs;
end
TrialJND.RT(trial) = endrt-start;

% check the answer
if press_key(LH)
    TrialJND.answer(trial)='L';
elseif press_key(RH)
    TrialJND.answer(trial)='R';
else
    TrialJND.answer(trial)='I';
end
% evaluate the answer
if  TrialJND.answer(trial) =='I'
    TrialJND.eval_answer(trial) = 2;
    Rotated_fixation(window, fix_rect, center_x, center_y,dark_grey,[45,135]);
    Screen('FillOval', window, red, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
    drawtext_realign(window, 'Missed', center_y-info.fb_pix, red, info)
    [start_FB]=Screen('Flip', window);
    WaitSecs(TrialJND.FBD); % Feedback presentation/ Missed or Ignored
else
    if TrialJND.answer(trial)==TrialJND.Gabor_position(trial)
        TrialJND.eval_answer(trial)=1;
        Rotated_fixation(window, fix_rect, center_x, center_y,dark_grey,[45,135]);
        Screen('FillOval', window, green, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
        [start_FB]=Screen('Flip', window);
        WaitSecs(TrialJND.FBD);
    else
        TrialJND.eval_answer(trial)=0;
        Rotated_fixation(window, fix_rect, center_x, center_y,dark_grey,[45,135]);
        Screen('FillOval', window, red, CenterRectOnPointd([0 0 lineWidthPix lineWidthPix], center_x, center_y));
        [start_FB]=Screen('Flip', window);
        WaitSecs(TrialJND.FBD); % Feedback presentation/ Wrong
    end
end
TrialJND.real_FBD(trial) = GetSecs-start_FB;