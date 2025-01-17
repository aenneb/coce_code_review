%% An outer level script for running Piray & Daw's HBI package (cbm)
% Running it on subjects from cost of control data set
% After running with type II ML package (EMfit_sm), thought I'd like to
% account for the fact that some subjects are better fit by different
% models.
% Instructions for doing all this here: https://payampiray.github.io/cbm

% % Starting out with some simple generate/recover on my models of interest
clear all

%% PREPARE FOR MODEL FITTING:
% FORMAT DATA, ETC.

global realsubjectsflag model_name HBI_flag
realsubjectsflag = true; HBI_flag = true;

%add relevant paths
addpath('cbm-master/codes/');
addpath('model-functions/');
addpath('../'); %other COC code, like model loading

%if isdir('data')
if isdir('../../data')
    % ALL experimental data, all 100 subjects live in 'data'
    load('../../data/filenames.mat')
    prefix = '../../data/';
    % grab all subjects from those files, then
elseif isdir('../../example_data')
    files{1} = '../../example_data/example_subjs.mat';
    prefix = '../../example_data/';
end
% version 4

load([prefix 'toanalyze.mat'])

paramcolors = [1 0 0; 1 0.5 0; 1 0 0.5; 0 0 1; 0 0.5 1; 0 0.7 0; 1 1 0];
% Set up some plotting variables

% WHICH PARAMETER COMBINATIONS DO YOU WANT?
% Models are specified by which parameters you want to include, like so:
% "epsilon_initi_alpha_mainc"
% This is a model containing a noise term epsilon (they all do), a separate
% initial rating for each task initi, a learning rate alpha which dictates
% the speed of cost learning, and a maintenance cost only (most frequently
% recovered model in the full dataset of 100 subjects)

% Dictate models to fit here by specifying which parameters are of interest
paramsofinterest = {'mainc','lurec','missc','fac','respc','initi'};

modelstofit = get_all_param_combos(paramsofinterest);
% Combine into one set of models
modelstofit = [modelstofit get_all_param_combos({'mainc','lurec','missc','fac','respc','deltai','initi'})];
% Add delta models into the mix by specifying the parameter 'deltai', which
% provides a different delta for each cost, or the parameter 'delta' which
% provides one delta for all costs.

% Toggle this on if you want to run
% model fitting over reliable models only (i.e. over models where the
% fidelity of recovered parameters has already been confirmed)
% Having a sense for this requires that you run test_model_recoverability

strict_criterion_for_fitting = false;

recoverability = true(length(modelstofit),1);

if strict_criterion_for_fitting
    
    for m = 1:length(modelstofit)
        file = load(['model-details/' modelstofit{m}]);
        recoverability(m) = file.reliable=='y';
    end
    modelstofit = modelstofit(recoverability);
    
end

% Go over existing models to ensure they have corresponding functions for
% their execution. In HBI framework, every model needs its own function.
% In my model fitting code, there is one fitting function which flexibly
% fits all models, so each model function is just named for the model, but
% contains the same call to that general model fitting function
% (getprobscostlearning.m).

function_folder = dir('model-functions'); list_existing = cellstr(string(char(function_folder.name)));
for m = 1:length(modelstofit)
    % now, cycling through models which are recoverable, create function
    % calls for running those models if they don't already exist
    diff = length(list_existing{end})-length(['fit_' modelstofit{m} '.m']);
    if sum(contains(list_existing,['fit_' modelstofit{m} '.m' repmat(' ',1,diff)]))==0 %no function for running this model, yet
        copyfile('dictate_model.m',['model-functions/fit_' modelstofit{m} '.m'])
    end
    %otherwise, do nothing
end

% Format real subject data for feeding in to the HBI framework. HBI is
% looking for 1 struct entry per subject.
nsubjs = length(unique(toanalyze.subj));
for subj = 1:length(unique(toanalyze.subj))
    data{subj} = toanalyze(toanalyze.subj==subj,:);
end


%% NOW, RUN REAL FITS! NO MORE PREPARATION NECESSARY!
% FIT REAL SUBJECT DATA!

fitflag = true;
% Run the whole model fitting, or just display previous fits?

% Define the parameters/inputs to HBI, including MLE fits of each model
v = 6.25;
for m = 1:length(modelstofit)
    model_name = modelstofit{m}; modeltofit = coc_createModels(model_name);
    fnames{m} = [modelstofit{m} '.mat'];
    eval(['func = @fit_' modelstofit{m} ';']); funcs{m} = func;
    priors{m} = struct('mean',zeros(modeltofit.nparams,1),'variance',v); 
    model_labels{m} = strrep(modelstofit{m},'_','-');
    if fitflag; cbm_lap(data, func, priors{m}, fnames{m}); end
end
fname_hbi = 'HBI_coc_48models_2022.mat'; 

% % RUN HBI %%

% Inputs are:
%data {cell per subj}, model-specific fitting functions, filenames from
%cbm_lap, %filename for saving full running to
if fitflag
    cbm_hbi(data,funcs,fnames,fname_hbi);
    cbm_hbi_null(data,fname_hbi);
end

%% ANALYZE MODEL FITS!

