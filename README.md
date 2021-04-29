# Flocke

Format Python source code asynchronously with multiple formatters.

## Settings

### autopep8 + yapf + add-trailing-comma

```vim
  let g:flocke_formatters = [
    \ {'cmd': 'autopep8', 'args': '-', 'range': '--line-range %d %d'},
    \ {'cmd': 'yapf', 'args': '', 'range': '--lines %d-%d'},
    \ {'cmd': 'add-trailing-comma', 'args': '-'},
    \ ]
```

### black

```vim
  let g:flocke_formatters = [
    \ {'cmd': 'black', 'args': '--quiet -'},
    \ ]
```
