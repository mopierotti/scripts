function setup-sites {
  export SITE_USERNAME=$1
  export SITE_DEFAULT_DOMAIN=$2
  SITE_BASEDIR=$3
  export SITE_LOG_APPSERVER=$SITE_BASEDIR/$4
  export SITE_LOG_AUDIT=$SITE_BASEDIR/$5
  export SITE_BUILD_INFO=$SITE_BASEDIR/$6
  export SITE_PLUGINS=$SITE_BASEDIR/$7
}

function setup-ec2 {
  export EC2_HOME=$1
  export EC2_CERT=$2
  export EC2_PRIVATE_KEY=$3
  export PATH=$EC2_HOME/bin:$PATH
}

function site-list {
  ec2dtag | awk '/instance.*Name.*site:/ {print $6}' | sort
}

alias qssh='ssh -e none -o StrictHostKeyChecking=no'
function ssh-site {
  sitename=$(site-default-domain $1)
  shift
  ssh-forget $sitename
  qssh $SITE_USERNAME@$sitename $*
}

function site-info {
  ssh-site $* grep = $SITE_BUILD_INFO
}

function site-default-domain {
  sitename=$1
  if [[ ! $sitename =~ .*$SITE_DEFAULT_DOMAIN ]]; then
    sitename=$sitename.$SITE_DEFAULT_DOMAIN
  fi
  echo $sitename
}

function site-plugins-transfer {
  srchost=$(site-default-domain $1)
  dsthost=$(site-default-domain $2)
  scp -3 $SITE_USERNAME@$srchost:$SITE_PLUGINS/*.jar $SITE_USERNAME@$dsthost:$SITE_PLUGINS
}

function site-plugins-download {
  srchost=$(site-default-domain $1)
  dest=${2-.}
  scp $SITE_USERNAME@$srchost:$SITE_PLUGINS/*.jar $dest
}

function site-plugins-upload {
  dsthost=$(site-default-domain $1)
  src=${2-.}
  scp $src/*.jar $SITE_USERNAME@$dsthost:$SITE_PLUGINS
}

function site-exceptions {
  ssh-site $* cat $SITE_LOG_APPSERVER | awk '/Exception/,/^$/ {print $0}'
}

function site-activity {
  ssh-site $* tail -f $SITE_LOG_AUDIT
}
