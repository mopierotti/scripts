# Aliases for internal build system

alias build="ant -s build/build.xml"
alias qbuild="build -Dskip.gwt=true"
alias crash="build clean-eclipse eclipse || build eclipse-projects-clean eclipse-projects"
alias rebuild='qbuild -l build1.log sound dev || build -l build2.log sound dev || crash -l build3.log sound dev || build -l build4.log sound clean dev'

function bisectable {
  from=${1-@{u}}
  to=${2-HEAD}
  target=${3-all-classes}
  clean=${4-clean}

  if [ -e failed.log ]; then
    rm failed.log
  fi

  rm build-*.log

  mkdir -p .bisectable-cache
  touch .bisectable-cache/{good,bad}
  refresh=0

  for i in `git rev-list --reverse --no-merges --first-parent ${from}..${to}`; do
    id=`git show $i | git patch-id | awk '{print $1}'`
    if [ "$refresh" -eq "1" ]; then
      grep -v $id .bisectable-cache/good > .bisectable-cache/good-refresh
      grep -v $id .bisectable-cache/bad > .bisectable-cache/bad-refresh
      mv .bisectable-cache/good{-refresh,}
      mv .bisectable-cache/bad{-refresh,}
    fi
    if [ `grep --quiet $id .bisectable-cache/good` ]; then
      echo "Skipping GOOD: $i"
    elif [ `grep --quiet $id .bisectable-cache/bad` ]; then
      echo "Skipping BAD: $i"
      echo $i >> failed.log
    else
      refresh=1
      git checkout $i
      ant -s build/build.xml -l build.log $target
      if [ $? != 0 ]; then
        mv build.log build-${i}.log
        ant -s build/build.xml -l build.log $clean $target
      fi
      if [ $? == 0 ]; then
        echo $id $i >> .bisectable-cache/good
      else
        mv build.log build-clean-${i}.log
        echo $i >> failed.log
        echo $id $i >> .bisectable-cache/bad
      fi
#      grep -E "^BUILD|^Total time" build-*${i}.log
#      grep -E "BUILD|Total time" build-${i}.log | tail -n 2
    fi
  done

  if [ -e failed.log ]; then
    less failed.log
  fi
}
