#!/usr/bin/env bash
# Project: myproject
# Description:
# Path: /path/to/project

switch() {
    cd /path/to/project
    export ROOT="/path/to/project"
    export PJ_CMDS="$ROOT/.pjcmds"
}