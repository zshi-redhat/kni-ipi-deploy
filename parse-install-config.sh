#!/bin/bash

usage() {
    cat <<EOM
    Usage: $(basename "$0")  [path/]install-config.yaml
        Generate settings.sh file from install-config.yaml file
EOM
    exit 0
}

declare -A MMAP
declare -A OUTMAP

parse_install_config() {
    local file="$1"

    # shellcheck disable=SC2016
    if ! VALUES=$(yq 'paths as $p | [ ( [ $p[] | tostring ] | join(".") ) , ( getpath($p) | tojson ) ] | join(" ")' "$file"); then
        printf "Error during parsing...%s\n" "$file"

        return 1
    fi

    mapfile -t LINES < <(echo "$VALUES" | sed -e 's/^"//' -e 's/"$//' -e 's/\\\\\\"/"/g' -e 's/\\"//g')

    declare -g -A INSTALL_CONFIG
    for line in "${LINES[@]}"; do
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
    [API_VIP]="platform.baremetal.apiVIP"
    [INGRESS_VIP]="platform.baremetal.ingressVIP"
    [DNS_VIP]="platform.baremetal.dnsVIP"

    # Provisioning host
    [MASTER_0_MAC]="platform.baremetal.hosts.[master-0].bootMACAddress"
    [MASTER_1_MAC]="platform.baremetal.hosts.[master-1].bootMACAddress"
    [MASTER_2_MAC]="platform.baremetal.hosts.[master-2].bootMACAddress"
    [WORKER_0_MAC]="platform.baremetal.hosts.[master-0].bootMACAddress"
    [WORKER_1_MAC]="platform.baremetal.hosts.[master-1].bootMACAddress"
)

map_install_config() {
    local file="$1"

    local error=false

    mapfile -t hosts < <(printf '%s\n' "${LINES[@]}" | sed -nre 's/^platform.baremetal.hosts.([0-9]+).name\s+([a-z0-9-]+)/\2:\1/p')
    for pair in "${hosts[@]}"; do
        MMAP[${pair%%:*}]="${pair##*:}"
    done

    for var in "${!INSTALL_CONFIG_MAP[@]}"; do
        map_rule=${INSTALL_CONFIG_MAP[$var]}

        reg='.*\[([A-Za-z0-9-]+)\].*'

        if [[ $map_rule =~ $reg ]]; then
            name="${BASH_REMATCH[1]}"
            if [[ ! "${MMAP[$name]}" ]]; then
                printf "Invalid rule or missing value: %s\n" "$map_rule"
                exit 1
            fi
            map_rule=${map_rule/\[$name\]/${MMAP[$name]}}
        fi

        if [[ $map_rule =~ ^\| ]]; then
            map_rule=${map_rule#|}
        else
            if [[ -z "${INSTALL_CONFIG[$map_rule]}" ]]; then
                printf "Error: %s is unset in %s, must be set\n\n" "$map_rule" "$file"
            fi
        fi
        OUTMAP[$var]="${INSTALL_CONFIG[$map_rule]}"
    done

    [[ $error =~ false ]] && return 0 || return 1
}

print_install_config() {
    for var in "${!INSTALL_CONFIG_MAP[@]}"; do
        printf "[%s]=\"%s\"\n" "$var" "${INSTALL_CONFIG[${INSTALL_CONFIG_MAP[$var]}]}"
    done
}

store_install_config() {

    mapfile -t sorted < <(printf '%s\n' "${!OUTMAP[@]}" | sort)

    ofile="settings.sh"
    {
        printf "#!/bin/bash\n\n"

        for var in "${sorted[@]}"; do
            printf "export %s=\"%s\"\n" "$var" "${OUTMAP[$var]}"
        done

    } >"$ofile"
}

if [ "$#" -lt 1 ]; then
    usage
fi

VERBOSE="false"
export VERBOSE

while getopts ":hv" opt; do
    case ${opt} in
    v)
        VERBOSE="true"
        ;;
    h)
        usage
        exit 0
        ;;
    \?)
        echo "Invalid Option: -$OPTARG" 1>&2
        exit 1
        ;;
    esac
done
shift $((OPTIND - 1))

parse_install_config "$1" || exit 1
map_install_config "$1" || exit 1
store_install_config || exit 1
