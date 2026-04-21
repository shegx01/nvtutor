local M = {}

function M.setup()
  local groups = {
    NVTutorTarget  = { default = true, bg = '#3B3820', fg = '#E0D060', bold = true },
    NVTutorSuccess = { default = true, bg = '#1E3A1E', fg = '#60E060', bold = true },
    NVTutorHint    = { default = true, fg = '#888888', italic = true },
    NVTutorError   = { default = true, bg = '#3A1E1E', fg = '#E06060', bold = true },
    NVTutorBronze  = { default = true, fg = '#CD7F32', bold = true },
    NVTutorSilver  = { default = true, fg = '#C0C0C0', bold = true },
    NVTutorGold    = { default = true, fg = '#FFD700', bold = true },
  }

  for name, opts in pairs(groups) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end

return M
