
SubName = 'KSS18';

%if IsLinux
   log_dir = '/home/usera/Documents/MEG_framing_data/';
   addpath(genpath('/usr/share/psychtoolbox-3/'))
%else
   %log%_dir = '/Users/yinancaojake/Documents/Postdoc/UKE/MEG_framing_data/';
%end
close all; clc;

fn = [log_dir,SubName,'_contrast_JND*.mat'];
f = dir(fn);

figure
hold
if ~isempty(f)
    for k = 1:length(f)
        load([log_dir,f(k).name])
        subplot(1,3,k)
        c = 0;
        for i = 1:2
            c = c + 1;
            eval(['plot(10.^(JND_BDMOGtask.Quest.Quantile' int2str(i) '));']); hold on;
            eval(['Q =(10.^QuestQuantile(JND_BDMOGtask.Quest.q' int2str(i) '(end-10:end-1)));']);
            last10_trials(c,:) = Q;
            mean_last10_trials(c) = mean(Q);
            x = JND_BDMOGtask.Trial.Gabor_all_contrast_base(i);
            xlabel('Trials','Fontsize',16);
        end
    end
end




