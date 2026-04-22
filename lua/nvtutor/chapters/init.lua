local M = {}

M.chapters = {
  { id = 1, title = 'First Steps',              file = 'ch1' },
  { id = 2, title = 'Editing Essentials',        file = 'ch2' },
  { id = 3, title = 'The Vim Language',          file = 'ch3' },
  { id = 4, title = 'Insert & Change Mastery',   file = 'ch4' },
  { id = 5, title = 'Precision Movement',        file = 'ch5' },
  { id = 6, title = 'Document Navigation',       file = 'ch6' },
  { id = 7, title = 'Search',                    file = 'ch7' },
  { id = 8, title = 'Power Commands',            file = 'ch8' },
  { id = 9, title = 'Vim Tricks',               file = 'ch9' },
}

---@param n number chapter number (1-9)
---@return table chapter module
function M.get_chapter(n)
  return require('nvtutor.chapters.ch' .. n)
end

---@param chapter_n number
---@param lesson_n number
---@return table|nil lesson table
function M.get_lesson(chapter_n, lesson_n)
  local ok, chapter = pcall(M.get_chapter, chapter_n)
  if not ok or not chapter.lessons then
    return nil
  end
  return chapter.lessons[lesson_n]
end

---@return number
function M.get_chapter_count()
  return #M.chapters
end

---@param chapter_n number
---@return number
function M.get_lesson_count(chapter_n)
  local ok, chapter = pcall(M.get_chapter, chapter_n)
  if not ok or not chapter.lessons then
    return 0
  end
  return #chapter.lessons
end

---Validate all chapter content. Returns list of error strings.
---@return string[]
function M.validate()
  local errors = {}

  for _, ch_meta in ipairs(M.chapters) do
    local n = ch_meta.id
    local ok, chapter = pcall(M.get_chapter, n)
    if not ok then
      table.insert(errors, 'Ch' .. n .. ': failed to load: ' .. tostring(chapter))
      goto continue
    end

    if not chapter.lessons or #chapter.lessons == 0 then
      table.insert(errors, 'Ch' .. n .. ': no lessons found')
      goto continue
    end

    local seen_ids = {}
    for li, lesson in ipairs(chapter.lessons) do
      -- Check duplicate IDs
      if lesson.id then
        if seen_ids[lesson.id] then
          table.insert(errors, 'Ch' .. n .. ' L' .. li .. ': duplicate lesson id ' .. lesson.id)
        end
        seen_ids[lesson.id] = true
      end

      -- Check challenge count
      if not lesson.challenges or #lesson.challenges < 3 then
        table.insert(errors, 'Ch' .. n .. ' L' .. li .. ': fewer than 3 challenges')
      elseif #lesson.challenges > 5 then
        table.insert(errors, 'Ch' .. n .. ' L' .. li .. ': more than 5 challenges')
      end

      -- Validate each challenge
      for ci, c in ipairs(lesson.challenges or {}) do
        local prefix = 'Ch' .. n .. ' L' .. li .. ' C' .. ci .. ': '

        if not c.type then
          table.insert(errors, prefix .. 'missing type')
        end
        if not c.command or c.command == '' then
          table.insert(errors, prefix .. 'missing or empty command')
        end
        if not c.instruction then
          table.insert(errors, prefix .. 'missing instruction')
        end
        if not c.buffer_lines or #c.buffer_lines == 0 then
          table.insert(errors, prefix .. 'missing or empty buffer_lines')
        end
        if not c.start_pos then
          table.insert(errors, prefix .. 'missing start_pos')
        end
        if not c.optimal_keystrokes or c.optimal_keystrokes <= 0 then
          table.insert(errors, prefix .. 'missing or invalid optimal_keystrokes')
        end
        if not c.optimal_time then
          table.insert(errors, prefix .. 'missing optimal_time')
        end

        -- Optional field type check
        if c.optimal_solution ~= nil and type(c.optimal_solution) ~= 'string' then
          table.insert(errors, prefix .. 'optimal_solution must be a string')
        end

        -- Type-specific checks
        local needs_target = { movement = true, search = true, visual = true }
        local needs_expected = { editing = true, vim_language = true, power = true }

        if needs_target[c.type] and not c.target then
          table.insert(errors, prefix .. 'movement/search challenge missing target')
        end
        if needs_expected[c.type] and not c.expected_lines then
          table.insert(errors, prefix .. 'editing/vim_language/power challenge missing expected_lines')
        end

        -- Check target within bounds
        if c.target and c.target.line and c.buffer_lines then
          if c.target.line > #c.buffer_lines or c.target.line < 1 then
            table.insert(errors, prefix .. 'target line out of bounds')
          end
        end

        -- Check expected differs from initial for editing types
        if needs_expected[c.type] and c.expected_lines and c.buffer_lines then
          local same = true
          if #c.expected_lines ~= #c.buffer_lines then
            same = false
          else
            for i = 1, #c.buffer_lines do
              if c.buffer_lines[i] ~= c.expected_lines[i] then
                same = false
                break
              end
            end
          end
          if same then
            table.insert(errors, prefix .. 'expected_lines identical to buffer_lines')
          end
        end
      end
    end

    ::continue::
  end

  return errors
end

return M
