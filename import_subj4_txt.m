%% Import data from text file.
% Script for importing data from the following text file:
%
%    C:\Users\sarah\Dropbox\MTurk_tasks\costofcontrol\Pilot4.txt
%
% To extend the code to different selected data or a different text file,
% generate a function instead of a script.

% Auto-generated by MATLAB on 2019/11/13 12:15:22

%% Initialize variables.
function Pilot4 = import_subj4_txt(filename)

%filename = 'C:\Users\sarah\Dropbox\MTurk_tasks\costofcontrol\Pilot4.txt';
delimiter = ',';
startRow = 2;

%% Read columns of data as text:
% For more information, see the TEXTSCAN documentation.
formatSpec = '%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to the format.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines' ,startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');

%% Close the text file.
fclose(fileID);

%% Convert the contents of columns containing numeric text to numbers.
% Replace non-numeric text with NaN.
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = mat2cell(dataArray{col}, ones(length(dataArray{col}), 1));
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[1,3,6,7,11,12,13,15,17]
    % Converts text in the input cell array to numbers. Replaced non-numeric
    % text with NaN.
    rawData = dataArray{col};
    for row=1:size(rawData, 1)
        % Create a regular expression to detect and remove non-numeric prefixes and
        % suffixes.
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData(row), regexstr, 'names');
            numbers = result.numbers;
            
            % Detected commas in non-thousand locations.
            invalidThousandsSeparator = false;
            if numbers.contains(',')
                thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(numbers, thousandsRegExp, 'once'))
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            % Convert numeric text to numbers.
            if ~invalidThousandsSeparator
                numbers = textscan(char(strrep(numbers, ',', '')), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch
            raw{row, col} = rawData{row};
        end
    end
end


%% Split data into numeric and string columns.
rawNumericColumns = raw(:, [1,3,6,7,11,12,13,15,17]);
rawStringColumns = string(raw(:, [2,4,5,8,9,10,14,16,18,19,20,21,22,23,24,25,26]));


%% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),rawNumericColumns); % Find non-numeric cells
rawNumericColumns(R) = {NaN}; % Replace non-numeric cells

%% Make sure any text containing <undefined> is properly converted to an <undefined> categorical
for catIdx = [1,2,3,5,6,7,8,10,11]
    idx = (rawStringColumns(:, catIdx) == "<undefined>");
    rawStringColumns(idx, catIdx) = "";
end

%% Create output variable
Pilot4 = table;
Pilot4.rt = cell2mat(rawNumericColumns(:, 1));
Pilot4.stimulus = categorical(rawStringColumns(:, 1));
Pilot4.key_press = cell2mat(rawNumericColumns(:, 2));
Pilot4.task = categorical(rawStringColumns(:, 2));
Pilot4.trial_type = categorical(rawStringColumns(:, 3));
Pilot4.trial_index = cell2mat(rawNumericColumns(:, 3));
Pilot4.time_elapsed = cell2mat(rawNumericColumns(:, 4));
Pilot4.internal_node_id = rawStringColumns(:, 4);
Pilot4.correct = categorical(rawStringColumns(:, 5));
Pilot4.detect = categorical(rawStringColumns(:, 6));
Pilot4.correct_key = cell2mat(rawNumericColumns(:, 5));
Pilot4.tasknum = cell2mat(rawNumericColumns(:, 6));
Pilot4.training_performance = cell2mat(rawNumericColumns(:, 7));
Pilot4.nback = categorical(rawStringColumns(:, 7));
Pilot4.n = cell2mat(rawNumericColumns(:, 8));
Pilot4.practice = categorical(rawStringColumns(:, 8));
Pilot4.practice_accuracy = cell2mat(rawNumericColumns(:, 9));
Pilot4.response = rawStringColumns(:, 9);
Pilot4.slider_start = categorical(rawStringColumns(:, 10));
Pilot4.stimnum = categorical(rawStringColumns(:, 11));
Pilot4.TOT = rawStringColumns(:, 12);
Pilot4.overall = rawStringColumns(:, 13);
Pilot4.performance_by_block = rawStringColumns(:, 14);
Pilot4.points_list = rawStringColumns(:, 15);
Pilot4.value_list = rawStringColumns(:, 16);
Pilot4.offer_list = rawStringColumns(:, 17);

%% Clear temporary variables
clearvars filename delimiter startRow formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp rawNumericColumns rawStringColumns R catIdx idx;

end