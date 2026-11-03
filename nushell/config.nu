# Nushell Config File

alias e = zed
alias f = cd (open --raw ~\docs\bookmarks | fzf)
alias ef = e (open --raw ~\docs\bookmarks | fzf)
def ba [] { $"($env.PWD)\n" | save ~\docs\bookmarks --append }
alias c = cargo

# play lucynes
def playnes [] {
  cd "E:\\dev\\lucynes"
  let rom = (rg --files roms/ | fzf)
  odin run . --o:speed -- ($rom)
}

# editing configurations
alias ec = e $"($nu.config-path)"
alias ece = e $nu.env-path
alias ecn = e $nu.config-path
alias ecw = e ~\.wezterm.lua

$env.FZF_DEFAULT_OPTS = "--color=hl:magenta,fg+:-1,hl+:magenta,info:magenta,prompt:magenta,pointer:magenta,marker:-1,spinner:magenta,header:magenta,bg:-1,bg+:-1"

alias config = git $"--git-dir=($env.USERPROFILE)/.cfg/" $"--work-tree=($env.USERPROFILE)"
alias lg = lazygit
alias lconfig = lazygit $"--git-dir=($env.USERPROFILE)/.cfg/" $"--work-tree=($env.USERPROFILE)"

# "default" = the terminal's own foreground (ESC[39m), so text stays readable
# whether Zed/WezTerm is in a light or dark theme
let lucy_fg = "default"
let lucy_error = { fg: "#FFFFFF" bg: "#FF0000" attr: b}

let lucy_theme = {
    # color for nushell primitives
    separator: $lucy_fg
    leading_trailing_space_bg: { attr: n } # no fg, no bg, attr none effectively turns this off
    header: magenta
    empty: blue
    bool: $lucy_fg
    int: $lucy_fg
    filesize: $lucy_fg
    duration: $lucy_fg
    date: $lucy_fg
    range: $lucy_fg
    float: $lucy_fg
    string: $lucy_fg
    nothing: $lucy_fg
    binary: $lucy_fg
    cellpath: $lucy_fg
    row_index: magenta
    record: $lucy_fg
    list: $lucy_fg
    block: $lucy_fg
    hints: dark_gray

    # shapes are used to change the cli syntax highlighting
    shape_garbage: $lucy_error
    shape_binary: $lucy_fg
    shape_int: $lucy_fg
    shape_float: $lucy_fg
    shape_range: $lucy_fg
    shape_internalcall: $lucy_fg
    shape_external: $lucy_fg
    shape_externalarg: $lucy_fg
    shape_literal: $lucy_fg
    shape_operator: $lucy_fg
    shape_signature: $lucy_fg
    shape_string: $lucy_fg
    shape_string_interpolation: $lucy_fg
    shape_datetime: $lucy_fg
    shape_list: $lucy_fg
    shape_table: $lucy_fg
    shape_record: $lucy_fg
    shape_block: $lucy_fg
    shape_filepath: $lucy_fg
    shape_globpattern: $lucy_fg
    shape_variable: $lucy_fg
    shape_flag: $lucy_fg
    shape_custom: $lucy_fg
    shape_nothing: $lucy_fg
}