%Model fits get saved in a structure called cbm, load that up here and
% grab variables of interest from it.
fits = load(fname_hbi);
cbm   = fits.cbm;
freqs = cbm.output.model_frequency;
[~,best] = max(cbm.exceedance.pxp);
best_model = coc_createModels(modelstofit{best});

% Here I create my own structure, best_model, for saving other measures of
% interest, like the name of every model that ran in this model fitting
% regime. This gets called in other analysis scripts, like
% paper_graphs_and_stats.m, which lives one directory up.
best_model.lowparams = cbm.output.parameters{best};
best_model.highparams = cbm.output.group_mean{best}; best_model.overallfit = cbm.output;
best_model.overallfit.fitmodels = model_labels; best_model.name = model_labels{best};
best_model.cbm = cbm;
modelStruct.best_model = best_model; save('HBI_modelStruct.mat','modelStruct');

% Format parameter names, etc. to be input in to CBM toolbox plot command
% below
for p = 1:length(best_model.paramnames)
    original_name = best_model.paramnames{p};
    param_names{p}= original_name; transform{p} = 'none';
    if strmatch(original_name,'alpha')
        transform{p} = 'sigmoid';
        param_names{p} = ['\' original_name];
    end
    if strmatch(original_name,'epsilon')
        transform{p} = 'exp';
        param_names{p} = ['\' original_name];
    end
    if contains(original_name,'c')
        param_names{p} = strrep(original_name,'c',' cost');
        costs(p) = true;
    else
        costs(p) = false;
    end 
end

% Use CBM toolbox to print parameter means etc.
% 1st input is the file-address of the file saved by cbm_hbi
% 2nd input: a cell input containing model names
% 3rd input: another cell input containing parameter names of the winning model
cbm_hbi_plot(fname_hbi, model_labels, param_names(1:best_model.nparams), transform(1:best_model.nparams))
% this function creates a model comparison plot (exceednace probability and model frequency) as well as 
% a plot of transformed parameters of the most frequent model.

% % run a t-test on maintenance costs (from best model) versus 0
% % 2nd input: the index of the model of interest in the cbm file
k = 1; % model including maintenance costs
% % 3rd input: the test will be done compared with this value (i.e. this value indicates the null hypothesis)
m = 0; % here the maintenance costs parameter should be tested against m = 0
% % 4th input: the index of the parameter of interest 
i = 3; % here the maintenance parameter is the 3rd parameter of the winning model
[p,stats] = cbm_hbi_ttest(cbm,k,m,i);

k = 2; % model including interference (lure) costs
% other arguments to this function are the same
[p,stats] = cbm_hbi_ttest(cbm,k,m,i);

k = 4; % third-best model including interference (lure) costs
% other arguments to this function are the same
[p,stats] = cbm_hbi_ttest(cbm,k,m,i);

% is the learning rate 0?
% no
k = 1; i = 2;
m = 1./(1+exp(0));
% run t-test on transformed 0 value - same as alpha is transformed ??
[p,stats] = cbm_hbi_ttest(cbm,k,m,i)

% count up total model frequency w response and miss costs
idx = contains(modelstofit,'missc') | contains(modelstofit,'respc');
disp(['missc and respc reprsented in ' num2str(sum(freqs(idx))) '% model frequency'])

figure
subplot(4,3,1)
bar(freqs)
title('Fit model freq (HBI)')
%xticklabels(model_labels)
%xtickangle(45)
fig = gcf; fig.Color = 'w';
best_models = find(cbm.output.model_frequency>=0.01);
for m = 1:length(best_models)
    modeltofit = coc_createModels(modelstofit{best_models(m)});
    means = applyTrans_parameters(modeltofit,cbm.output.group_mean{best_models(m)});
    subplot(4,3,m+1)
    for p = 1:modeltofit.nparams
        bar(p,means(p),'FaceColor',paramcolors(p,:))
        hold on
    end
    ylim([-2 2])
    xticks(1:length(means))
    errorbar(means,cbm.output.group_hierarchical_errorbar{best_models(m)},'*k')
    xticklabels(modeltofit.paramnames)
    title('Parameter means from subjects best fit by model')
end

subplot(4,3,m+2); 
costs = find(costs(1:best_model.nparams)); 
means = applyTrans_parameters(modeltofit,cbm.output.group_mean{2});
bar(means(:,costs),'FaceColor',[0 0.7 0])
hold on
errorbar(means(:,costs),cbm.output.group_hierarchical_errorbar{m}(costs),'*k')
%plot(1:length(costs),best_model.lowparams(:,costs),'--k')
fig = gcf; fig.Color = 'w';
xticklabels(param_names(costs))
xtickangle(30)
ylabel('Mean parameter value')
xlabel('Cost parameter')

%% Model simulations and validation figures
% Call a couple functions to see the effects of previous model
% fitting. For example, is there a good match between simulated and real
% subject behavior, using these best-fit models?

% Plot comparisons between simulated data and real subject behavior
model_validation_HBI()

% Plot individual model information if you want confirmation it's fitting
% well
cbm.input.model_names = modelstofit;
% model_inspection(best_models(end),cbm)
model_inspection(1,cbm)
