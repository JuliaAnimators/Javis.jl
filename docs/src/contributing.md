# Contributing to Javis

Javis is currently under heavy development as we push to a primary release version. As such, some parts of these instructions may become outdated faster than we can update them. If you encounter an error in these instructions, please open an issue and let us know. 

We follow a workflow pattern that is directly inspired by the [development workflow guide](http://docs.juliaplots.org/latest/contributing/#Development-Workflow-1) found in [`Plots.jl`](https://github.com/JuliaPlots/Plots.jl). The general workflow we expect contributors to adhere to is as follows:

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

      git branch [your github username]-documentation-[issue number]

      Example: tcp-documentation-22

## 3. Write code, test, and commit

Once you have a fork, it is useful to make sure the fork was successful.
To verify that everything is operational, let's test it.
The following procedure is as follows:

1. Go into the root of your fork:

`cd Javis`

2. Open your Julia REPL and type the following within the repo:

```
julia> ]
(@v###) pkg> dev .
(@v###) pkg> test Javis
```

This might take a little bit, but if the installation on your computer is successful, it should say all tests passed.

> **NOTE:** You may need to remove the current version of `Javis` you have installed in your Julia environment in order to develop. 

After making the changes you wanted to make, run the tests again to make sure you did not introduce any breaking changes.
If everything passed, we can continue on to the next step.
If not, it is the responsibility of the contributor to resolve any conflicts or failing tests.
Don't worry!
We're happy to help you resolve errors. 😄
If you are stuck, go ahead and continue with this tutorial.

Now that you are done, let's push these changes to GitHub!
The way we do this is in three steps:

1. Add the files you have added or changed via `git add` 

2. After adding the files, we need to say what you did to the files (i.e. commit the files). This can be accomplished thusly: `git commit -m "your message"` 

3. Finally, let's push these changes to GitHub using `git push --set-upstream origin [name of the branch you made]`

An example would be this: Say if I make a branch called `tcp-documentation-22` after a discussion about changing documentation in issue 22. 
From that file, I changed `README.md` to add about how cool I think penguins are.
I would do the following:

```
git add README.md
git commit -m "Added discussion about penguins"
git push --set-upstream origin tcp-documentation-22
```

If I have already pushed in the past and set the upstream to origin, then I could do `git push` instead of `git push --set-upstream origin tcp-documentation-22`.

## 4. Submitting your changes to the main project

Almost done! Go to your fork and there should be a section that asks you to make a pull request (PR) from your branch. This allows the maintainers of Javis to see if they can add your changes to the main project. If not, you can click the "New pull request" button.

Make sure the "base" branch is Javis `master` and the "compare" branch is the branch you just made. 
To your PR, add an informative title and description, and link your PR to relevant issues or discussions. 
Finally, click "Create pull request". 

You may get some questions about it, and possibly suggestions of how to make it ready to go into the main project. 
If you had test errors or problems, we are happy to help you. 
Then, if all goes according to plan, it gets merged... **Thanks for the contribution!!** :tada: :tada: :tada:
