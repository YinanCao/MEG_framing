clear; clc; close all;

c = 0;
for i = 1:2
    c = c + 1;
%                eval(['subplot(1,2,' int2str(c) ');']);
    eval(['plot(10.^(JND_BDMOGtask.Quest.Quantile' int2str(i) '));']);
    eval(['Q =(10.^QuestQuantile(JND_BDMOGtask.Quest.q' int2str(i) '(end-10:end-1)));']);
    last10_trials(c,:)= Q;
    mean_last10_trials(c)= mean(Q);
    x= JND_BDMOGtask.Trial.Gabor_all_contrast_base(i);
%     ylim([-0.002 0.3]);
    if c == 1 
        title('Close tGuess');
    else
        title('Far tGuess');
    end
%     if bt == 'n'
%         ylabel('Near blocks','Fontsize',16);
%     else
%         ylabel('Far blockes');
%     end
        xlabel('Trials','Fontsize',16);
end