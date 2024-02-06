test *args='':
    # pytest tests/
    python -m pytest tests/ {{args}}

test-with-stdout:
    python -m pytest --capture=tee-sys tests/

link-fonts:
    ln -s "$(nix build --no-link --print-out-paths .\#soundfonts)/share/soundfonts" .

start-fluidsynth-server:
    fluidsynth --server soundfonts/FluidR3_GM2-2.sf2

start-vmpk:
    vmpk

midi2wav name:
    fluidsynth --no-shell --no-midi-in -r 44100 \
        {{justfile_directory()}}soundfonts/FluidR3_GM2-2.sf2 \
        {{name}}.mid -F {{name}}.wav

poetry *args='':
    nix run .\#poetry -- {{args}}
    
# record-vmpk:
