%% A script to print stats and paper stuff, with more upfront formatting and
% fewer exploratory analyses

%% Process raw jspsych text file data
clear all

addpath(genpath('plotting/'))
addpath('modeling/HBI/')
addpath('modeling/')
addpath(genpath('data_loading_and_scoring/'))

%if isdir('data')
if isdir('data')
    % ALL experimental data, all 100 subjects live in 'data'
    load('data/filenames.mat')
    prefix = 'data/';
    % grab all subjects from those files, then
elseif isdir('example_data')
    files{1} = 'example_data/example_subjs.mat';
    prefix = 'example_data/';
end
% version 4
[data,excluded] = load_cost_data(files); %load data in
n = height(data);

tasks = [categorical(cellstr('detection'));categorical(cellstr('n1')); categorical(cellstr('ndetection')); categorical(cellstr('n2'))];
tasklabels = {'1-detect','1-back','3-detect','2-back'};
tasknumbers = [0,1,7,2];
default_length = 32;

inattentive = data.perf<60;

% save important variables for later
for subj = 1:n
    for task = 1:length(tasks)
        list = find(data.task_progression(subj,:)==tasks(task));
        tasks_overall(subj,task) = nanmean(data.perf(subj,list));
    end
end
tasks_rts = [nanmean(data.detectrts,2) nanmean(data.n1rts,2) nanmean(data.ndetectrts,2) nanmean(data.n2rts,2)];
data.taskfreqs = [sum(data.task_progression==tasks(1),2) sum(data.task_progression==tasks(2),2) sum(data.task_progression==tasks(3),2) sum(data.task_progression==tasks(4),2)];
meanBDM = nanmean(data.values(:,2:end),2);

%display variables
subjcolors = rand(n);subjcolors(:,4:end) = []; %delete unnecessary columns
taskcolors = [0.75 0.75 0.75;0 0.75 0.75; 0.75 0.75 0; 0.75 0 0.75];
%style variables
NFCcolors = [.25 0 .25; .60 0 .60; .95 0 .95];
SAPScolors = [0 .25 .25; 0 .5 .5; 0 .75 .75];
modelcolors = [1 0 0; 1 0.5 0; 1 0 0.5; 0 0 1; 0 0.5 1; 0 0.7 0; 1 1 0];

list = data.subjnum;
save([prefix 'fullsubjnumbers.mat'],'list');

% Initial print-outs of demographics, etc., for beginning of methods
% section

disp(['Sample of ' num2str(n) ' subjects (' num2str(sum(data.sex==2)) ' female). Mean(std) age: ' num2str(nanmean(data.age)) '(' num2str(nanstd(data.age)) ')'])
disp(['Unspecified sex n: ' num2str(sum(isnan(data.sex))) '; unspecified age: ' num2str(sum(isnan(data.age)))])
disp(['Mean total TOT: ' num2str(nanmean(data.totalTOT)) ', median total TOT: ' num2str(median(data.totalTOT))])
% REMINDER OF TASK ORDERS in VARIABLES %
%tasks = [detection,n1,3detection,n2];

extra_flag = false;

