#!/usr/bin/env bash
# Project: myproject
# Description:
# Path: /path/to/project

switch() {
    cd /path/to/project
    export PJ_ROOT="/path/to/project"
    export PJ_CMDS="$PJ_ROOT/.pjcmds"
}