# The default config record. This is where much of your global configuration is setup.
$env.config = {
  ls: {
    use_ls_colors: true
  }
  rm: {
    always_trash: false
  }
  table: {
    mode: rounded
    trim: {
      methodology: wrapping, # truncating
      # A strategy which will be used by 'wrapping' methodology
      wrapping_try_keep_words: true,
      # A suffix which will be used with 'truncating' methodology
      # truncating_suffix: "..."
    }
  }
  history: {
    max_size: 10000
    sync_on_enter: true
    file_format: "plaintext" # "sqlite" or "plaintext"
  }
  completions: {
    case_sensitive: false # set to true to enable case-sensitive completions
    quick: true  # set this to false to prevent auto-selecting completions when only one remains
    partial: true  # set this to false to prevent partial filling of the prompt
    algorithm: "prefix"  # prefix, fuzzy
    external: {
      enable: true # set to false to prevent nushell looking into $env.PATH to find more suggestions, `false` recommended for WSL users as this look up my be very slow
      max_results: 100 # setting it lower can improve completion performance at the cost of omitting some options
    }
  }
  filesize: {
    unit: binary # metric, binary, or a fixed unit like kb, kib, mb, mib
  }
  color_config: $lucy_theme
  footer_mode: 25 # always, never, number_of_rows, auto
  float_precision: 2
  buffer_editor: "nvim"
  use_ansi_coloring: true
  edit_mode: vi
  show_banner: false # true or false to enable or disable the banner

  menus: [
      # Configuration for default nushell menus
      # Note the lack of souce parameter
      {
        name: completion_menu
        only_buffer_difference: false
        marker: "| "
        type: {
            layout: columnar
            columns: 4
            col_width: 20   # Optional value. If missing all the screen width is used to calculate column width
            col_padding: 2
        }
        style: {
            text: green
            selected_text: green_reverse
            description_text: yellow
        }
      }
      {
        name: history_menu
        only_buffer_difference: true
        marker: "? "
        type: {
            layout: list
            page_size: 10
        }
        style: {
            text: green
            selected_text: green_reverse
            description_text: yellow
        }
      }
      {
        name: help_menu
        only_buffer_difference: true
        marker: "? "
        type: {
            layout: description
            columns: 4
            col_width: 20   # Optional value. If missing all the screen width is used to calculate column width
            col_padding: 2
            selection_rows: 4
            description_rows: 10
        }
        style: {
            text: green
            selected_text: green_reverse
            description_text: yellow
        }
      }
      # Example of extra menus created using a nushell source
      # Use the source field to create a list of records that populates
      # the menu
      {
        name: commands_menu
        only_buffer_difference: false
        marker: "# "
        type: {
            layout: columnar
            columns: 4
            col_width: 20
            col_padding: 2
        }
        style: {
            text: green
            selected_text: green_reverse
            description_text: yellow
        }
        source: { |buffer, position|
            scope commands
            | where name =~ $buffer
            | each { |it| {value: $it.name description: $it.description} }
        }
      }
      {
        name: vars_menu
        only_buffer_difference: true
        marker: "# "
        type: {
            layout: list
            page_size: 10
        }
        style: {
            text: green
            selected_text: green_reverse
            description_text: yellow
        }
        source: { |buffer, position|
            scope variables
            | where name =~ $buffer
            | sort-by name
            | each { |it| {value: $it.name description: $it.type} }
        }
      }
      {
        name: commands_with_description
        only_buffer_difference: true
        marker: "# "
        type: {
            layout: description
            columns: 4
            col_width: 20
            col_padding: 2
            selection_rows: 4
            description_rows: 10
        }
        style: {
            text: green
            selected_text: green_reverse
            description_text: yellow
        }
        source: { |buffer, position|
            scope commands
            | where name =~ $buffer
            | each { |it| {value: $it.name description: $it.description} }
        }
      }
  ]
  keybindings: [
    {
      name: completion_menu
      modifier: none
      keycode: tab
      mode: [emacs, vi_normal, vi_insert] # edit_mode is vi, so emacs alone left Tab unbound
      event: {
        until: [
          { send: menu name: completion_menu }
          { send: menunext }
        ]
      }
    }
    {
      name: completion_previous
      modifier: shift
      keycode: backtab
      mode: [emacs, vi_normal, vi_insert] # Note: You can add the same keybinding to all modes by using a list
      event: { send: menuprevious }
    }
    {
      name: history_menu
      modifier: control
      keycode: char_r
      mode: emacs
      event: { send: menu name: history_menu }
    }
    {
      name: next_page
      modifier: control
      keycode: char_x
      mode: emacs
      event: { send: menupagenext }
    }
    {
      name: undo_or_previous_page
      modifier: control
      keycode: char_z
      mode: emacs
      event: {
        until: [
          { send: menupageprevious }
          { edit: undo }
        ]
       }
    }
    {
      name: yank
      modifier: control
      keycode: char_y
      mode: emacs
      event: {
        until: [
          {edit: pastecutbufferafter}
        ]
      }
    }
    {
      name: unix-line-discard
      modifier: control
      keycode: char_u
      mode: [emacs, vi_normal, vi_insert] # edit_mode is vi, so emacs alone left Tab unbound
      event: {
        until: [
          {edit: cutfromlinestart}
        ]
      }
    }
    {
      name: kill-line
      modifier: control
      keycode: char_k
      mode: [emacs, vi_normal, vi_insert] # edit_mode is vi, so emacs alone left Tab unbound
      event: {
        until: [
          {edit: cuttolineend}
        ]
      }
    }
    # Keybindings used to trigger the user defined menus
    {
      name: commands_menu
      modifier: control
      keycode: char_t
      mode: [emacs, vi_normal, vi_insert] # edit_mode is vi, so emacs alone left Tab unbound
      event: { send: menu name: commands_menu }
    }
    {
      name: commands_with_description
      modifier: control
      keycode: char_s
      mode: [emacs, vi_normal, vi_insert] # edit_mode is vi, so emacs alone left Tab unbound
      event: { send: menu name: commands_with_description }
    }
    {
      name: change_dir_with_fzf
      modifier: control
      keycode: char_f
      mode: [emacs, vi_normal, vi_insert] # edit_mode is vi, so emacs alone left Tab unbound
      event: {
        send: executehostcommand,
        cmd: 'cd (open --raw ~\docs\bookmarks | fzf)'
      }
    }
    {
      name: lf_cd
      modifier: control
      keycode: char_o
      mode: [emacs, vi_normal, vi_insert] # edit_mode is vi, so emacs alone left Tab unbound
      event: {
        send: executehostcommand,
        cmd: 'lf'
      }
    }
  ]
}

# OSC 133/633 prompt marks confuse ConPTY on Windows: prompt redraws drift down a line per keystroke
if ($nu.os-info.name == "windows") {
  $env.config.shell_integration.osc133 = false
  $env.config.shell_integration.osc633 = false
}

# Download English .srt subtitles for every movie under E:\Movies (see E:\Movies\download_subs.py)
def download_subs [
  root?: path              # folder to scan (default: E:\Movies)
  --lang: string = "eng"   # OpenSubtitles 3-letter language code (eng, spa, ...)
  --ext: string = "mp4"    # comma-separated video extensions, e.g. mp4,mkv
  --force                  # overwrite existing .srt files
  --dry-run                # show matches without downloading
] {
  mut args = ["--lang" $lang "--ext" $ext]
  if $force { $args = ($args | append "--force") }
  if $dry_run { $args = ($args | append "--dry-run") }
  if $root != null { $args = ($args | append $root) }
  ^py -3 'E:\Movies\download_subs.py' ...$args
}
