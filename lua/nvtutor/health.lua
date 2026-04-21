local M = {}

function M.check()
  vim.health.start('NVTutor')

  -- Check Neovim version
  if vim.fn.has('nvim-0.10') == 1 then
    vim.health.ok('Neovim version >= 0.10')
  else
    vim.health.error('NVTutor requires Neovim 0.10+', {
      'Upgrade Neovim to version 0.10 or later',
    })
  end

  -- Check data directory
  local data_dir = vim.fn.stdpath('data') .. '/tutor'
  if vim.fn.isdirectory(data_dir) == 1 then
    vim.health.ok('Data directory exists: ' .. data_dir)
  else
    local ok = vim.fn.mkdir(data_dir, 'p')
    if ok == 1 then
      vim.health.ok('Data directory created: ' .. data_dir)
    else
      vim.health.error('Cannot create data directory: ' .. data_dir)
    end
  end

  -- Check progress file
  local progress_file = data_dir .. '/progress.json'
  if vim.fn.filereadable(progress_file) == 1 then
    local content = vim.fn.readfile(progress_file)
    local raw = table.concat(content, '\n')
    local ok, _ = pcall(vim.json.decode, raw)
    if ok then
      vim.health.ok('Progress file is valid JSON')
    else
      vim.health.warn('Progress file contains invalid JSON', {
        'Run :NVTutor reset to clear corrupted progress',
      })
    end
  else
    vim.health.ok('No progress file yet (fresh install)')
  end

  -- Validate chapter content
  local chapters_ok, chapters = pcall(require, 'nvtutor.chapters')
  if chapters_ok and chapters.validate then
    local errors = chapters.validate()
    if #errors == 0 then
      vim.health.ok('All chapter content validates successfully')
    else
      for _, err in ipairs(errors) do
        vim.health.warn('Content validation: ' .. err)
      end
    end
  else
    vim.health.ok('Chapter validation skipped (chapters not yet loaded)')
  end
end

return M
