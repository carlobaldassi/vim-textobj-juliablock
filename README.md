## THIS DOES NOT WORK YET!!! DO NOT USE ##

A custom text object for selecting julia blocks.

Depends on Kana's [textobj-user plugin][u]. Test suite requires [vspec][] (also by Kana).

Also requires that the matchit.vim plugin is enabled. Ensure that the following line is included somewhere in your vimrc file:

    runtime macros/matchit.vim

It is also essential that you enable filetype plugins, and disable Vi compatible mode. Placing these lines in your vimrc file will do this:

    set nocompatible
    if has("autocmd")
      filetype indent plugin on
    endif

Usage
=====

When textobj-juliablock is installed you will gain two new text objects, which
are triggered by `ar` and `ir` respectively. These follow Vim convention, so
that `ar` selects _all_ of a julia block, and `ir` selects the _inner_ portion
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

Suppose your cursor was positioned on the word `function`. Typing `var` would
enable visual mode selecting _all_ of the method definition. Your selection
would comprise the following lines:

    function Bar()
      for i in 1:3
        println(i)
      end
    end

Whereas if you typed `vir`, you would select everything _inside_ of the method
definition, which looks like this:

    for i in 1:3
      println(i)
    end

Note that the `ar` and `ir` text objects always enable _visual line_ mode,
even if you were in visual character or block mode before you triggered the
juliablock text object.

Note too that the `ar` and `ir` text objects always position your cursor on
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
text-object manually. So if you press `var` to select the current julia block,
you can expand your selection outwards by repeating `ar`, or contract your
selection inwards by repeating `ir`.

Development
===========

Running the specs
-----------------

Set up the testing environment by running this command from the project root:

    bundle install

Generating a vimball
--------------------

To distribute the script on [vim.org][s] wrap it up as a vimball by following these steps:

* open the file `vimballer` in Vim
* set the variable `g:vimball_home` to the development directory of this plugin (e.g. run: `:let g:vimball_home='~/dotfiles/vim/bundle/textobj-juliablock'`)
* visually select all lines in `vimballer` file
* run `'<,'>MkVimball! textobj-juliablock.vba`

That should create a file called `textobj-juliablock.vba` which you can upload to [vim.org][s].

[u]: https://github.com/kana/vim-textobj-user
[vspec]: https://github.com/kana/vim-vspec
[pathogen]: http://www.vim.org/scripts/script.php?script_id=2332
[s]: http://www.vim.org/scripts/index.php

Credits
=======

This plugin is a fork of [textobj-rubyblock][] which was built by [Drew Neil][me], adapted to work in [Julia][] rather than Ruby, and it's made possible thanks to the [textobj-user][kana-git] plugin by [Kana][].

[Kana]: http://whileimautomaton.net/
[textobj-user]: http://www.vim.org/scripts/script.php?script_id=2100
[kana-git]: https://github.com/kana/vim-textobj-user
[textobj-rubyblock]: https://github.com/nelstrom/vim-textobj-rubyblock
[me]: http://drewneil.com
[Julia]: http://julialang.org
