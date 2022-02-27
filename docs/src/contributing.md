# Contributing to Javis

Javis is currently under heavy development as we push to a primary release version. As such, some parts of these instructions may become outdated faster than we can update them. If you encounter an error in these instructions, please open an issue and let us know. 

We follow a workflow pattern that is directly inspired by the [development workflow guide](http://docs.juliaplots.org/latest/contributing/#Development-Workflow-1) found in [`Plots.jl`](https://github.com/JuliaPlots/Plots.jl). The general workflow we expect contributors to adhere to is as follows:

## 1. Create an Issue about the Problem

If you want to add functionality or to work on a bug you found, open an issue first.
That'll save you from doing work that we may not support for Javis.

## 2. Fork the repo to your account

## 3. Create a branch based on what you are developing

Before making a branch, make sure to check that you are even with main via the following commands:

```
git fetch origin
git checkout main
git merge --ff-only origin/main
```

> The `--ff-only` flag will "fast forward" to newer commits. It will not create new merge commits.

After your main branch is up to date, we follow the following naming conventions for branches:

- For issue fixes, name it like so:

      git branch [your github username]-issue-[issue number]

      Example: tcp-issue-6

- For features, name it like so:

      git branch [your github username]-feature-[name of feature]

      Example: tcp-feature-scaling

- For documentation, name it like so:

      git branch [your github username]-documentation-[where improvement is made]

      Example: tcp-documentation-contributing-guidelines

## 4. Test, code, format, and commit

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

This might take some time, but if the installation on your computer is successful, it should say all tests passed.

> **NOTE:** You may need to remove the current version of `Javis` you have installed in your Julia environment in order to develop. 

After making the changes you wanted to make, run the tests again to make sure you did not introduce any breaking changes.
If everything passed, we can continue on to the next step.
If not, it is the responsibility of the contributor to resolve any conflicts or failing tests.
Don't worry!
We're happy to help you resolve errors. 😄
If you are stuck, go ahead and continue with this tutorial.

Once you are done with your changes, you will need to install `JuliaFormatter.jl` to format your code before we make a PR.
To do this, install `JuliaFormatter.jl` into your personal Julia installation by running:

```julia
julia> ]
(@v###) pkg> add JuliaFormatter
```

> **NOTE:** Make sure that `(@v###) pkg>` does not say `(Javis) pkg>` or else you will accidentally install `JuliaFormatter.jl` into `Javis.jl`! To get out of the `(Javis) pkg>` environment, type into your REPL, `julia> ] activate` and that should put you back into your own environment.

Great!
Now that you have `JuliaFormatter.jl` installed, run the following in your REPL:

```julia
julia> using JuliaFormatter
julia> format(".")
```

> **NOTE:** Make sure when you run format, you are at the top of the `Javis` directory so that every file gets properly formatted.

Now that formatting is done, let's push your changes to GitHub!
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

## 5. Submitting your changes to the main project

Almost done! Go to your fork and there should be a section that asks you to make a pull request (PR) from your branch. This allows the maintainers of Javis to see if they can add your changes to the main project. If not, you can click the "New pull request" button.

Make sure the "base" branch is Javis `main` and the "compare" branch is the branch you just made. 
To your PR, add an informative title and description, and link your PR to relevant issues or discussions. 
Finally, click "Create pull request". 

You may get some questions about it, and possibly suggestions of how to make it ready to go into the main project. 
If you had test errors or problems, we are happy to help you. 
Then, if all goes according to plan, it gets merged... **Thanks for the contribution!!** 🎉 🎉 🎉

## Note on Adding Dependencies

As a rule, we try to avoid having too many dependencies.
Therefore, we request that if you have a PR that adds a new dependency, please have opened an issue previously.

### Adding Core Dependencies

If you are working on introducing a new core dependency, make sure to add that dependency to the main `Project.toml` for `Javis`.
To do this, follow these steps:

1. Enter the root of the `Javis` directory 

```
cd /path/to/Javis.jl
```

2. Activate the `Javis` environment and add the dependency:

```julia
julia> ]
(@v###) pkg> activate .
(Javis) pkg> add [NAME OF DEPENDENCY]
```

### Adding Test Dependencies

If you are  introducing a new test dependency, make sure to add that dependency to the `Project.toml` located in the `Javis` test directory.
To do this, follow these steps:

1. Enter the test directory inside of the `Javis` directory 

```
cd /path/to/Javis.jl/test/
```

2. Activate the `Javis` environment and add the dependency:

```julia
julia> ]
(@v###) pkg> activate .
(test) pkg> add [NAME OF DEPENDENCY]
```
