# Nushell Config File

alias e = zed
alias f = cd (open --raw ~\docs\bookmarks | fzf)
alias ef = e (open --raw ~\docs\bookmarks | fzf)
alias ba = (echo $"($env.PWD)\n" | save ~\docs\bookmarks --append)
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

let-env FZF_DEFAULT_OPTS = "--color=hl:#ffb8f6,fg+:-1,hl+:#ffb8f6,info:#ffb8f6,prompt:#ffb8f6,pointer:#ff91f0,marker:-1,spinner:#ffb8f6,header:#ffb8f6,bg:-1,bg+:-1"

alias config = git $"--git-dir=($env.USERPROFILE)/.cfg/" $"--work-tree=($env.USERPROFILE)"
alias lg = lazygit
alias lconfig = lazygit $"--git-dir=($env.USERPROFILE)/.cfg/" $"--work-tree=($env.USERPROFILE)"

let lucy_white = "#ffffff"
let lucy_error = { fg: "#FFFFFF" bg: "#FF0000" attr: b}

let dark_theme = {
    # color for nushell primitives
    separator: white
    leading_trailing_space_bg: { attr: n } # no fg, no bg, attr none effectively turns this off
    header: { fg: "#ffbdf6"}
    empty: blue
    bool: white
    int: white
    filesize: white
    duration: white
    date: white
    range: white
    float: white
    string: white
    nothing: white
    binary: white
    cellpath: white
    row_index: { fg: "#ffbdf6"}
    record: white
    list: white
    block: white
    hints: dark_gray

    # shapes are used to change the cli syntax highlighting
    shape_garbage: $lucy_error
    shape_binary: $lucy_white
    shape_int: $lucy_white
    shape_float: $lucy_white
    shape_range: $lucy_white
    shape_internalcall: $lucy_white
    shape_external: $lucy_white
    shape_externalarg: $lucy_white
    shape_literal: $lucy_white
    shape_operator: $lucy_white
    shape_signature: $lucy_white
    shape_string: $lucy_white
    shape_string_interpolation: $lucy_white
    shape_datetime: $lucy_white
    shape_list: $lucy_white
    shape_table: $lucy_white
    shape_record: $lucy_white
    shape_block: $lucy_white
    shape_filepath: $lucy_white
    shape_globpattern: $lucy_white
    shape_variable: $lucy_white
    shape_flag: $lucy_white
    shape_custom: $lucy_white
    shape_nothing: $lucy_white
}

# The default config record. This is where much of your global configuration is setup.
let-env config = {
  ls: {
    use_ls_colors: true
  }
  rm: {
    always_trash: false
  }
  cd: {
    abbreviations: false # set to true to allow you to do things like cd s/o/f and nushell expand it to cd some/other/folder
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
    metric: false
    format: "auto" # b, kb, kib, mb, mib, gb, gib, tb, tib, pb, pib, eb, eib, zb, zib, auto
  }
  color_config: $dark_theme
  use_grid_icons: true
  footer_mode: "25" # always, never, number_of_rows, auto
  float_precision: 2
  buffer_editor: "nvim"
  use_ansi_coloring: true
  edit_mode: vi
  shell_integration: false
  # A strategy of managing table view in case of limited space.
  show_banner: false # true or false to enable or disable the banner

  hooks: {
    pre_prompt: [{
      $nothing  # replace with source code to run before the prompt is shown
    }]
    pre_execution: [{
      $nothing  # replace with source code to run before the repl input is run
    }]
    env_change: {
      PWD: [{|before, after|
        $nothing  # replace with source code to run if the PWD environment is different since the last repl input
      }]
    }
  }
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
            $nu.scope.commands
            | where command =~ $buffer
            | each { |it| {value: $it.command description: $it.usage} }
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
            $nu.scope.vars
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
            $nu.scope.commands
            | where command =~ $buffer
            | each { |it| {value: $it.command description: $it.usage} }
        }
      }
  ]
  keybindings: [
    {
      name: completion_menu
      modifier: none
      keycode: tab
      mode: emacs # Options: emacs vi_normal vi_insert
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
      mode: [emacs, vi_normal, vi_insert]
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
      mode: [emacs, vi_normal, vi_insert]
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
      mode: [emacs, vi_normal, vi_insert]
      event: { send: menu name: commands_menu }
    }
    {
      name: commands_with_description
      modifier: control
      keycode: char_s
      mode: [emacs, vi_normal, vi_insert]
      event: { send: menu name: commands_with_description }
    }
    {
      name: change_dir_with_fzf
      modifier: control
      keycode: char_f
      mode: [emacs, vi_normal, vi_insert]
      event: {
        send: executehostcommand,
        cmd: 'cd (open --raw ~\docs\bookmarks | fzf)'
      }
    }
    {
      name: lf_cd
      modifier: control
      keycode: char_o
      mode: [emacs, vi_normal, vi_insert]
      event: {
        send: executehostcommand,
        cmd: 'lf'
      }
    }
  ]
}
