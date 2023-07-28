#!/usr/bin/env python

from __future__ import division
import git

repo = git.Repo(".")


def score(commit):
    size = commit.stats.total["lines"]
    if size == 0:
        return 0
    return len(commit.message) / size


commits = sorted(repo.iter_commits("master"), key=score, reverse=True)[:10]
print(commits)
