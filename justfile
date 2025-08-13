#!/usr/bin/env -S just --justfile
# just reference  : https://just.systems/man/en/

@list:
    just --list

default: build

build:
    @dub build

run:
    @cd /g/raytest && dub run

reuse:
    @reuse --suppress-deprecation lint

setup:
    #!/usr/bin/env bash
    __has() {
        command -v $@ 2>&1 >/dev/null && return 0 || return 1
    }
    DIST="$(lsb_release -i | awk -F ':\\s*' '{print $2}')"
    if [ "$DIST" == "Arch" ]; then
        __has yay && echo "Found yay, using it" || echo "Missing yay, using pacman"
        echo ""
        __has yay && \
            yay -S vulkan-devel vulkan-validation-layers vulkan-headers vulkan-tools --needed || \
            sudo pacman -S vulkan-devel vulkan-validation-layers vulkan-headers vulkan-tools --needed
        echo ""
        echo "======================================================================================"
        echo "Install either of nvidia-utils, vulkan-intel, vulkan-radeon packages matching your GPU"
        echo "======================================================================================"
        exit 0
    fi
    echo "Unsupported setup distro"


test:
    #!/bin/bash
    >&2 echo "Error: Message"
    echo "Info: Message"
    >&2 echo "Error: Message 2"
    echo "Info: Message 2"

