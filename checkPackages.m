REQUIRED_TOOLBOXES = [
  "signal_processing",
];

for i = 0:length(REQUIRED_TOOLBOXES)
    hasIPT = license('test', REQUIRED_TOOLBOXES(i));
    if ~hasIPT
      % User does not have the toolbox installed.
      message = sprintf('Sorry, but you do not seem to have the %s Toolbox.\nDo you want to try to continue anyway?', REQUIRED_TOOLBOXES(i));
      reply = questdlg(message, 'Toolbox missing', 'Yes', 'No', 'Yes');
      if strcmpi(reply, 'No')
        % User said No, so exit.
        return;
      end
    end
end