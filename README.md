# vrtnu.el
VRT NU support for Emacs

## Installation

To use `vrtnu.el`, you must have `mpv.el` installed from [this fork/branch](https://github.com/detvdl/mpv.el/tree/feat/play-from-url)

### Package.el

You will need to clone both repositories locally, since package.el does not have support for git-hosted packages

```shell
git clone -b feat/play-from-url https://github.com/detvdl/mpv.el
git clone https://github.com/detvdl/vrtnu.el
```

In your `init.el` or `.emacs`

```emacs-lisp
(add-to-list 'load-path "<path-to-mpv.el>" 'append)
(add-to-list 'load-path "<path-to-vrtnu.el>" 'append)
(require 'mpv)
(with-eval-after-load "mpv"
  (require 'vrtnu))
```

### [Straight.el](https://github.com/raxod502/straight.el)

```emacs-lisp
(straight-use-package
 '(mpv :type git :host github
       :repo "kljohann/mpv.el"
       :fork (:host github
              :repo "detvdl/mpv.el"
              :branch "feat/play-from-url")))

(with-eval-after-load "mpv"
  (straight-use-package
   '(vrtnu :type git :host github
           :repo "detvdl/vrtnu.el")))
```

or, with [use-package integration](https://github.com/raxod502/straight.el#integration-with-use-package-1)

```emacs-lisp
(use-package mpv
  :straight (mpv
             :host github :type git
             :repo "kljohann/mpv.el"
             :fork t))

(use-package vrtnu
  :after mpv
  :straight (vrtnu
             :host github :type git
             :repo "detvdl/vrtnu.el"))
```

## Configuration

Currently, the only required configuration is a file that contains your VRT account information.
It is defined in the format of an emacs-lisp association list.

Example:

```emacs-lisp
'((username . "<your-username>")
  (password . "<your-password>"))
```

To point `vrtnu.el` at your custom configuration file, you can set the `vrtnu-config-file` variable.:

```emacs-lisp
(setq vrtnu-config-file "<config-file-location>")
```

By default, it is set to `<emacs-home>/.vrtnu.eld`

## Usage

Invoke the interactive `vrt-news` command to be prompted with a selection of dates/times for the past week that are available to watch.
