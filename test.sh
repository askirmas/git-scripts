#!/bin/bash
reset=\\033[0m

HOOKS=$(cat hooks/hooks_dir)
./main.sh init $HOOKS

_it() {
  echo -e "\033[1;30;43m TEST \033[0m \033[1;4m$test$reset"
}
_commit() {
  msg="$test$1" 
  echo "$msg" >> file
  git add file && git commit -avm "$msg"
  return $?
}
_passed() {
  echo -e "\033[1;30;42m PASSED $reset $@"
}
_failed() {
  echo -e "\033[1;41m FAILED $reset $test: \033[1;4m$@$reset";
  exit 1;
}

MY_DIR=$(dirname "$(realpath "$0")")
REPO="repo"

rm -rf $REPO
mkdir $REPO
cd $REPO
mkdir $HOOKS
git init

touch file
git add file

test="first commit without hooks"
_it; _commit
[ "$?" == 0 ] && _passed || _failed

$MY_DIR/main.sh init $HOOKS
HOOKS_CONFIG=$(git config --get core.hooksPath | sed -e 's/^\([A-Z]\):/\/\1/' | tr '[:upper:]' '[:lower:]')
test="init"
_it
[ "$HOOKS_CONFIG" == $(echo "$MY_DIR/hooks" | tr '[:upper:]' '[:lower:]') ] \
||  _failed "$HOOKS_CONFIG != $MY_DIR/hooks"

cp -rf "$MY_DIR/tests/exit0.sh" "$HOOKS/pre-commit"
git add "$HOOKS/pre-commit"
git commit -nm "init pre-commit"

test="pre-commit exit0"
_it; _commit
[ $? == 0 ] && _passed || _failed

test="delete file"
rm -rf file
_it
git commit -avm "$test" && (test -e file; [ $? == 1 ]) 
[ $? == 0 ] && _passed || _failed

test=""
_commit "recover file"

cp -rf "$MY_DIR/tests/exit1.sh" "$HOOKS/pre-commit" || exit 1;
git commit -anm "bad pre-commit"

test="pre-commit exit1"
_it; _commit && _failed || _passed

test="stash pop after fail"
touch "tostash"
_it; _commit
test -e "tostash" && _passed || _failed

test="npm install"
echo "{}" > package.json
_it;
npm install "$MY_DIR" && _passed || _failed


# TODO: it commit interuption;

# TODO: check git log
echo -e "\n\033[1;30;42m DONE \033[0m"