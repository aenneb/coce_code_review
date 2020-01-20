function Pilot6 = import_subj6_txt(filename, startRow, endRow)
%IMPORTFILE Import numeric data from a text file as a matrix.
%   PILOT6 = IMPORTFILE(FILENAME) Reads data from text file FILENAME for
%   the default selection.
%
%   PILOT6 = IMPORTFILE(FILENAME, STARTROW, ENDROW) Reads data from rows
%   STARTROW through ENDROW of text file FILENAME.
%
% Example:
%   Pilot6 = importfile('Pilot6.txt', 2, 463);
%
%    See also TEXTSCAN.

% Auto-generated by MATLAB on 2019/11/20 16:25:07

%% Initialize variables.
delimiter = ',';
if nargin<=2
    startRow = 2;
    endRow = inf;
end

%% Read columns of data as text:
% For more information, see the TEXTSCAN documentation.
formatSpec = '%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%q%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to the format.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines', startRow(1)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
for block=2:length(startRow)
    frewind(fileID);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines', startRow(block)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
    for col=1:length(dataArray)
        dataArray{col} = [dataArray{col};dataArrayBlock{col}];
    end
end

%% Close the text file.
fclose(fileID);

%% Convert the contents of columns containing numeric text to numbers.
% Replace non-numeric text with NaN.
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = mat2cell(dataArray{col}, ones(length(dataArray{col}), 1));
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[3,4,6,8,12,13,14,16,18]
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
rawNumericColumns = raw(:, [3,4,6,8,12,13,14,16,18]);
rawStringColumns = string(raw(:, [1,2,5,7,9,10,11,15,17,19,20,21,22,23,24,25,26,27]));


%% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),rawNumericColumns); % Find non-numeric cells
rawNumericColumns(R) = {NaN}; % Replace non-numeric cells

%% Make sure any text containing <undefined> is properly converted to an <undefined> categorical
for catIdx = [2,4,5,6,7,8,9,12]
    idx = (rawStringColumns(:, catIdx) == "<undefined>");
    rawStringColumns(idx, catIdx) = "";
end

%% Create output variable
Pilot6 = table;
Pilot6.success = rawStringColumns(:, 1);
Pilot6.trial_type = categorical(rawStringColumns(:, 2));
Pilot6.trial_index = cell2mat(rawNumericColumns(:, 1));
Pilot6.time_elapsed = cell2mat(rawNumericColumns(:, 2));
Pilot6.internal_node_id = rawStringColumns(:, 3);
Pilot6.rt = cell2mat(rawNumericColumns(:, 3));
Pilot6.stimulus = categorical(rawStringColumns(:, 4));
Pilot6.key_press = cell2mat(rawNumericColumns(:, 4));
Pilot6.task = categorical(rawStringColumns(:, 5));
Pilot6.correct = categorical(rawStringColumns(:, 6));
Pilot6.detect = categorical(rawStringColumns(:, 7));
Pilot6.correct_key = cell2mat(rawNumericColumns(:, 5));
Pilot6.tasknum = cell2mat(rawNumericColumns(:, 6));
Pilot6.training_performance = cell2mat(rawNumericColumns(:, 7));
Pilot6.nback = categorical(rawStringColumns(:, 8));
Pilot6.n = cell2mat(rawNumericColumns(:, 8));
Pilot6.practice = categorical(rawStringColumns(:, 9));
Pilot6.practice_accuracy = cell2mat(rawNumericColumns(:, 9));
Pilot6.response = rawStringColumns(:, 10);
Pilot6.slider_start = rawStringColumns(:, 11);
Pilot6.stimnum = categorical(rawStringColumns(:, 12));
Pilot6.TOT = rawStringColumns(:, 13);
Pilot6.overall = rawStringColumns(:, 14);
Pilot6.performance_by_block = rawStringColumns(:, 15);
Pilot6.points_list = rawStringColumns(:, 16);
Pilot6.value_list = rawStringColumns(:, 17);
Pilot6.offer_list = rawStringColumns(:, 18);

