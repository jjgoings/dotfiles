# .zshenv - Universal environment variables (loaded for all zsh instances)

# Editor preference
[[ -x /usr/bin/vim ]] && export EDITOR=/usr/bin/vim

# Core environment
export CLICOLOR=1
export LSCOLORS=Gxfxcxdxbxegedabagacad

# Compiler toolchain (update for your use-cases)
# export CC=/opt/homebrew/opt/llvm/bin/clang
# export CXX=/opt/homebrew/opt/llvm/bin/clang++
# export FC=gfortran
# export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
# export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"

# Application homes
# export JMOL_HOME="$HOME/micromamba/envs/main/share/jmol/"
