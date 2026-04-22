local M = {}

function M.check()
  vim.health.start('NVTutor')

  -- Check Neovim version
  -- 0.10 is the minimum for vim.on_key()'s `typed` parameter and vim.health.start()
  if vim.fn.has('nvim-0.10') == 1 then
    vim.health.ok('Neovim version >= 0.10')
  else
    vim.health.error('NVTutor requires Neovim 0.10+', {
      'Upgrade Neovim to version 0.10 or later',
    })
  end

  -- Check command registration
  if vim.fn.exists(':NVTutor') == 2 then
    vim.health.ok(':NVTutor command is registered')
  else
    vim.health.warn(':NVTutor command not found', {
      'Ensure your plugin manager has loaded nvtutor (cmd = "NVTutor" in lazy.nvim)',
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
    local ok, decoded = pcall(vim.json.decode, raw)
    if not ok then
      vim.health.warn('Progress file contains invalid JSON', {
        'Run :NVTutor reset to clear corrupted progress',
      })
    elseif type(decoded) ~= 'table' or not decoded.version then
      vim.health.warn('Progress file missing schema fields — may be from an older version', {
        'Run :NVTutor reset if you encounter unexpected behavior',
      })
    else
      vim.health.ok('Progress file is valid (schema v' .. tostring(decoded.version) .. ')')
    end
  else
    vim.health.ok('No progress file yet (fresh install)')
  end

  -- Validate chapter content
  local chapters_ok, chapters = pcall(require, 'nvtutor.chapters')
  if not chapters_ok then
    vim.health.warn('Could not load nvtutor.chapters: ' .. tostring(chapters))
  elseif not chapters.validate then
    vim.health.warn('chapters.validate() not found — content validation skipped')
  else
    local errors = chapters.validate()
    if #errors == 0 then
      vim.health.ok(string.format('All %d chapters validate successfully', chapters.get_chapter_count()))
    else
      for _, err in ipairs(errors) do
        vim.health.warn('Content validation: ' .. err)
      end
    end
  end
end

return M
