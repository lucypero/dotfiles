local wezterm = require 'wezterm'
local act = wezterm.action
local scroll_strength = 5

-- ── per-machine detection ──────────────────────────────────────────
-- One config for every machine: anything that differs (desktop vs laptop,
-- Windows vs elsewhere) is detected here, not hardcoded below.
local is_windows = wezterm.target_triple:find('windows') ~= nil
-- Desktops report no battery; laptops report at least one.
local is_laptop = #wezterm.battery_info() > 0

local function exists(path)
  local f = io.open(path, 'r')
  if f then f:close() return true end
  return false
end

local function first_dir(candidates)
  for _, dir in ipairs(candidates) do
    if pcall(wezterm.read_dir, dir) then return dir end
  end
  return nil
end

-- nudevcmd.bat = vsinit.bat (MSVC env: CL/INCLUDE/LIB/PATH) + cd + nu.
-- cmd /c so the wrapper exits with nu instead of dropping back to cmd.
local msvc_nu = { 'cmd.exe', '/c', 'E:\\bin\\nudevcmd.bat' }
local has_msvc_nu = is_windows and exists('E:\\bin\\nudevcmd.bat')

local launch_menu = {
  { label = 'Nushell',    args = { 'nu' } },
  { label = 'PowerShell', args = { 'pwsh' } },
}
local default_prog = nil -- nil = the user's login shell
if is_windows then
  default_prog = has_msvc_nu and msvc_nu or { 'nu.exe' }
  if has_msvc_nu then
    table.insert(launch_menu, 1, { label = 'Nushell (MSVC dev)', args = msvc_nu })
  end
  table.insert(launch_menu, { label = 'Command Prompt', args = { 'cmd' } })
  table.insert(launch_menu, { label = 'Ubuntu (WSL)', domain = { DomainName = 'WSL:Ubuntu' } })
end

-- Pick the GPU: a discrete card on a desktop (power is free), the integrated
-- one on a laptop (keeps the dGPU asleep and the battery alive). Always Dx12,
-- so adapter selection can never drift to Vulkan or the CPU "Basic Render
-- Driver". Returns nil if nothing matches, and wezterm picks by itself.
local function pick_gpu()
  if not wezterm.gui then return nil end
  local want = is_laptop and 'IntegratedGpu' or 'DiscreteGpu'
  local fallback
  for _, gpu in ipairs(wezterm.gui.enumerate_gpus()) do
    if gpu.backend == 'Dx12' then
      if gpu.device_type == want then return gpu end
      if gpu.device_type ~= 'Cpu' then fallback = fallback or gpu end
    end
  end
  return fallback
end

return {
  -- ── shells (ported from Windows Terminal profiles) ───────────────
  default_prog = default_prog,
  default_cwd = first_dir {
    'E:\\dev\\dx12',
    'D:\\dev\\hookin',
  },
  launch_menu = launch_menu,
  -- ── input latency ────────────────────────────────────────────────
  -- Dx12 backend instead of the ANGLE/OpenGL one (prefer_egl is only
  -- consulted by the OpenGL front end, so it no longer applies).
  front_end = 'WebGpu',
  webgpu_power_preference = is_laptop and 'LowPower' or 'HighPerformance',
  webgpu_preferred_adapter = is_windows and pick_gpu() or nil,
  -- Default is 60, which on a 144 Hz panel adds up to ~8 ms of waiting
  -- before a keypress is even drawn. Match the monitor instead.
  max_fps = 144,
  -- Cursor fade/blink animations force repaints and delay the frame the
  -- keypress lands in. 1 fps + rate 0 = no animation, no blink at all.
  animation_fps = 1,
  cursor_blink_rate = 0,
  cursor_blink_ease_in = 'Constant',
  cursor_blink_ease_out = 'Constant',
  default_cursor_style = 'SteadyBlock',
  -- No network check on startup.
  check_for_updates = false,
  -- Default 3. After each read from the pty, wezterm sleeps this long to
  -- coalesce fragmented writes into one "frame" before parsing them. An
  -- echoed keystroke is a tiny chunk, so it always eats the full delay.
  -- 0 = dispatch immediately; costs some tearing on unsynchronised TUI output.
  mux_output_parser_coalesce_delay_ms = 0,
  -- ─────────────────────────────────────────────────────────────────

  color_scheme = 'zenbones_dark',
  font = wezterm.font('JetBrains Mono', { weight = 'Medium'}),
  font_size = 11.0,
  enable_scroll_bar = true,
  keys = {
    {
      key = 'w',
      mods = 'CTRL|SHIFT',
      action = act.CloseCurrentPane { confirm = false },
    },
    {
      key = 'DownArrow',
      mods = 'CTRL|SHIFT',
      action = act.SplitVertical { domain = 'CurrentPaneDomain' },
    },
    {
      key = 'RightArrow',
      mods = 'CTRL|SHIFT',
      action = act.SplitHorizontal { domain = 'CurrentPaneDomain' },
    },
    {
      key = 'd',
      mods = 'CTRL|ALT',
      action = act.SplitHorizontal { domain = 'CurrentPaneDomain' },
    },
    {
      key = 'D',
      mods = 'CTRL|ALT|SHIFT',
      action = act.SplitVertical { domain = 'CurrentPaneDomain' },
    },
    -- Change Split Focus
    {
      key = ']',
      mods = 'CTRL',
      action = act.ActivatePaneDirection 'Next',
    },
    {
      key = '[',
      mods = 'CTRL',
      action = act.ActivatePaneDirection 'Prev',
    },
    {
      key = 'j',
      mods = 'ALT',
      action = act.ActivatePaneDirection 'Down',
    },
    {
      key = 'k',
      mods = 'ALT',
      action = act.ActivatePaneDirection 'Up',
    },
    {
      key = 'h',
      mods = 'ALT',
      action = act.ActivatePaneDirection 'Left',
    },
    {
      key = 'l',
      mods = 'ALT',
      action = act.ActivatePaneDirection 'Right',
    },
    -- scrolling
    {
      key = 'j',
      mods = 'CTRL|SHIFT',
      action = act.ScrollByLine(scroll_strength),
    },
    {
      key = 'k',
      mods = 'CTRL|SHIFT',
      action = act.ScrollByLine(-scroll_strength),
    },
    {
      key = 'f',
      mods = 'CTRL|SHIFT',
      action = act.ScrollByPage(1),
    },
    {
      key = 'b',
      mods = 'CTRL|SHIFT',
      action = act.ScrollByPage(-1)
    },
    -- search
    {
      key = '/',
      mods = 'CTRL',
      action = act.Search("CurrentSelectionOrEmptyString")
    },
  }
}
