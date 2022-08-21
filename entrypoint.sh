#!/bin/sh -l

set -e

[ -z "${INPUT_GITHUB_TOKEN}" ] && {
    echo 'Missing input "github_token: ${{ secrets.GITHUB_TOKEN }}".';
    exit 1;
};

docs_src=$GITHUB_WORKSPACE/docs
docs_html=$GITHUB_WORKSPACE/gh-pages
sphinx_doctree=$GITHUB_WORKSPACE/.doctree

echo ::group::Create working directories
echo "mkdir $docs_src"
mkdir $docs_src
echo "mkdir $docs_html"
mkdir $docs_html
echo "mkdir $sphinx_doctree"
mkdir $sphinx_doctree
echo ::endgroup::

# sphinx extensions
# sphinx extensions pip lib install is finished in the docker file command, 
# move forward to avoid that requirements.txt is overwrite by the git init.
if [ "$INPUT_INSTALL_EXTENSIONS" = true  ] ; then
    echo ::group::Installing sphinx extensions
    echo "pip3 install -r $docs_src/requirements.txt"
    echo "ls -l /github/workspace/docs"
    ls -l /github/workspace/docs
    echo "pwd"
    pwd
    echo "ls -l"
    ls -l   
    # pip3 install -r requirements.txt
    echo ::endgroup::
fi

# checkout branch docs
echo ::group::Initializing the repository
echo "cd $docs_src"
cd $docs_src
echo "git init"
git init
echo "git remote add origin https://github.com/$GITHUB_REPOSITORY.git"
git remote add origin https://$GITHUB_ACTOR:$INPUT_GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY.git
echo ::endgroup::
echo ::group::Fetching the repository
echo "git fetch origin +$GITHUB_SHA:refs/remotes/origin/docs"
git fetch origin +$GITHUB_SHA:refs/remotes/origin/docs
echo ::endgroup::
echo ::group::Checkout ref
echo "git checkout -B docs refs/remotes/origin/docs"
git checkout -B docs refs/remotes/origin/docs
echo ::endgroup::
echo ::group::Show HEAD message
git log -1
echo ::endgroup::

# get author
author_name="$(git show --format=%an -s)"
author_email="$(git show --format=%ae -s)"
docs_sha8="$(echo ${GITHUB_SHA} | cut -c 1-8)"

# outputs
echo "::set-output name=name::"$author_name""
echo "::set-output name=email::"$author_email""
echo "::set-output name=docs_sha::$(echo ${GITHUB_SHA})"
echo "::set-output name=docs_sha8::"$docs_sha8""

# checkout branch gh-pages
echo ::group::Initializing branch gh-pages
echo "cd $docs_html"
cd $docs_html
echo "git init"
git init
#git remote add origin https:<access__token>://@github.com/<username>/<repo__name>.git
#git push https://<access__token>@github.com/<username>/<repo__name>.git
echo "GITHUB_ACTOR : $GITHUB_ACTOR"
echo "INPUT_GITHUB_TOKEN : $INPUT_GITHUB_TOKEN"
echo "GITHUB_REPOSITORY : $GITHUB_REPOSITORY"

echo "git remote add origin https://$GITHUB_ACTOR:$INPUT_GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY.git"
git remote add origin https://$GITHUB_ACTOR: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@github.com/$GITHUB_REPOSITORY.git
echo ::endgroup::

# check remote branch exist first
echo ::group::Check remote branch gh-pages exist
echo "git ls-remote --heads origin refs/heads/gh-pages"
gh_pages_exist=$(git ls-remote --heads origin refs/heads/gh-pages)
if [ -z "$gh_pages_exist" ]
then
    echo "Not exist."
else
    echo "Exist"
fi
echo ::endgroup::

if [ -z "$gh_pages_exist" ]
then
    echo ::group::Create branch gh-pages
    echo "git checkout -B gh-pages"
    git checkout -B gh-pages
    echo ::endgroup::
else
    echo ::group::Fetching branch gh-pages
    echo "git fetch origin +refs/heads/gh-pages:refs/remotes/origin/gh-pages"
    git fetch origin +refs/heads/gh-pages:refs/remotes/origin/gh-pages
    echo "git checkout -B gh-pages refs/remotes/origin/gh-pages"
    git checkout -B gh-pages refs/remotes/origin/gh-pages
    echo "git log -1"
    git log -1
    echo ::endgroup::
fi

# git config Set commiter
echo ::group::Set commiter
echo "git config --global user.name 'sky-dream' "
git config --global user.name "sky-dream"
echo "git config --global user.email 'xxm1263476788@126.com' "
git config --global user.email "xxm1263476788@126.com"

# https://stackoverflow.com/questions/18935539/authenticate-with-github-using-a-token
# curl -H 'Authorization: token <MYTOKEN>' https://github.com/sky-dream/sphinx-pages.git
# git remote set-url origin https://sky-dream:<MYTOKEN>@github.com/sky-dream/sphinx-pages.git
echo ::endgroup::


# sphinx-build
echo ::group::Sphinx build html
echo "pwd"
pwd
echo "ls -l"
ls -l 
echo "ls -l $docs_src/$INPUT_SOURCE_DIR"
ls -l $docs_src/$INPUT_SOURCE_DIR
echo "sphinx-build -b html $docs_src/$INPUT_SOURCE_DIR $docs_html -E -d $sphinx_doctree"
sphinx-build -b html $docs_src/$INPUT_SOURCE_DIR $docs_html -E -d $sphinx_doctree
echo ::endgroup::

# auto creation of README.md
if [ "$INPUT_CREATE_README" = true ] ; then
    echo ::group::Create README
    echo "Create file README.md with these content"
    echo "GitHub Pages of [$GITHUB_REPOSITORY](https://github.com/$GITHUB_REPOSITORY.git)" > README.md
    echo "===" >> README.md
    echo "Sphinx html documentation of [$docs_sha8](https://github.com/$GITHUB_REPOSITORY/tree/$GITHUB_SHA)" >> README.md
    cat README.md
    echo ::endgroup::
fi

# commit and push
echo ::group::Push
echo "git add ."
git add .
echo 'git commit --allow-empty -m "From $GITHUB_REF $docs_sha8"'
git commit --allow-empty -m "From $GITHUB_REF $docs_sha8"
echo "git show-ref"
git show-ref
echo "git push -fq origin gh-pages"
git push -fq origin gh-pages 
echo ::endgroup::
