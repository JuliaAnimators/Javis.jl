---
name: Bug report
about: Create a report to help us improve
title: "[BUG] "
labels: bug
assignees: ''

---

**Before Filing a Report**

- Did I read the Documentation and/or docstrings?
- Did I search the Javis GitHub to see if this bug has already been reported?
- Am I familiar with the Javis philosophy?
- Do I have the latest version of Javis installed? 

**Describe the bug**

A clear and concise description of what the bug is.

**To Reproduce**

1. Julia Version (i.e. output of `julia -v`):

2. Operating system (Mac, Linux, Windows):

3. Javis version (i.e output of `] status Javis` in the REPL)

4. Minimum working code example that led to bug:

**Expected Behavior and Actual Behavior**

A clear and concise description of what you expected to happen followed up with an explanation of what actually happened.

**Stacktrace (If Applicable)**
If the stacktrace includes some ffmpeg error please set the kwarg `ffmpeg_loglevel` to `"info"` i.e `render(your_video, "your_animation.gif", ffmpeg_loglevel = "info")`

**Screenshots**
If applicable, add your gif or drawing to help explain your problem.

**Additional context**
Add any other context about the problem here.