% turn on if you want to run a BUNCH of extra analyses
% (don't recommend, if you have extra questions, you should open
% run_supplementary_analyses and run it cell-by-cell according to what
% you're interested in seeing)

if extra_flag
    run_supplementary_analyses()
end

%% Many ANOVAs, and post-hoc t-tests

% % STATS ON ACCURACY, MEAN RT, and DIFFICULTY RATINGS
% COMPARE MEAN ACCURACY BY TASK %
clear vector; vector = tasks_overall(:); taskidentity = [ones(n,1); 2*ones(n,1); 3*ones(n,1); 4*ones(n,1)];
[~,~,stats] = anovan(vector,taskidentity);
%tasks = [detection,n1,3detection,n2];
Table1 = table; Table1.onedetect = nanmean(vector(taskidentity==1)); Table1.oneback = nanmean(vector(taskidentity==2));
Table1.threedetect = nanmean(vector(taskidentity==3)); Table1.twoback = nanmean(vector(taskidentity==4));
Table1.Properties.RowNames{1} = 'Accuracy';
[h,p] = ttest(vector(taskidentity==1),vector(taskidentity==2));
p_mat = NaN(3,3); p_mat(1,2) = p; p_mat(2,1) = p;
[h,p] = ttest(vector(taskidentity==4),vector(taskidentity==2));
p_mat(2,4) = p; p_mat(4,2) = p;
[h,p] = ttest(vector(taskidentity==1),vector(taskidentity==3));
p_mat(1,3) = p; p_mat(3,1) = p;
[h,p] = ttest(vector(taskidentity==1),vector(taskidentity==4));
p_mat(1,4) = p; p_mat(4,1) = p;
[h,p] = ttest(vector(taskidentity==3),vector(taskidentity==2));
p_mat(3,2) = p; p_mat(2,3) = p;
[h,p] = ttest(vector(taskidentity==3),vector(taskidentity==4));
p_mat(3,4) = p; p_mat(4,3) = p;

% COMPARE MEAN RTs ON TASK %
clear vector; vector = tasks_rts(:);
[~,~,stats] = anovan(vector,taskidentity,'display','off');
%tasks = [detection,n1,3detection,n2];
temp = table; temp.onedetect = nanmean(vector(taskidentity==1)); temp.oneback = nanmean(vector(taskidentity==2));
temp.threedetect = nanmean(vector(taskidentity==3)); temp.twoback = nanmean(vector(taskidentity==4));
Table1 = [Table1; temp]; Table1.Properties.RowNames{2} = 'RT (msec)';
[h,p] = ttest(vector(taskidentity==1),vector(taskidentity==2));
[h,p] = ttest(vector(taskidentity==4),vector(taskidentity==2));
[h,p] = ttest(vector(taskidentity==1),vector(taskidentity==3));
[h,p] = ttest(vector(taskidentity==1),vector(taskidentity==4));
[h,p] = ttest(vector(taskidentity==3),vector(taskidentity==2));
[h,p] = ttest(vector(taskidentity==3),vector(taskidentity==4));

% COMPARE DIFFICULTY RATINGS FROM END OF TASK %
clear vector; vector = data.taskratings(:);
[~,~,stats] = anovan(vector,taskidentity,'display','off');
%tasks = [detection,n1,n2,3detection];
temp = table; temp.onedetect = nanmean(vector(taskidentity==1)); temp.oneback = nanmean(vector(taskidentity==2));
temp.threedetect = nanmean(vector(taskidentity==3)); temp.twoback = nanmean(vector(taskidentity==4));
Table1 = [Table1; temp]; Table1.Properties.RowNames{3} = 'Difficulty';
[h,p] = ttest(vector(taskidentity==1),vector(taskidentity==2));
[h,p] = ttest(vector(taskidentity==4),vector(taskidentity==2));
[h,p] = ttest(vector(taskidentity==1),vector(taskidentity==3));
[h,p] = ttest(vector(taskidentity==1),vector(taskidentity==4));
[h,p] = ttest(vector(taskidentity==3),vector(taskidentity==2));
[h,p] = ttest(vector(taskidentity==3),vector(taskidentity==4));

% COMPARE MEAN BDM RATINGS %
n1 = data.task_displayed==tasknumbers(2); %1
n2 = data.task_displayed==tasknumbers(4); %2
ndetect = data.task_displayed==tasknumbers(3); %7

temp = table; temp.onedetect = NaN; temp.oneback = nanmean(data.values(n1));
temp.threedetect = nanmean(data.values(ndetect)); temp.twoback = nanmean(data.values(n2));
Table1 = [Table1; temp]; Table1.Properties.RowNames{4} = 'Fair wage';
p_mat_BDM = NaN(3,3);
[h,p] = ttest2(data.values(n1),data.values(n2));
disp (['t-test 1-back versus 2-back BDM values p = ' num2str(p)]);
p_mat_BDM(1,3) = p; p_mat_BDM(3,1) = p;
[h,p] = ttest2(data.values(ndetect),data.values(n2));
disp (['t-test 2-back versus 3-detect BDM values p = ' num2str(p)]); %task 2 values versus task 3 values
p_mat_BDM(3,2) = p; p_mat_BDM(2,3) = p;
[h,p] = ttest2(data.values(n1),data.values(ndetect));
disp (['t-test 1-back versus 3-detect BDM values p = ' num2str(p)]); %task 1 values versus task 3 values
p_mat_BDM(1,2) = p; p_mat_BDM(2,1) = p;
% basically it's task 2 versus the world

% PULL A BUNCH OF INFORMATION BY TASK ITERATION
% FOR EXAMPLE, FAIR WAGE BY TASK ITERATION
n0subjlearning = NaN(n,default_length+1); n0subjvalue = NaN(n,default_length+1); n0subjrt = NaN(n,default_length+1);
n1subjlearning = NaN(n,default_length+1); n2subjlearning = NaN(n,default_length+1); n3subjlearning = NaN(n,default_length+1);
n1subjrt = NaN(n,default_length+1); n2subjrt = NaN(n,default_length+1); n3subjrt = NaN(n,default_length+1);
for row = 1:n %cycle through subjects
    for task = 1:4 %cycle through tasks
        for trial = 2:default_length
            iters = sum(data.task_progression(row,1:(trial-1)) == tasks(task))+1;
            if data.task_progression(row,trial) == tasks(task)
                eval(['n' num2str(task-1) 'subjlearning(row,iters) = data.perf(row,trial);'])
                eval(['n' num2str(task-1) 'subjrt(row,iters) = data.BDMrt(row,trial);'])
            end
        end
    end
end

n1subjvalue = []; n2subjvalue = []; n3subjvalue = [];
for task = 1:3
    for subj = 1:n
        BDM = data.values(subj,:);
        curve = NaN(1,11);
        curve(1:sum(data.task_displayed(subj,:)==tasknumbers(task+1))) = BDM(data.task_displayed(subj,:)==tasknumbers(task+1));
        eval(['n' num2str(task) 'subjvalue = [n' num2str(task) 'subjvalue; curve];'])
    end
end


% More analyses of task iteration by reaction times, accuracy, and fair
% wages

% What's the relationship of fair wage and accuracy?
meanBDM = [nanmean(n1subjvalue,2) nanmean(n2subjvalue,2) nanmean(n3subjvalue,2)];
meanAcc = tasks_overall(:,2:4);
tocorr = [meanBDM meanAcc];
tocorr = tocorr(sum(isnan(tocorr),2)<1,:);

[r,p] = corr(tocorr(:,1),tocorr(:,4)) %1-back
[r,p] = corr(tocorr(:,2),tocorr(:,5)) %3-detect
[r,p] = corr(tocorr(:,3),tocorr(:,6)) %2-back

% % BDM RT STUFF % %
% are people getting more decisive on how many BDM points they want?
big_matrix = [];
for task = 1:(length(unique(data.task_displayed(~isnan(data.task_displayed)))))
    matrix = [];
    for subj = 1:n
        eval(['rts = n' num2str(task) 'subjrt(subj,:);'])
        display = data.task_displayed(subj,:);
        init = NaN(1,default_length);
        init(~isnan(rts)) = rts(~isnan(rts));
        matrix = [matrix; init];
    end
    big_matrix = [big_matrix; matrix]; % task agnostic measure of rt by task iteration
    %errorbar(nanmean(matrix),nanstd(matrix)/sqrt(n),'Color',taskcolors(task+1,:),'LineWidth',1.5)
    %hold on
end
%title('BDM RT by iteration by task displayed')

[h,p] = ttest2(big_matrix(:,1),big_matrix(:,5)); %choosing iter 1 versus iter 5
disp(['t-test iter 1 rts vs iter 5 rts p = ' num2str(p)])
[h,p] = ttest2(data.BDMrt(:,1),data.BDMrt(:,31));
disp(['t-test block 1 rts vs block 31 rts p = ' num2str(p)])

% correlate block # (out of 32) with perf measures
blockbyperf_mat = [reshape(data.perf',n*32,1) repmat([1:32]',n,1)];
blockbyperf_mat(isnan(blockbyperf_mat),:) = [];
[r,p] = corr(blockbyperf_mat(:,1),blockbyperf_mat(:,2));
disp(['Relationship round number/accuracy p = ' num2str(p)])
clear blockbyperf_mat;
blockbyperf_mat = [reshape(data.meanRTs',n*32,1) repmat([1:32]',n,1)];
blockbyperf_mat(isnan(blockbyperf_mat),:) = [];
[r,p] = corr(blockbyperf_mat(:,1),blockbyperf_mat(:,2));
disp(['Relationship round number/mean RTs p = ' num2str(p)])

%% FIGURE #2 IN MANUSCRIPT

% (Plot the numbers which the above stats are checking for significance)

% % MEAN ACCURACY BY TASK % %
figure
subplot(2,2,1)
fig = gcf; fig.Color = 'w';
errorbar(1:length(tasklabels),[nanmean(tasks_overall(:,1)) nanmean(tasks_overall(:,2)) nanmean(tasks_overall(:,3)) nanmean(tasks_overall(:,4))],[nanstd(tasks_overall(:,1)) nanstd(tasks_overall(:,2)) nanstd(tasks_overall(:,3)) nanstd(tasks_overall(:,4))]/sqrt(n),'k','LineWidth',1.25)
hold on
violin([nanmean(tasks_overall(:,1)) nanmean(tasks_overall(:,2)) nanmean(tasks_overall(:,3)) nanmean(tasks_overall(:,4))],'facecolor',[taskcolors(1,:);taskcolors(2,:);taskcolors(3,:);taskcolors(4,:)],'medc','','mc','')
%superbar(1:length(tasklabels),[nanmean(tasks_overall(:,1)) nanmean(tasks_overall(:,2)) nanmean(tasks_overall(:,3)) nanmean(tasks_overall(:,4))],'BarFaceColor','none','BarEdgeColor','none','P',p_mat)
legend('off')
xticks(1:length(tasklabels))
xticklabels(tasklabels)
%xtickangle(45)
xlabel('Task')
ylim([70 100]); xlim([0.5 4.5])
ylabel('Mean accuracy')
ax = gca; ax.FontSize = 14;

% % MEAN FAIR WAGE BY TASK % %
subplot(2,2,2)
dotsize = 5;
scatter(ones(n,1),nanmean(n1subjvalue,2),dotsize*ones(n,1),taskcolors(2,:),'filled','DisplayName','1-back')
hold on
scatter(2*ones(n,1),nanmean(n2subjvalue,2),dotsize*ones(n,1),taskcolors(3,:),'filled','DisplayName','3-detect')
scatter(3*ones(n,1),nanmean(n3subjvalue,2),dotsize*ones(n,1),taskcolors(4,:),'filled','DisplayName','2-back')
%overlay group means
errorbar([nanmean(data.values(n1)) nanmean(data.values(ndetect)) nanmean(data.values(n2))],[nanstd(data.values(n1)) nanstd(data.values(ndetect)) nanstd(data.values(n2))]./sqrt(n),'k','LineWidth',1.25)
superbar(1:3,[nanmean(data.values(n1)) nanmean(data.values(ndetect)) nanmean(data.values(n2))]+1,'BarFaceColor','none','BarEdgeColor','none','P',p_mat_BDM,...
    'PStarOffset',0.2,'PStarShowGT',false)
%xlim([0.75 3.25])
ylim([1 8])

violin([nanmean(n1subjvalue,2) nanmean(n2subjvalue,2) nanmean(n3subjvalue,2)],'facecolor',[taskcolors(2,:);taskcolors(3,:);taskcolors(4,:)],'medc','','mc','')
xticks(1:(length(tasklabels)-1))
xticklabels(tasklabels(2:end))
ylabel('Mean fair wage')
xlabel('Task')
legend('off')
ax = gca; ax.FontSize = 14;

% % ACCURACY BY TASK ITERATION % %
scaling = 1;
subplot(2,2,3)
errorbar(nanmean(n0subjlearning(:,1:11)),nanstd(n0subjlearning(:,1:11))/sqrt(n),'Color',taskcolors(1,:),'LineWidth',1.25,'DisplayName',tasklabels{1})
hold on
n0points = sum(~isnan(n0subjlearning(:,1:11)));
errorbar(nanmean(n1subjlearning),nanstd(n1subjlearning)/sqrt(n),'Color',taskcolors(2,:),'LineWidth',1.25,'DisplayName',tasklabels{2})
n1points = sum(~isnan(n1subjlearning(:,1:10)));
errorbar(nanmean(n2subjlearning),nanstd(n2subjlearning)/sqrt(n),'Color',taskcolors(3,:),'LineWidth',1.25,'DisplayName',tasklabels{3})
n2points = sum(~isnan(n2subjlearning(:,1:11)));
errorbar(nanmean(n3subjlearning),nanstd(n3subjlearning)/sqrt(n),'Color',taskcolors(4,:),'LineWidth',1.25,'DisplayName',tasklabels{4}) %task 3 is actually ndetect
n3points = sum(~isnan(n3subjlearning(:,1:11)));
n1points(n1points==0) = NaN; % in example data, there's a small bug in creating the size of the dots
n2points(n2points==0) = NaN; % so I'm patching 0's with NaN's

% Plot overlay which depicts # of data points in each bar
scatter(1:11,nanmean(n0subjlearning(:,1:11)),n0points*scaling,taskcolors(1,:),'Filled')
scatter(1:10,nanmean(n1subjlearning(:,1:10)),n1points*scaling,taskcolors(2,:),'Filled')
scatter(1:11,nanmean(n2subjlearning(:,1:11)),n2points*scaling,taskcolors(3,:),'Filled')
scatter(1:11,nanmean(n3subjlearning(:,1:11)),n3points*scaling,taskcolors(4,:),'Filled')
legend(tasklabels)
legend('boxoff')
xlim([0.5 11.5])
fig = gcf; ax = gca;
fig.Color = 'w'; ax.FontSize = 14;
ylabel('Accuracy')
xlabel('Iteration #')

% run an ANOVA on task accuracy with iteration as a factor
n1subjlearning = n1subjlearning(:,1:10); n2subjlearning = n2subjlearning(:,1:10); n3subjlearning = n3subjlearning(:,1:10);
vector = [n1subjlearning(:);n2subjlearning(:);n3subjlearning(:)];
taskidentity = [ones(length(n1subjlearning(:)),1);2*ones(length(n2subjlearning(:)),1);3*ones(length(n3subjlearning(:)),1)];
iternum = repmat([1 2 3 4 5 6 7 8 9 10],n*3,1);
[~,~,stats] = anovan(vector,[taskidentity iternum(:)],'display','off');

% % FAIR WAGE BY TASK ITERATION % %
subplot(2,2,4)
errorbar(nanmean(n1subjvalue),nanstd(n1subjvalue)./sqrt(n),'Color',taskcolors(2,:),'LineWidth',1.25,'DisplayName',tasklabels{2})
hold on
errorbar(nanmean(n2subjvalue),nanstd(n2subjvalue)./sqrt(n),'Color',taskcolors(3,:),'LineWidth',1.25,'DisplayName',tasklabels{3})
errorbar(nanmean(n3subjvalue),nanstd(n3subjvalue)./sqrt(n),'Color',taskcolors(4,:),'LineWidth',1.25,'DisplayName',tasklabels{4})
ylabel('Fair wage')
legend('boxoff')
xlabel('Iteration #')
xlim([0.5 11.5])
ax = gca; ax.FontSize = 14;

% test effect of iteration on BDM rating, run 2-way anova on iteration and
% task
n1subjvalue = n1subjvalue(:,1:10); n2subjvalue = n2subjvalue(:,1:10); n3subjvalue = n3subjvalue(:,1:10);
vector = [n1subjvalue(:);n2subjvalue(:);n3subjvalue(:)];
taskidentity = [ones(length(n1subjvalue(:)),1);2*ones(length(n2subjvalue(:)),1);3*ones(length(n3subjvalue(:)),1)];
iternum = repmat([1 2 3 4 5 6 7 8 9 10],n*3,1);
[~,~,stats] = anovan(vector,[taskidentity iternum(:)]);


% An interesting supplementary plot showing that:
% % subjects are RELATIVELY STABLE IN THEIR BDMs % %
% this speaks to the relationship between BDM & task iteration being more
% stationary than would be assumed from the group means, as plotted %

% subplot(2,2,4)
% for task = 4 %grab 2-back specifically
%     rating_idx = data.task_displayed==tasknumbers(task);
%     eval(['ratings = n' num2str(task-1) 'subjvalue;'])
%     hold on
%     eval(['completions = sum(~isnan(n' num2str(task-1) 'subjlearning),2);'])
%     ratings = [completions ratings]; ratings = sortrows(ratings,1);
%     n_rounds = unique(completions);
%     for i = 1:length(n_rounds)
%         tomean = ratings(ratings(:,1)==n_rounds(i),2:end);
%         toplot = nanmean(tomean,1);
%         errorbar(toplot,nanstd(tomean,[],1)./sqrt(size(tomean,1)),'Color',taskcolors(task,:))
%         hold on
%     end
%     xlabel('# task iters completed')
%     ylabel('Mean BDM rating')
%     title([tasklabels{task} ' ratings by completed iterations'])
% end
% fig = gcf; fig.Color = 'w';
% xlim([0 11])

% END FIGURE 2

%% modeling results (parameters) 
% % BEGIN FIGURE 3 % % 

modelfits = load('modeling/HBI/HBI_modelStruct.mat');
no_fits = load([prefix 'toanalyze.mat'],'trim'); no_fits = no_fits.trim;
% remove subjects who weren't fit to models
% grab best model

best_model = modelfits.modelStruct.best_model;
cbm = best_model.cbm;

freqs = cbm.output.model_frequency;
models_at_play = find(freqs>0.01);
[~,assignments] = max(cbm.output.responsibility,[],2);

disp([num2str(sum(assignments>4)) ' subjects best explained by a model with more than 1 cost'])

full_labels = modelfits.modelStruct.best_model.overallfit.fitmodels;
model_labels = cell(length(full_labels),1);
for ll = 1:length(full_labels)
    % trim model labels down to just the cost labels
    temp_label = strsplit(full_labels{ll},'epsilon-initi-alpha-');
    if length(temp_label) == 1
        temp_label = strsplit(full_labels{ll},'epsilon-initi-');
        % indicate that it's a delta cost model
    end
    just_costs = temp_label{2};
    trim = strsplit(just_costs,'c');
    new_name = ['c_{' trim{1} '}'];
    
    if length(trim)>2
        for ii = 2:(length(trim)-1)
            new_name = [new_name ' & ' strrep(trim{ii},'-','c_{')];
            new_name = [new_name '}'];
        end
    end
    
    if strmatch(new_name,'c_lure')
        % calling this the "interference cost" in the actual paper
        new_name = 'c_interference';
    end
    
    model_labels{ll} = new_name;
end


nparams = best_model.nparams;
params = applyTrans_parameters(best_model,best_model.lowparams); paramnames = best_model.paramnames;

%% Look at parameter trends within subjects whose best model was the winning
% model w exceedance probability = 1
% FIGURE 3 CONTINUED

all_params = cbm.output.parameters;

figure
%At the top, plot each model frequency.
subplot(1,3,1)
%     for mm = 1:length(models_at_play)
%         bar(mm,freqs(models_at_play(mm)),'FaceColor',modelcolors(mm,:))
%         hold on
%     end
%     ylabel('Model frequencies')
for mm = 1:length(models_at_play)
    bar(mm,sum(assignments==models_at_play(mm)),'FaceColor',modelcolors(mm,:))
    hold on
end
ylabel('# subjects best fit by model')
xticks(1:mm)
xticklabels(model_labels(models_at_play));xtickangle(45)
ax = gca; ax.FontSize = 14;
fig = gcf; fig.Color = 'w';

calcflag = false;

if calcflag
    cd('modeling/HBI/')
    [big_posterior,joint,xs] = get_param_posterior_dists(best_model);
    cd('../../')
else
    load('modeling/HBI/joint_cost_distributions.mat')
end

% feed model fits in, also specify whether you want to recalculate the
% dists (takes some time, lots of numbers to compute)

% Now I have a joint distribution over 3 cost parameters of interest

% so then, if you have subjects s _1...s_k in your low tertile group (say),
% you can work out the approximate posterior distribution
%
% P(Theta ; low_tertile) =
%    \prod_{i=1}^k \sum_j [\rho^{s_i}_j P(Theta^{s_i}_j|D^{s_i})*P(Theta_{j'})]
%
% in the low_tertile [in practice you should calculate it carefully using
% logs - in the three dimensions of maintenance, lure and false-alarm costs

% Plot distributions of mainc, lurec, and fac,
%to compare their distributions to one another.

modelstofit = best_model.overallfit.fitmodels;

dim1 = logsumexp(big_posterior,1);
dim2 = logsumexp(dim1,2);
dim3 = logsumexp(dim2,3);
big_posterior = big_posterior - dim3;
% normalize to make sure it's a real posterior
big_posterior = exp(big_posterior);

mainc_dist = sum(sum(big_posterior,1),3);
lurec_dist = squeeze(sum(sum(big_posterior,2),3));
fac_dist = squeeze(sum(sum(big_posterior,2),1));

subplot(1,3,2); hold on;
plot(xs',fac_dist,'Color',modelcolors(3,:),'LineWidth',1.5,'DisplayName','False Alarm')
plot(xs',mainc_dist,'Color',modelcolors(1,:),'LineWidth',1.5,'DisplayName','Maintenance')
plot(xs',lurec_dist,'Color',modelcolors(2,:),'LineWidth',1.5,'DisplayName','Interference')
legend('Location','Best')
ylabel('Posterior probability')
xlabel('Parameter value')
xlim([0 1.15])
fig = gcf; ax = gca;
fig.Color = 'w'; ax.FontSize = 14;

subplot(1,3,3);
% model validation plot
make_model_validation_subplot()

group_level_means_sarah(1) = sum(xs.*mainc_dist);
group_level_means_sarah(2) = sum(xs'.*lurec_dist);
group_level_means_sarah(3) = sum(xs'.*fac_dist);

model = coc_createModels(modelstofit{1});
idx_cost = find(contains(model.paramnames,'mainc'));
group_level_means_payam(1) = best_model.cbm.output.group_mean{1}(idx_cost);

model = coc_createModels(modelstofit{2});
idx_cost = find(contains(model.paramnames,'lurec'));
group_level_means_payam(2) = best_model.cbm.output.group_mean{2}(idx_cost);

model = coc_createModels(modelstofit{4});
idx_cost = contains(model.paramnames,'fac');
group_level_means_payam(3) = best_model.cbm.output.group_mean{4}(idx_cost);

disp('Your means are: ')
disp(group_level_means_sarah)
disp('The means from the HBI package are: ')
disp(group_level_means_payam)


%% BEGIN SUPPLEMENTARY FIGURE 1
% Individual differences measures, as measured by questionnaires.
% Their spread (histograms) and relationship to each other (scatter plots).
% Primarily examining Need for Cognition (NFC) and Short Almost Perfect
% Scale (SAPS) scores.

measures = [data.NFC data.SAPS];
measures(sum(isnan(measures),2)>1,:) = [];
agemeasures = [data.NFC data.SAPS data.age];
ages = agemeasures(sum(isnan(agemeasures),2)==0,:);
disp(['Mean(std) NFC = ' num2str(nanmean(data.NFC)) '(' num2str(nanstd(data.NFC)) '); mean(std) SAPS = ' num2str(nanmean(data.SAPS)) '(' num2str(nanstd(data.SAPS)) ')'])
disp(['Missing ' num2str(sum(isnan(data.NFC))) ' NFC; missing ' num2str(sum(isnan(data.SAPS))) ' SAPS.'])
[r,p] = corr(measures(:,1),measures(:,2));
disp(['Corr NFC/SAPS r = ' num2str(r) '; p = ' num2str(p)])
[r,p] = corr(ages(:,1),ages(:,3));
disp(['Corr NFC/age r = ' num2str(r) '; p = ' num2str(p)])
[r,p] = corr(ages(:,2),ages(:,3));
disp(['Corr SAPS/age r = ' num2str(r) '; p = ' num2str(p)])

% PLOT DISTRIBUTIONS
figure
subplot(2,3,1)
histogram(data.NFC,[1 2 3 4 5])
xlabel('Score'); ylabel('# subjects')
title('Distribution of NFC')
ax = gca; ax.FontSize = 14;
subplot(2,3,2)
histogram(data.SAPS,[1 2 3 4 5 6 7])
xlabel('Score'); ylabel('# subjects')
title('Distribution of SAPS')
fig = gcf; fig.Color = 'w';
ax = gca; ax.FontSize = 14;
subplot(2,3,3)
scatter(data.NFC,data.SAPS,'Filled')
lsline
ylabel('SAPS score')
xlabel('NFC score')
xlim([1 5]); ylim([1 7])
ax = gca; ax.FontSize = 14;

% More stats %
% % LINEAR RELATIONSHIPS OF NFC/SAPS and ACCURACY/MEAN RTs/DIFF
% RATINGS/BDMs
names = {'NFC','SAPS'};
measures = [data.NFC data.SAPS];
trim = [measures tasks_overall tasks_rts data.taskratings];
trim(sum(isnan(trim),2)>0,:) = [];
BDMs = data.values(sum(isnan(trim),2)==0,:); taskBDMs = [];
task_by_round{1} = n1(sum(isnan(trim),2)==0,:); task_by_round{2} = ndetect(sum(isnan(trim),2)==0,:); task_by_round{3} = n2(sum(isnan(trim),2)==0,:);
for subj = 1:size(BDMs,1)
    taskBDMs = [taskBDMs; nanmean(BDMs(subj,task_by_round{1}(subj,:))) nanmean(BDMs(subj,task_by_round{2}(subj,:))) nanmean(BDMs(subj,task_by_round{3}(subj,:)))];
end

for m = 1:2
    % ACCURACY CORRs
    [r,p] = corr(trim(:,m),nanmean(trim(:,3:6),2));
    disp(['Relationship of ' names{m} ' and overall acc: r = ' num2str(r) '; p = ' num2str(p)])
    [r,p] = corr(trim(:,m),trim(:,3));
    disp(['Relationship of ' names{m} ' and 1-detect acc: r = ' num2str(r) '; p = ' num2str(p)])
    [r,p] = corr(trim(:,m),trim(:,4));
    disp(['Relationship of ' names{m} ' and 1-back acc: r = ' num2str(r) '; p = ' num2str(p)])
    [r,p] = corr(trim(:,m),trim(:,5));
    disp(['Relationship of ' names{m} ' and 3-detect acc: r = ' num2str(r) '; p = ' num2str(p)])
    [r,p] = corr(trim(:,m),trim(:,6));
    disp(['Relationship of ' names{m} ' and 2-back acc: r = ' num2str(r) '; p = ' num2str(p)])
    disp('. . .')
    % RT CORRs
    [r,p] = corr(trim(:,m),nanmean(trim(:,7:10),2));
    disp(['Relationship of ' names{m} ' and overall RT: r = ' num2str(r) '; p = ' num2str(p)])
    [r,p] = corr(trim(:,m),trim(:,7));
    disp(['Relationship of ' names{m} ' and 1-detect RT: r = ' num2str(r) '; p = ' num2str(p)])
    [r,p] = corr(trim(:,m),trim(:,8));
    disp(['Relationship of ' names{m} ' and 1-back RT: r = ' num2str(r) '; p = ' num2str(p)])
    [r,p] = corr(trim(:,m),trim(:,9));
    disp(['Relationship of ' names{m} ' and 3-detect RT: r = ' num2str(r) '; p = ' num2str(p)])
    [r,p] = corr(trim(:,m),trim(:,10));
    disp(['Relationship of ' names{m} ' and 2-back RT: r = ' num2str(r) '; p = ' num2str(p)])
    disp('. . .')
    % DIFF RATINGS
    [r,p] = corr(trim(:,m),nanmean(trim(:,11:14),2));
    disp(['Relationship of ' names{m} ' and overall rating: r = ' num2str(r) '; p = ' num2str(p)])
    [r,p] = corr(trim(:,m),trim(:,11));
    disp(['Relationship of ' names{m} ' and 1-detect rating: r = ' num2str(r) '; p = ' num2str(p)])
    [r,p] = corr(trim(:,m),trim(:,12));
    disp(['Relationship of ' names{m} ' and 1-back rating: r = ' num2str(r) '; p = ' num2str(p)])
    [r,p] = corr(trim(:,m),trim(:,13));
    disp(['Relationship of ' names{m} ' and 3-detect rating: r = ' num2str(r) '; p = ' num2str(p)])
    [r,p] = corr(trim(:,m),trim(:,14));
    disp(['Relationship of ' names{m} ' and 2-back rating: r = ' num2str(r) '; p = ' num2str(p)])
    disp('. . .')
    % MEAN BDMs
    [r,p] = corr(trim(:,m),nanmean(BDMs,2));
    disp(['Relationship of ' names{m} ' and mean BDM rating: r = ' num2str(r) '; p = ' num2str(p)])
    [r,p] = corr(trim(:,m),taskBDMs(:,1));
    disp(['Relationship of ' names{m} ' and 1-back BDM rating: r = ' num2str(r) '; p = ' num2str(p)])
    [r,p] = corr(trim(:,m),taskBDMs(:,2));
    disp(['Relationship of ' names{m} ' and 3-detect BDM rating: r = ' num2str(r) '; p = ' num2str(p)])
    [r,p] = corr(trim(:,m),taskBDMs(:,3));
    disp(['Relationship of ' names{m} ' and 2-back BDM rating: r = ' num2str(r) '; p = ' num2str(p)])
    disp('. . .')
end


%% % GROUP ANALYSIS OF BDMS by NFC AND SAPS GROUPS % %
% SUPPLEMENTARY ANALYSES CONTINUED!
% THESE ARE NOT INCLUDED IN SUPPLEMENTARY FIGURES IN THE MANUSCRIPT

measures = [data.NFC data.SAPS];
labels = {'NFC','SAPS'};
for measure = 1:2
    split = tertile_split(measures(:,measure));
    disp([labels{measure} ' group Ns: ' num2str([sum(split==1) sum(split==2) sum(split==3)])])
    if measure == 1
        colors = NFCcolors;
    else
        colors = SAPScolors;
    end
    subplot(2,2,2+measure)
    lowNFCvalues = data.values(split==1,:);
    midNFCvalues = data.values(split==2,:);
    highNFCvalues = data.values(split==3,:);
    errorbar([nanmean(lowNFCvalues(n1(split==1,:))) nanmean(lowNFCvalues(ndetect(split==1,:))) nanmean(lowNFCvalues(n2(split==1,:)))],[nanstd(lowNFCvalues(n1(split==1,:))) nanstd(lowNFCvalues(ndetect(split==1,:))) nanstd(lowNFCvalues(n2(split==1,:)))]/sqrt(sum(split==1)),'Color',colors(1,:),'Linewidth',1.5)
    hold on
    errorbar([nanmean(midNFCvalues(n1(split==2,:))) nanmean(midNFCvalues(ndetect(split==2,:))) nanmean(midNFCvalues(n2(split==2,:)))],[nanstd(midNFCvalues(n1(split==2,:))) nanstd(midNFCvalues(ndetect(split==2,:))) nanstd(midNFCvalues(n2(split==2,:)))]/sqrt(sum(split==2)),'Color',colors(2,:),'Linewidth',1.5)
    errorbar([nanmean(highNFCvalues(n1(split==3,:))) nanmean(highNFCvalues(ndetect(split==3,:))) nanmean(highNFCvalues(n2(split==3,:)))],[nanstd(highNFCvalues(n1(split==3,:))) nanstd(highNFCvalues(ndetect(split==3,:))) nanstd(highNFCvalues(n2(split==3,:)))]/sqrt(sum(split==3)),'Color',colors(3,:),'Linewidth',1.5)
    legend(['Low ' labels{measure}],['Mid ' labels{measure}],['High ' labels{measure}],'Location','Best')
    title(['Mean Fair Wage by ' labels{measure} ' group'])
    ylabel('Wage')
    xlabel('Task')
    xticklabels(tasklabels(2:end))
    xticks([1:3])
    xlim([0.5 3.5])
    ax = gca; ax.FontSize = 14;
    
    tasklist = [repmat(1,n,1); repmat(2,n,1); repmat(3,n,1)];
    ratings = [nanmean(n1subjvalue,2); nanmean(n3subjvalue,2); nanmean(n2subjvalue,2)];
    matrix = [ratings repmat(split,3,1) tasklist];
    [~,~,stats] = anovan(matrix(:,1),{matrix(:,2),matrix(:,3)},'model','interaction','varnames',{labels{measure},'task'});
    
end

% % regress mean BDM values by SAPS and NFC, and quadratic terms on them,
% too % %
Y = nanmean(data.values,2);
X = [ones(n,1) data.NFC data.SAPS data.NFC.^2 data.SAPS.^2];
invalid = sum(isnan(X),2)>0; Y(invalid,:) = []; X(invalid,:) = [];

[betas,BINT,~,~,stats] = regress(Y,X);
% get betas for quadratic term
predicted = X*betas;
distance = predicted-Y;
MSE = distance'*distance; %squared distance
%disp(['betas on intercept, NFC, SAPS, NFC^2, and SAPS^2: ' num2str(betas') ', p = ' num2str(stats(3)), ', MSE = ' num2str(MSE)])
% The only real term here is the intercept

%Examine individual NFC group differences post-ANOVA main effect
split = tertile_split(data.NFC);
lowNFCvalues = data.values(split==1,:);midNFCvalues = data.values(split==2,:);highNFCvalues = data.values(split==3,:);
low = nanmean(lowNFCvalues,2); mid = nanmean(midNFCvalues,2); high = nanmean(highNFCvalues,2);
[h,p] = ttest2(low,mid);
disp(['Mid versus low NFC fair wage ratings: p = ' num2str(p)])
[h,p] = ttest2(high,low);
disp(['High versus low NFC fair wage ratings: p = ' num2str(p)])
[h,p] = ttest2(mid,high);
disp(['Mid versus high NFC fair wage ratings: p = ' num2str(p)])

%Do individual differences relate to baseline executive function?
%0-detect, 3-detect, 1-back, 2-back (in that order in practice)
meanpracaccs = nanmean(data.practiceacc,2);
[r,p] = corr(meanpracaccs(~isnan(data.NFC)),data.NFC(~isnan(data.NFC)));
disp(['Relationship of overall practice accuracy & NFC r = ' num2str(r) ', p = ' num2str(p)])
[r,p] = corr(meanpracaccs(~isnan(data.SAPS)),data.SAPS(~isnan(data.SAPS)));
disp(['Relationship of overall practice accuracy & SAPS r = ' num2str(r) ', p = ' num2str(p)])
practiceaccs = data.practiceacc(:,1:4);
matrix = [practiceaccs(:) [ones(n,1); repmat(2,n,1); repmat(3,n,1); repmat(4,n,1)] repmat(split,4,1)];
[~,~,stats] = anovan(matrix(:,1),{matrix(:,2),matrix(:,3)},'model','interaction','varnames',{'task','NFC'},'display','off');

%From that main effect of NFC on practice accuracy, run some post-hoc tests
%of NFC groups & practice accuracy
[h,p] = ttest2(practiceaccs(split==1,:),practiceaccs(split==2,:))
disp('t-test low vs mid NFC in practice rounds 1-4')
[h,p] = ttest2(practiceaccs(split==2,:),practiceaccs(split==3,:))
disp('t-test mid vs high NFC in practice rounds 1-4')
[h,p] = ttest2(practiceaccs(split==1,:),practiceaccs(split==3,:))
disp('t-test low vs high NFC in practice rounds 1-4')

%Does this difference persist into the actual experiment?
matrix = [tasks_overall(:) [ones(n,1); repmat(2,n,1); repmat(3,n,1); repmat(4,n,1)] repmat(split,4,1)];
[~,~,stats] = anovan(matrix(:,1),{matrix(:,2),matrix(:,3)},'model','interaction','varnames',{'task','NFC'},'display','off');


% What are the differences between groups, exactly?
%Examine individual NFC group differences post-ANOVA main effect
lowNFCvalues = tasks_overall(split==1,:);midNFCvalues = tasks_overall(split==2,:);highNFCvalues = tasks_overall(split==3,:);
low = nanmean(lowNFCvalues,2); mid = nanmean(midNFCvalues,2); high = nanmean(highNFCvalues,2);
[h,p] = ttest2(low,mid);
disp(['Mid versus low NFC fair wage ratings: p = ' num2str(p)])
[h,p] = ttest2(high,low);
disp(['High versus low NFC fair wage ratings: p = ' num2str(p)])
[h,p] = ttest2(mid,high);
disp(['Mid versus high NFC fair wage ratings: p = ' num2str(p)])

%Does this difference account for NFC effect on fair wage?
matrix = [nanmean(n1subjvalue,2) nanmean(n2subjvalue,2) nanmean(n3subjvalue,2) data.NFC];
matrix(sum(isnan(matrix),2)>0,:) = [];
[r,p] = corr(matrix);

%% Another way of looking at the stuff above (differences between NFC & SAPS groups)
% within subjects

% now distinguishing between which subjects were best fit by each model

for measure = 1  %set measure = 1:2 to see SAPS score bins also, not just NFC
    figure
    count = 0;
    
    if measure == 1
        split = tertile_split(data.NFC); colors = NFCcolors;
        % Also, run multiple linear regressions
        X = [ones(n,1) data.NFC data.NFC.^2];
    elseif measure == 2
        split = tertile_split(data.SAPS); colors = SAPScolors;
        X = [ones(n,1) data.SAPS data.SAPS.^2];
    end
    invalid = sum(isnan(X),2)>0; X(invalid,:) = [];
    
    modelnum = 1;
    nparams = size(all_params{modelnum},2);
    paramnames = best_model.paramnames;
    paramnames{3} = 'maintenance cost';
    [~,assignments] = max(best_model.cbm.output.responsibility,[],2);
    modelgroup = assignments==modelnum;
    values = all_params{modelnum};
    model = coc_createModels(best_model.name);
    values = applyTrans_parameters(model,values);
    
    for p = 1:size(values,2)
        
        % run group-based & continuous stats
        [h,pval1] = ttest2(values(split==1&modelgroup,p),values(split==2&modelgroup,p));
        [h,pval2] = ttest2(values(split==3&modelgroup,p),values(split==2&modelgroup,p));
        [h,pval3] = ttest2(values(split==1&modelgroup,p),values(split==3&modelgroup,p));
        ps = [NaN pval1 pval3; pval1 NaN pval2; pval3 pval2 NaN];
        
        Y = nanmean(values,2); Y(invalid,:) = [];
        [betas,BINV,~,~,stats] = regress(Y,X);
        % get betas for quadratic term
        predicted = X*betas;
        distance = predicted-Y; MSE = distance'*distance; %squared distance
        if stats(3)<0.05
            disp([names{measure} ' significant betas on ' paramnames{p} ', linear & quadratic: ' num2str(betas')])
            disp(['p value = ' num2str(stats(3))])
        end
        
        count = count + 1;
        % plot effect of measure group on parameter values
        subplot(2,3,count)
        superbar([nanmean(values(split==1&modelgroup,p)) nanmean(values(split==2&modelgroup,p)) nanmean(values(split==3&modelgroup,p))], ...
            'E',[nanstd(values(split==1&modelgroup,p)) nanstd(values(split==2&modelgroup,p)) nanstd(values(split==3&modelgroup,p))]./sqrt(n), ...
            'P',ps,'BarFaceColor',colors,'PStarShowNS',false,'PStarBackgroundColor','None');
        ylabel(paramnames{p})
        %title(model_labels{modelnum})
        xticks([1:3])
        xticklabels({['Low ' names{measure}],['Mid ' names{measure}],['High ' names{measure}]})
        ax = gca; ax.FontSize = 14;
        
    end %of cycling over each cost
    
    fig = gcf; fig.Color = 'w';
    
end %of cycling over SAPS & NFC

%% Get posterior distributions over parameters, using the outputs of HBI
% Another way of looking at group differences across self-report measures

count = 0; figure
for measure = 1:2
    if measure == 1
        split = tertile_split(data.NFC);
        colors = NFCcolors;
        measure_label = 'NFC';
    elseif measure == 2
        split = tertile_split(data.SAPS);
        colors = SAPScolors;
        measure_label = 'SAPS';
    end
    
    labels = {'low','mid','high'};
    low_group = 0;
    mid_group = 0;
    high_group = 0;
    
    for group = 1:3
        subjs = find(split==group);
        group_label = labels{group};
        
        disp([num2str(length(subjs)) ' subjects in group ' num2str(group) ' (' group_label ' ' measure_label ')'])
        
        for s = 1:length(subjs)
            eval([group_label '_group = ' group_label '_group + log(joint{s});'])
        end
        
        eval(['full_posterior = ' group_label '_group;'])
        
        dim1 = logsumexp(full_posterior,1);
        dim2 = logsumexp(dim1,2);
        dim3 = logsumexp(dim2,3);
        full_posterior = full_posterior - dim3;
        %     % normalize to make sure it's a real posterior
        eval([group_label '_group = exp(full_posterior);'])
        
    end
    
    % and you could then compare these posteriors for the three groups.
    %
    % In practice, if a subject isn't well fit by a model (rho^s_j is low);
    % then that subject won't pull parameters that are only in that model away
    % from their population prior very much - which is just the property you
    % want.
    
    marginal_mainc(1,:) = sum(sum(low_group,1),3);
    marginal_mainc(2,:) = sum(sum(mid_group,1),3);
    marginal_mainc(3,:) = sum(sum(high_group,1),3);
    
    marginal_lurec(1,:) = sum(sum(low_group,2),3);
    marginal_lurec(2,:) = sum(sum(mid_group,2),3);
    marginal_lurec(3,:) = sum(sum(high_group,2),3);
    
    marginal_fac(1,:) = sum(sum(low_group,2),1);
    marginal_fac(2,:) = sum(sum(mid_group,2),1);
    marginal_fac(3,:) = sum(sum(high_group,2),1);
    
    count = count+1;
    subplot(2,3,count)
    plot(xs,marginal_mainc(1,:),'Color',colors(1,:),'LineWidth',1.5,'DisplayName',['Low ' measure_label])
    hold on
    plot(xs,marginal_mainc(2,:),'Color',colors(2,:),'LineWidth',1.5,'DisplayName',['Mid ' measure_label])
    plot(xs,marginal_mainc(3,:),'Color',colors(3,:),'LineWidth',1.5,'DisplayName',['High ' measure_label])
    legend('Location','Best')
    xlim([0 1.15])
    ax = gca; ax.FontSize = 14;
    title('Maintenance cost')
    
    count = count+1;
    subplot(2,3,count)
    plot(xs,marginal_lurec(1,:),'Color',colors(1,:),'LineWidth',1.5,'DisplayName',['Low ' measure_label])
    hold on
    plot(xs,marginal_lurec(2,:),'Color',colors(2,:),'LineWidth',1.5,'DisplayName',['Mid ' measure_label])
    plot(xs,marginal_lurec(3,:),'Color',colors(3,:),'LineWidth',1.5,'DisplayName',['High ' measure_label])
    legend('Location','Best')
    xlim([0 1.15])
    ax = gca; ax.FontSize = 14;
    title('Interference cost')
    
    count = count+1;
    subplot(2,3,count)
    plot(xs,marginal_fac(1,:),'Color',colors(1,:),'LineWidth',1.5,'DisplayName',['Low ' measure_label])
    hold on
    plot(xs,marginal_fac(2,:),'Color',colors(2,:),'LineWidth',1.5,'DisplayName',['Mid ' measure_label])
    plot(xs,marginal_fac(3,:),'Color',colors(3,:),'LineWidth',1.5,'DisplayName',['High ' measure_label])
    legend('Location','Best')
    title('False alarm cost')
    xlim([0 1.15])
    ax = gca; ax.FontSize = 14;
    fig = gcf; fig.Color = 'w';
    
end

