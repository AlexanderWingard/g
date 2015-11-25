#!/usr/bin/env python

from shpy import *
from itertools import product


def do_st():
    c("git fetch")
    upstream = "".join(c("git rev-parse --abbrev-ref --symbolic-full-name '@{{u}}'", exit=True))
    #branches = ["master", "a", "b", "c"]
    branches = ["HEAD", upstream]
    branchstring = " ".join(branches)
    commits = c("git rev-parse {}", branchstring)
    boundaries = []
    contexts = [c("git rev-list --first-parent --max-count 3 {}", commit) for commit in commits]
    allcontexts = sum(map(lambda x: x[:-1], contexts), [])

    for context in contexts:
        bound = context[-1]
        if not bound in allcontexts:
            boundaries.append(bound)
    p(c("git --no-pager log --color --graph --boundary --format=format:\"%C(red)%h%C(reset) %C(yellow)%ad%C(reset) %s %C(green)[%an]%C(auto)%d%C(reset)\" --abbrev-commit --date=relative {} {}", " ".join(commits), " ".join(map(lambda x: "^" + x, boundaries)), q=True))
    p(c("git stash list --format=format:\"S %C(red)%gd%C(reset) %C(yellow)%cr%C(reset) %s \""))
    ignored = []
    untracked = []
    statused = []
    for line in c("git -c color.ui=always status -sbuall --ignored"):
        if line.startswith("[31m!!"):
            ignored.append(line)
        elif line.startswith("[31m??"):
            untracked.append(line)
        else:
            statused.append(line)

    if len(ignored) > 10:
        p("X: {}", len(ignored))
    else:
        p(ignored)

    if len(untracked) > 10:
        p("U: {}", len(untracked))
    else:
        p(untracked)

    p(reversed(statused))

def do_branch():
    do_st()
    p(c("git -c color.ui=always  branch -vvv"))

def do_stash():
    ignored = 0
    untracked = 0
    modified = 0
    indexed = 0
    for line in c("git -c color.ui=always status -sbuall --ignored"):
        if line.startswith("[32m"):
            indexed += 1
        elif line.startswith("[31m!!"):
            ignored += 1
        elif line.startswith("[31m??"):
            untracked += 1
        elif line.startswith(" [31m"):
            modified +=1

    c("git stash save --all \"A: {} M: {} U: {} I: {}\"", indexed, modified, untracked, ignored)
    do_st()

def do_pop():
    c("git stash pop --index")
    do_st()


subparsers = parser.add_subparsers(help="commands")
status_parser = subparsers.add_parser('s', help='status');
status_parser.set_defaults(func=do_st);

branch_parser = subparsers.add_parser('b', help='branch');
branch_parser.set_defaults(func=do_branch);


stash_parser = subparsers.add_parser('stash', help='stash');
stash_parser.set_defaults(func=do_stash);

pop_parser = subparsers.add_parser('pop', help='stash pop');
pop_parser.set_defaults(func=do_pop);


if (len(sys.argv) < 2):
    sys.argv.append("s")

if (sys.argv[1] not in ["s", "b", "stash", "pop"]):
    c("git {}", " ".join(sys.argv[1:]))
    do_st()
else:
    a = init()
    a.func()

