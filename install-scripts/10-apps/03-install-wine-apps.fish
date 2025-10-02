#!/usr/bin/env fish
source install-scripts/library/print-utils.fish
source install-scripts/library/wine-utils.fish

print_info "Installing wine applications"

install_wine_app \
    modorganizer \
    ModOrganizer2/modorganizer \
    "dotnet48 vcrun2019 corefonts" \
    "ModOrganizer2/ModOrganizer.exe"

print_success Done
