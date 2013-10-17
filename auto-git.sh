function setup-git {
  export MASTER=$1
  export REMOTES=$2
}

function git-aliases {
  git config --global alias.g "grep -n"
  git config --global alias.s "status -sb"
  git config --global alias.neighborhood "for-each-ref --sort='committerdate' --format='%(committerdate:short),%(refname),%(committername)'"
  git config --global alias.incoming "log ..@{u}"
  git config --global alias.outgoing "log @{u}.."
}

function git-hunt {
  target=$1
  base=$2
  if [ -z $base ]; then base=HEAD; fi
  git rev-list --merges --first-parent $target..$base | while read changeset; do git log --format="$changeset %H" $changeset^1..$changeset^2 | grep $target && git log -1 $changeset; done
}

function git-fixup {
  git ls-files -m | while read file; do
    echo "Diff for $file"
    git diff -U1 $* $file | grep ^@@ | cut -d @ -f 3 | sed -E -e "s/[-+]([0-9]+),([0-9]+)/-L\1,+\2/g" | awk -v f=$file '{
      system(sprintf("git blame -s $MASTER..HEAD %s %s", $1, f))
      print ""
      system(sprintf("git blame -s HEAD %s %s", $1, f))
      print ""
      system(sprintf("git blame -s %s %s", $2, f))
      print "-------------"
    }'
  done
}

function git-praise {
  git grep -n "$*" | cut -d: -f 1-2 | sed "s/:\(.*\)/ -L\1,+1/" | xargs -n 2 git --no-pager blame -fn $MASTER..HEAD
}

function git-review-today {
  git neighborhood refs/remotes \
  | grep `date +%Y-%m-%d` | cut -d , -f 2 \
  | while read i; do
    git log --source --decorate --dirstat --log-size --format=fuller -p $MASTER..$i
  done
}

function git-review-yesterday {
  git neighborhood refs/remotes \
  | grep `date -v-1d +%Y-%m-%d` | cut -d , -f 2 \
  | while read i; do
    git log --source --decorate --dirstat --log-size --format=fuller -p $MASTER..$i
  done
}

function git-stat-commit {
  git log --oneline --shortstat --format="commit %h" --no-merges $* \
  | awk '/commit/ {hash=$2} /file/ {printf("%s %s %s\n", hash, $4, $6)}'
}

function git-stat-overall {
  git log --oneline --shortstat --format="commit %h" --no-merges $* \
  | awk '/commit/ {hash=$2} /file/ {add+=$4; del+=$6} END {print add; print del}'
}

# Create branches for
# all pull requests
function github-pr-fetch {
  remote=$1
  git fetch $remote refs/pull/*:refs/heads/*
}
# Find pull requests that have not been
# merged into the given branch
function github-pr-no-merged {
  target=$1
  git branch --no-merged $target \
  | grep head | cut -d / -f 1 | sort -rn \
  | while read i; do
    git show-ref -q $i/merge && git name-rev --name-only --refs=refs/remotes/* $i/merge^1 \
    | grep -q $target && echo $i
  done
}

function git-review-fetch {
  url=git@github.com
  repo=$(git remote | while read i; do git config remote.$i.url | cut -d : -f 2 | cut -d / -f 2; done | sort -u)
  for i in $REMOTES; do
    git config remotes.$i > /dev/null
    if [ $? -eq 0 ]; then
      for j in $(git config remotes.$i); do
        git remote | grep -q $j || git remote add $j $url:$j/$repo
      done
    else
      git remote | grep -q $i || git remote add $i $url:$i/$repo
    fi
  done
  git fetch --multiple $REMOTES
}

function git-owner {
  filename=$1
  git blame -w -f -C $filename | awk '{print $3 " " $4}' | sort | uniq -c | sort -rn
}

# infer tracking branch
# of current branch
function git-tracking {
  git branch -vv | grep "^*" | grep -o "\[.*\]" | awk '{print substr($0,2,length($0)-2)}' | cut -d : -f 1
}

if [ -n "$SSH_TTY" ]; then
  PS1='\[\e[0;37m\]\t \[\e[0;32m\]\u@\h \[\e[0;36m\]\w\[\e[0;33m\]\n\[\e[0;37m\]\!\[\e[0m\]\$ '
else
  PS1='\[\e[0;37m\]\t \[\e[0;32m\]\u@\h \[\e[0;36m\]\w\[\e[0;33m\]$(__git_ps1 " (%s)")\n\[\e[0;37m\]\!\[\e[0m\]\$ '
fi

# Adds a * for modified files
# Adds a + for staged files
GIT_PS1_SHOWDIRTYSTATE=true

# Adds a $ for stashed files
GIT_PS1_SHOWSTASHSTATE=true

# Adds a % for untracked files
GIT_PS1_SHOWUNTRACKEDFILES=true

# < indicates behind
# > indicates ahead
# <> indicates diverged
GIT_PS1_SHOWUPSTREAM=auto