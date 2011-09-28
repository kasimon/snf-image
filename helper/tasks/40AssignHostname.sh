#! /bin/sh

### BEGIN TASK INFO
# Provides:		AssignHostname
# Requires:		InstallUnattend
# Short-Description:	Assign the Hostname of Computer Name in the instance
### END TAST INFO

set -e
. /usr/share/snf-image/common.sh

windows_hostname() {
    local target=$1
    local password=$2

    local tmp_unattend=`mktemp` || exit 1
    CLEANUP+=("rm $tmp_unattend")

    echo -n "Assigning new computer name..."

    local namespace="urn:schemas-microsoft-com:unattend"
    
    $XMLSTARLET ed -N x=$namespace -u "/x:unattend/x:settings/x:component/x:ComputerName" -v $password "$target/Unattend.xml" > $tmp_unattend

    cat $tmp_unattend > "$target/Unattend.xml"
    echo done
}

linux_hostname() {
    local target=$1
    local hostname=$2

    local distro=$(get_base_distro $target)

    case "$distro" in
        debian)
            echo "$hostname" > $target/etc/hostname;;
        redhat)
            sed -ie "s/HOSTNAME=.*$/HOSTNAME=$hostname/g" $target/etc/sysconfig/network;;
        slackware|suse)
        #local domain=$(sed -e 's/^[^\.]*//g' < /etc/HOSTNAME)
        
        # In slackware hostname and domain name are joined together. For now I
        # will not retain the domain name.
        
        echo $hostname > ${target}/etc/HOSTNAME;;
    gentoo)
        sed -ie "s/\(\(HOSTNAME\)\|\(hostname\)\)=.*$/\1=\"$hostname\"/" $target/etc/conf.d/hostname;;
    esac

    # Some Linux distributions assign the hostname to 127.0.1.1 in order to be
    # resolvable to an IP address. Lets replace this if found in /etc/hosts
    sed -ie "s/^[[:blank:]]*127\.0\.1\.1[[:blank:]].\+$/127.0.1.1\t$hostname/" $target/etc/hosts
}

if [ -z "$SNF_IMAGE_TARGET" -o ! -d "$SNF_IMAGE_TARGET" ]; then
    log_error "Missing target directory"	
fi

if [ -z "$SNF_IMAGE_HOSTNAME" ]; then
    log_error "Hostname is missing"
fi

if [ "$SNF_IMAGE_TYPE" = "ntfsdump" ]; then
    windows_hostname $SNF_IMAGE_TARGET $SNF_IMAGE_PASSWORD
elif [ "$SNF_IMAGE_TYPE" = "extdump" ]; then
    linux_hostname $SNF_IMAGE_TARGET $SNF_IMAGE_PASSWORD
fi

echo "done"

cleanup
trap - EXIT

exit 0

# vim: set sta sts=4 shiftwidth=4 sw=4 et ai :
