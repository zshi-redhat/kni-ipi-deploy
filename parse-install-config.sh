#!/bin/bash

parse_install_config() {
    local file="$1"
    local manifest_dir=$2

    # shellcheck disable=SC2016
    if ! values=$(yq 'paths as $p | [ ( [ $p[] | tostring ] | join(".") ) , ( getpath($p) | tojson ) ] | join(" ")' "$file"); then
        printf "Error during parsing...%s\n" "$file"

        return 1
    fi

    mapfile -t lines < <(echo "$values" | sed -e 's/^"//' -e 's/"$//' -e 's/\\\\\\"/"/g' -e 's/\\"//g')

    declare -g -A INSTALL_CONFIG
    for line in "${lines[@]}"; do
        # create the associative array
        INSTALL_CONFIG[${line%% *}]=${line#* }
    done
}

#  Rules that start with | are optional

declare -g -A INSTALL_CONFIG_MAP=(
    [CLUSTER_DOMAIN]="baseDomain"
    [MASTER_COUNT]="controlPlane.replicas"
    [WORKER_COUNT]="compute.replicas"
    [CLUSTER_NAME]="metadata.name"
    [API_VIP]="platform.apiVIP"
    [INGRESS_VIP]="platform.ingressVIP"
    [DNS_VIP]="platform.dnsVIP"

    # Provisioning host
    [MASTER_0_BMC]="platform.hosts.0.bootMACAddress"

    [PROV_INTF_IP]="provisioningInfrastructure.provHost.interfaces.provisioningIpAddress"
    [PROV_BRIDGE]="provisioningInfrastructure.provHost.bridges.provisioning"
    [EXT_INTF]="provisioningInfrastructure.provHost.interfaces.external"
    [BM_IP_CIDR]="provisioningInfrastructure.network.baremetalIpCidr"
    [BM_IP_DHCP_START]="provisioningInfrastructure.network.baremetalDHCPStart"
    [BM_IP_DHCP_END]="provisioningInfrastructure.network.baremetalDHCPEnd"
    [BM_INTF]="provisioningInfrastructure.provHost.interfaces.baremetal"
    [BM_INTF_IP]="provisioningInfrastructure.provHost.interfaces.baremetalIpAddress"
    [BM_BRIDGE]="provisioningInfrastructure.provHost.bridges.baremetal"
    [CLUSTER_DNS]="provisioningInfrastructure.network.dns.cluster"
    [CLUSTER_DEFAULT_GW]="provisioningInfrastructure.network.baremetalGWIP"
    [EXT_DNS1]="provisioningInfrastructure.network.dns.external1"
    [EXT_DNS2]="|provisioningInfrastructure.network.dns.external2"
    [EXT_DNS3]="|provisioningInfrastructure.network.dns.external3"
    [PROVIDE_DNS]="provisioningInfrastructure.provHost.services.clusterDNS"
    [PROVIDE_DHCP]="provisioningInfrastructure.provHost.services.baremetalDHCP"
    [PROVIDE_GW]="provisioningInfrastructure.provHost.services.baremetalGateway"
)

map_install_config() {
    status="$1"

    local error=false

    for var in "${!INSTALL_CONFIG_MAP[@]}"; do
        map_rule=${INSTALL_CONFIG_MAP[$var]}

        if [[ $map_rule =~ ^\| ]]; then
            map_rule=${map_rule#|}
        else
            if [[ -z "${INSTALL_CONFIG[$map_rule]}" ]]; then
                printf "Error: %s is unset in %s, must be set\n\n" "$map_rule" "./cluster/site-config.yaml"
                error=true
            fi
        fi
        read -r "${var?}" <<<"${INSTALL_CONFIG[${INSTALL_CONFIG_MAP[$var]}]}"

        [[ $status =~ true ]] && printf "%s: %s\n" "${map_rule//./\/}" "${var}"
    done

    [[ $error =~ false ]] && return 0 || return 1
}

print_install_config() {
    for var in "${!INSTALL_CONFIG_MAP[@]}"; do
        printf "[%s]=\"%s\"\n" "$var" "${INSTALL_CONFIG[${INSTALL_CONFIG_MAP[$var]}]}"
    done
}

store_install_config() {

    mapfile -t sorted < <(printf '%s\n' "${!INSTALL_CONFIG[@]}" | sort)

    ofile="$BUILD_DIR/site_vals.sh"
    {
        printf "#!/bin/bash\n\n"

        for v in "${sorted[@]}"; do
            printf "INSTALL_CONFIG[%s]=\'%s\'\n" "$v" "${INSTALL_CONFIG[$v]}"
        done

    } >"$ofile"
}
