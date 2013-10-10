#!/usr/bin/env bash
set -e

echo "Setting up your local git repository"
echo "Enter the name of the repository you want to clone, i.e. (AppStore, Famigo-Sandbox, iOS-Sandbox):"
read REPO
if [ -z "$REPO" ]; then 
	echo "You must provide a repository!"
	exit 1
fi

echo "Enter your github username:"
read GITHUB_USER

if [ -z "$GITHUB_USER" ]; then 
	echo "You must provide a github username!"	
	exit 1
fi


echo "Setting up repo $REPO for github user $GITHUB_USER."

echo "Enter the email address for your github account:"
read EMAIL

if [ -z "$EMAIL" ]; then 
	echo "You must provide a github email!"
	exit 1
fi

echo "Enter the name associated with your github account:"
read NAME

if [ -z "$NAME" ]; then 
	echo "You must provide a github name!"
	exit 1
fi

echo "Values Supplied:"
echo "Repository: ${REPO}"
echo "Github User: ${GITHUB_USER}"
echo "Github Email: ${EMAIL}"
echo "Github Name: ${NAME}"

echo "Are these values correct? (Y|N)"

read correct

if [ `echo ${correct} | tr [:upper:] [:lower:]` != `echo "Y" | tr [:upper:] [:lower:]` ]; then
	echo "Please try again"
	exit 1
fi

# Clone your fork onto your local machine and cd into it...
echo "Cloning your fork from github into $REPO/"
git clone git@github.com:$GITHUB_USER/$REPO.git
cd $REPO

# Configure "remotes". Yours will be known as "fork", 
#     production (famigo/$REPO) will be "prod".
echo "Configuring remotes. Yours will be known as \"fork\", production as \"prod\"."
echo "Adding prod.."
git remote add prod git@github.com:famigo/$REPO.git
echo "Renaming origin remote to fork, to force you to decide which remote you are interacting with..."
git remote rename origin fork


# Set up helpful aliases
# NOTE These are "local" to this repository (ie, not set globally)
echo "Setting up some helpful aliases (st, co, pu, etc.)."
git config alias.st status 
git config alias.co checkout
git config alias.up "pull --rebase prod master"
git config alias.alias "config --get-regexp alias"
git config alias.pb '!bash -ic git_push_current_branch'
git config alias.db '!f() { git branch -d $1; git push fork :$1; }; f'
git config alias.cb "checkout -b"
git config alias.aa "add -A"
git config alias.cm "commit -m"
git config alias.ca "commit -a -m"
git config alias.m "co master"s
git config alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"

git config color.ui true

# Configure your identity
echo "Configuring your identity: $NAME $EMAIL."
git config user.email "$EMAIL"
git config user.name "$NAME"


touch ~/.bashrc
grep "source ~/.famigo_aliases" ~/.bashrc
ret=$?

if [ $ret -ne 0 ] ; then
  echo "Adding import statement to your bashrc"
  echo "source ~/.famigo_aliases" >> ~/.bashrc
fi

if [ -a ~/.famigo_aliases ] ; then
	echo "Found existing .famigo_aliases file. moving it to ~/.famigo_aliases.bak"
	mv ~/.famigo_aliases ~/.famigo_aliases.bak
fi
cat << 'EOF' > ~/.famigo_aliases

alias cgrep=grep --color=always
alias pygrep='cgrep -rn --include=*.py --exclude=*.pyc'
alias fgrep='cgrep -rn --include=*.py,*.html --exclude=*.pyc'


function git_push_current_branch() {
BRANCH=`git branch | grep \* | awk '{print $2}'`
git push fork $BRANCH
}
EOF

touch ~/.bash_profile
grep ". ~/.django_bash_completion" ~/.bash_profile
ret=$?

if [ $ret -ne 0 ] ; then
  echo "Adding django bash completion to your bash_profile"
  echo ". ~/.django_bash_completion" >> ~/.bash_profile
fi

if [ -a ~/.django_bash_completion ] ; then
	echo "Found existing .django_bash_completion file. moving it to ~/.django_bash_completion.bak"
	mv ~/.django_bash_completion ~/.django_bash_completion.bak
fi
cat << 'EOF' > ~/.django_bash_completion
_django_completion()
{
    COMPREPLY=( $( COMP_WORDS="${COMP_WORDS[*]}" \
                   COMP_CWORD=$COMP_CWORD \
	               DJANGO_AUTO_COMPLETE=1 $1 ) )
}
complete -F _django_completion -o default django-admin.py manage.py django-admin

_python_django_completion()
{
    if [[ ${COMP_CWORD} -ge 2 ]]; then
        PYTHON_EXE=${COMP_WORDS[0]##*/}
        echo $PYTHON_EXE | egrep "python([2-9]\.[0-9])?" >/dev/null 2>&1
        if [[ $? == 0 ]]; then
            PYTHON_SCRIPT=${COMP_WORDS[1]##*/}
            echo $PYTHON_SCRIPT | egrep "manage\.py|django-admin(\.py)?" >/dev/null 2>&1
            if [[ $? == 0 ]]; then
                COMPREPLY=( $( COMP_WORDS="${COMP_WORDS[*]:1}" \
                               COMP_CWORD=$(( COMP_CWORD-1 )) \
                               DJANGO_AUTO_COMPLETE=1 ${COMP_WORDS[*]} ) )
            fi
        fi
    fi
}

# Support for multiple interpreters.
unset pythons
if command -v whereis &>/dev/null; then
    python_interpreters=$(whereis python | cut -d " " -f 2-)
    for python in $python_interpreters; do
        pythons="${pythons} ${python##*/}"
    done
    pythons=$(echo $pythons | tr " " "\n" | sort -u | tr "\n" " ")
else
    pythons=python
fi

complete -F _python_django_completion -o default $pythons
EOF


