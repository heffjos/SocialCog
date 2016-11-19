

[indices, names, infos] = GetKeyboardIndices;

for i = 1:numel(indices)
    fprintf('%d:%s\n', indices(i), names{i});
end
