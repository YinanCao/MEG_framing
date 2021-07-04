
SubName = 'ZXX';
addpath(genpath('/usr/share/psychtoolbox-3/'))
if IsLinux
   log_dir = '/home/usera/Documents/MEG_framing_data/';
else
   log_dir = '/Users/yinancaojake/Documents/Postdoc/UKE/MEG_framing_data/';
end
close all
load([log_dir,SubName,'_contrast_JND.mat'])

figure
hold
c = 0;
for i = 1:2
    c = c + 1;
               %eval(['subplot(1,2,' int2str(c) ');']);
    eval(['plot(10.^(JND_BDMOGtask.Quest.Quantile' int2str(i) '));']);
    eval(['Q =(10.^QuestQuantile(JND_BDMOGtask.Quest.q' int2str(i) '(end-10:end-1)));']);
    last10_trials(c,:) = Q;
    mean_last10_trials(c) = mean(Q);
    x = JND_BDMOGtask.Trial.Gabor_all_contrast_base(i);
    xlabel('Trials','Fontsize',16);
end