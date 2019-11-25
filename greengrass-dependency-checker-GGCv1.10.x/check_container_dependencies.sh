check_container_dependencies() {
    local user_provided_config_file="$1"

    info ""
    info "----------------(Optional) Greengrass container dependency check----------------"

    check_kernel_configs "$user_provided_config_file" 
    check_cgroups_mounted
}
