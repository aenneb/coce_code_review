function [map,negllh] = getprobs_costlearning(params)
%Get minimum a priori score (MAP) for specific parameter values of cost learning model
%   Runs model with input value of parameters
%   Returns map and negllh

global onesim modeltofit mu sigma fit_epsilon_opt noiselessri realsubjectsflag model
if ~realsubjectsflag
% simulated data, not real
% simdata = [simdata; subj task rating torate updates misses mains matches];
    subj = unique(onesim(:,1));
    stimuli = onesim(:,2);
    realratings = onesim(:,3);
    display = onesim(:,4);
    nupdates = onesim(:,5);
    nmisses = onesim(:,6);
    mains = onesim(:,7);
    nmatches = onesim(:,8);
    noisiness = onesim(:,9);
    responses = onesim(:,10);
    nlures = onesim(:,11);
else %fitting real subject data
    subj = unique(onesim.subj);
    stimuli = onesim.task;
    realratings = (onesim.BDM); %scale down? just added this 11/08/2020 - see how this works
    display = onesim.display;
    nupdates = zeros(length(onesim.nupdates),1); nupdates(onesim.nupdates>0,:) = zscore(onesim.nupdates(onesim.nupdates>0,:)); % need to edit nupdates because it has so many zeros from irrelevant task 1
    nmisses = zscore(onesim.nmisses);
    mains = zscore(onesim.maintained); 
    nmatches = zscore(onesim.nmatches);
    noisiness = zscore(onesim.noisiness);
    responses = zscore(onesim.nresponses);
    nlures = zscore(onesim.nlures);
end

model = modeltofit; %make agnostic variable model to send inputs in to param values func without overwriting other stuff outside this loop
[uc,epsilon,init,mc,mainc,matchc,noisec,respc,lurec,alpha,delta] = setParamValues(params);
costs = [uc mc mainc matchc noisec respc lurec];
ntrials = sum(~isnan(realratings)); %length(stimuli);

if ~modeltofit.init %remove intercept by 0-centering judgments
    realratings = realratings-mean(realratings); %remove mean, center at 0
end

%simulate the model for one subject at a time
ratings = init*(ones(1,max(display))); ratings_list = NaN(ntrials,1); %init for each subject 
costs = repmat(costs,ntrials,1);
if modeltofit.delta 
    for trial = 1:ntrials
        costs(trial,:) = setNewCosts(costs(trial,:),delta,trial);
    end
end
components = [nupdates nmisses mains nmatches noisiness responses nlures];
cost = sum(costs.*components(1:ntrials,:),2); %add all the costs together
for trial = 1:ntrials
    torate = display(trial); stim = stimuli(trial);
    if ~isnan(torate) %skip those trials
        %ratings(ratings<0)=0;
        rating = ratings(torate); ratings_list(trial) = rating; %ratings(stim) 
    end %end of disqualifying data type for displayed task
    
    if modeltofit.alpha
        ratings(stim) = ratings(stim) + alpha.*(cost(trial)-ratings(stim)); %delta rule
    else %alpha fixed or no alpha
        %ratings(stim) = ratings(stim) + alpha*(cost); %compounding cost model
        ratings(stim) = cost(trial); %no learning, no compounding, no delta rule. just a basic regression on last round
    end
end
%calculate epsilon optimally
epsilon_opt = sqrt((1/ntrials) * sum(realratings(~isnan(realratings)) - ratings_list).^2);
if ~modeltofit.epsilon; epsilon = epsilon_opt; end
probs = normpdf(realratings(~isnan(realratings)),ratings_list,epsilon); probs(probs==0) = 1e-100; %can't be 0 exactly for llh
negllh = -nansum(log(probs));
fit_epsilon_opt(subj) = epsilon_opt; %track fit epsilons

priors = normpdf(params',mu',sigma');
lprior = sum(log(priors));
map = negllh-lprior;
end

