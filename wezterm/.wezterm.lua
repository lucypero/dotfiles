local wezterm = require 'wezterm'
local act = wezterm.action
local scroll_strength = 5

return {
  -- ── shells (ported from Windows Terminal profiles) ───────────────
  -- nudevcmd.bat = vsinit.bat (MSVC env: CL/INCLUDE/LIB/PATH) + cd + nu.
  -- cmd /c so the wrapper exits with nu instead of dropping back to cmd.
  default_prog = { 'cmd.exe', '/c', 'E:\\bin\\nudevcmd.bat' },
  default_cwd = 'E:\\dev\\dx12',
  launch_menu = {
    { label = 'Nushell (MSVC dev)', args = { 'cmd.exe', '/c', 'E:\\bin\\nudevcmd.bat' } },
    { label = 'Nushell',            args = { 'nu' } },
    { label = 'PowerShell',         args = { 'pwsh' } },
    { label = 'Command Prompt',     args = { 'cmd' } },
    { label = 'Ubuntu (WSL)',       domain = { DomainName = 'WSL:Ubuntu' } },
  },
  -- ── input latency ────────────────────────────────────────────────
  -- Dx12 backend instead of the ANGLE/OpenGL one (prefer_egl is only
  -- consulted by the OpenGL front end, so it no longer applies).
  front_end = 'WebGpu',
  webgpu_power_preference = 'HighPerformance',
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
  -- Pin the discrete card + Dx12 explicitly, so adapter selection can
  -- never drift to the Vulkan path or the CPU "Basic Render Driver".
  webgpu_preferred_adapter = (function()
    if not wezterm.gui then return nil end
    for _, gpu in ipairs(wezterm.gui.enumerate_gpus()) do
      if gpu.backend == 'Dx12' and gpu.device_type == 'DiscreteGpu' then
        return gpu
      end
    end
    return nil
  end)(),
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
