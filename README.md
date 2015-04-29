A custom text object for selecting julia blocks in ViM.

Depends on Kana's [textobj-user plugin][u] and the [julia-vim plugin][jv].

Also requires that the matchit.vim plugin is enabled. Either ensure that the
following line is included somewhere in your vimrc file:

    runtime macros/matchit.vim

or add [edsono/vim-matchit][matchit] to your plugins via your favourite plugin
manager.

It is also essential that you enable filetype plugins, and disable Vi
compatible mode. Placing these lines in your vimrc file will do this:

    set nocompatible
    if has("autocmd")
      filetype indent plugin on
    endif

Usage
=====

When textobj-juliablock is installed you will gain two new text objects, which
are triggered by `aj` and `ij` respectively. These follow Vim convention, so
that `aj` selects _all_ of a julia block, and `ij` selects the _inner_ portion
of a juliablock.

In julia, a block is always closed with the `end` keyword. Ruby blocks may be
opened using one of several keywords, including `module`, `type`, `function`,
`if` and `for`. This example demonstrates a few of these:

    module Foo
    function Bar()
      for i in 1:3
        println(i)
      end
    end
    end

Suppose your cursor was positioned on the word `function`. Typing `vaj` would
enable visual mode selecting _all_ of the method definition. Your selection
would comprise the following lines:

    function Bar()
      for i in 1:3
        println(i)
      end
    end

Whereas if you typed `vij`, you would select everything _inside_ of the method
definition, which looks like this:

    for i in 1:3
      println(i)
    end

Note that the `aj` and `ij` text objects always enable _visual line_ mode,
even if you were in visual character or block mode before you triggered the
juliablock text object.

Note too that the `aj` and `ij` text objects always position your cursor on
the `end` keyword. If you want to move to the top of the selection, you can do
so with the `o` key.

Limitations
-----------

Some text objects in Vim respond to a count. For example, the `a{` text object
will select _all_ of the current `{}` delimited block, but if you prefix it
with the number 2 (e.g. `v2i{`) then it will select all of the block that
contains the current block. The juliablock text object does not respond in this
way if you prefix a count. This is due to a limitation in the [textobj-user
plugin][u].

However, you can achieve a similar effect by repeating the juliablock
text-object manually. So if you press `vaj` to select the current julia block,
you can expand your selection outwards by repeating `aj`, or contract your
selection inwards by repeating `ij`.

Generating a vimball
--------------------

To distribute the script on [vim.org][s] wrap it up as a vimball by following these steps:

* open the file `vimballer` in Vim
* set the variable `g:vimball_home` to the development directory of this plugin
  (e.g. run: `:let g:vimball_home='~/dotfiles/vim/bundle/textobj-juliablock'`)
* visually select all lines in `vimballer` file
* run `'<,'>MkVimball! textobj-juliablock.vba`

That should create a file called `textobj-juliablock.vba` which you can upload to [vim.org][s].

[u]: https://github.com/kana/vim-textobj-user
[jv]: https://github.com/JuliaLang/julia-vim
[matchit]: https://github.com/edsono/vim-matchit
[pathogen]: http://www.vim.org/scripts/script.php?script_id=2332
[s]: http://www.vim.org/scripts/index.php

Credits
=======

This plugin is a fork of [textobj-rubyblock][] which was built by [Drew Neil][drewneil],
heavily adapted to work in [Julia][] rather than Ruby, and it's made possible thanks to
the [textobj-user][kana-git] plugin by [Kana][].

[Kana]: http://whileimautomaton.net/
[textobj-user]: http://www.vim.org/scripts/script.php?script_id=2100
[kana-git]: https://github.com/kana/vim-textobj-user
[textobj-rubyblock]: https://github.com/nelstrom/vim-textobj-rubyblock
[drewneil]: http://drewneil.com
[Julia]: http://julialang.org
