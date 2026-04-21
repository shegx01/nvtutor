if vim.g.loaded_nvtutor then
  return
end

vim.api.nvim_create_user_command('NVTutor', function(opts)
  require('nvtutor').command(opts)
end, {
  nargs = '?',
  complete = function()
    return { 'menu', 'reset', 'stats' }
  end,
})

vim.g.loaded_nvtutor = true
