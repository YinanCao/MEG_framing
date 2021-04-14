clear; clc; close all;

if IsLinux
log_dir = '/home/usera/Documents/MEG_framing_data/';
else
log_dir = '/Users/yinancaojake/Documents/Postdoc/UKE/MEG_framing_data/';
end

for subj = 2:3

SubName = ['subj#_',num2str(subj)];

% 9 types (angles):
ang = [ 3,3,3
        2,2,2
        1,1,1
        1,2,3
        2,3,1
        3,2,1
        1,3,2
        2,1,3
        3,1,2];
angle_set = [1,2,3]; % [-75,-45,-15]
ang = angle_set(ang);
% 10 contrast comb:
con = nchoosek(1:5,3); % sorted naturally in each row
loc_perm = perms(1:3); % spatial permutation

% 10 con comb, 2 frames, 6 loc perms, 9 types
fullcond = [];

for type = 1:9
    trl = 1;
    for c = 1:10
        for loc = 1:6
            for f = 1:2
                 fullcond = [fullcond;type,c,loc,f,trl];
                 trl = trl + 1;
            end
        end
    end
end
size(fullcond)

type = fullcond(:,1);
n = size(fullcond,1);

while 1

X1 = [type, fullcond(:,2:end)];
X2 = permute(reshape(X1,120,size(X1,1)/120,[]),[1,3,2]);
for eachrow = 1:120
    X2(eachrow,:,:) = X2(eachrow,:,randperm(9));
end

X = [];
for bb = 1:size(X2,3)
    X = [X;X2(:,:,bb)];
end

nt = size(X,1);
Y = [];
for k = 1:nt
    type_t = ang(X(k,1),:); % corresponds to low-to-high c
    % when spatial changes, type (angle) also changes
    c_t = con(X(k,2),:); % sorted,low to high contrast
    l_t = loc_perm(X(k,3),:); % spatial perm
    c_TLR = c_t(l_t); % contrast, from T,to L,to R locations
    a_TLR = type_t(l_t); % angles, from T,to L,to R locations
    frame = X(k,4);
    [~,low] = min(c_TLR);
    [~,high] = max(c_TLR);
    var = [low,high];
    answer = var(frame);
    Y = [Y;c_TLR, a_TLR, answer, frame, X(k,end), X(k,1)];
end

% 3rd dim is blocks:
Y2 = permute(reshape(Y,120,size(Y,1)/120,[]),[1,3,2]);

beta = []; pall = [];
for whichrun = 1:size(Y2,3)
    y = Y2(:,:,whichrun);
    b = []; p = [];
    for f = 1:3 % frame
        y2 = y(y(:,8)==f,:);
        
        if f==3
            y2 = y; % combine 2 frames, all 120 trials
        end
        rsp = y2(:,7); % answer
        ph = zeros(length(rsp),3);
        for ii = 1:length(rsp)
            ph(ii,rsp(ii)) = 1;
        end
        
        % angle predictors:
        tmp1 = y2(:,4:6); % raw angles
        tmp2 = abs(tmp1-angle_set(2)); % distance to oblique
        
        tmp1 = zscore(tmp1);
        tmp2 = zscore(tmp2);

        for TLR = 1:3 % each location individually
            [B,DEV,STATS] = glmfit(tmp1(:,TLR),ph(:,TLR));
            b = [b,B(2)];
            p = [p,STATS.p(2)];
        end
        
        for TLR = 1:3
            [B,DEV,STATS] = glmfit(tmp2(:,TLR),ph(:,TLR));
            b = [b,B(2)];
            p = [p,STATS.p(2)];
        end
    end
    beta = [beta;b];
    pall = [pall;p];
end

min_N_per_ori_class = [];
for k = 1:120
    min_N_per_ori_class = [min_N_per_ori_class;...
        min([sum(X(X(:,end)==k,1)<=3),sum(X(X(:,end)==k,1)>3)])];
end
    p_s = pall<=0.08;
    if sum(p_s(:))==0 && sum(ttest(beta))==0 && min(min_N_per_ori_class)>=1
        break;
    end
end

beta
ttest(beta)
pall

framing_design = Y2(:,1:8,:);

if ~exist([log_dir,SubName,'_framing_design.mat'],'file')
save([log_dir,SubName,'_framing_design.mat'],'framing_design','beta','pall','Y','X','min_N_per_ori_class');
end



end




