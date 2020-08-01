# Contributing to Javis

Javis is currently under heavy development as we push to a primary release version. As such, some parts of these instructions may become outdated faster than we can update them. If you encounter an error in these instructions, please open an issue and let us know. 

We follow a workflow pattern that is directly inspired by the [development workflow guide](http://docs.juliaplots.org/latest/contributing/#Development-Workflow-1) found in [`Plots.jl`](https://github.com/JuliaPlots/Plots.jl). The general workflow we expect contributors to follow is as follows:

## 1. Fork the repo to your account

## 2. Create a branch based on what you are developing

Before making a branch, make sure to check that you are even with master via the following commands:

```
git fetch origin
git checkout master
git merge --ff-only origin/master
```

> The `--ff-only` flag will "fast forward" to newer commits. It will not create new merge commits.

After your master branch is up to date, we follow the following naming conventions for branches:

- For issue fixes, name it like so:

      git branch [your github username]-issue-[issue number]

      Example: tcp-issue-6

- For features, name it like so:

      git branch [your github username]-feature-[issue number]

      Example: tcp-feature-4

- For documentation, name it like so:

      git branch [your github username]-documentation

      Example: tcp-documentation

## 3. Write code and commit

After making the changes you wanted to make, now let's push these changes to GitHub. The way we do this is in three steps:

1. Add the files you have added or changed via `git add` 

2. After adding the files, we need to say what you did to the files (i.e. commit the files). This can be accomplished thusly: `git commit -m "your message"` 

3. Finally, let's push these changes to GitHub using `git push --set-upstream origin [name of the branch you made]`

An example would be this: Say if I make a branch called `thecedarprince-documentation` and changed `README.md`. In that file, all I added was how cool I think penguins are. I would do the following:

```
git add README.md
git commit -m "Added discussion about penguins"
git push --set-upstream origin thecedarprince-documentation
```

If I have already pushed in the past and set the upstream to origin, then I could do `git push` instead of `git push --set-upstream origin thecedarprince-documentation`.

## 4. Submitting your changes to the main project

Almost done! Go to your fork and there should be a section that asks you to make a pull request (PR) from your branch. This allows the maintainers of Javis to see if they can add your changes to the main project. If not, you can click the "New pull request" button.

Make sure the "base" branch is Javis `master` and the "compare" branch is the branch you just made. To your PR, add an informative title and description, and link your PR to relevant issues or discussions. Finally, click "Create pull request". 

You may get some questions about it, and possibly suggestions of how to make it ready to go into the main project. Then, if all goes according to plan, it gets merged... **Thanks for the contribution!!** :tada: :tada: :tada:
