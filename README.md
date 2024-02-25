# right click summarize

i've found myself copy pasting a lot of text into ChatGPT just to summarize it.
this script aims to make that easier by birning the summary to your right click context menu.

<img width="830" alt="image" src="https://github.com/ericzakariasson/right-click-summarize/assets/25622412/52902973-5171-41c6-9e22-e522832454fb">

<img width="830" alt="image" src="https://github.com/ericzakariasson/right-click-summarize/assets/25622412/28122a26-4f0f-4f08-86f2-771a8deea2c6">


## how

- it's built on top of automator scripts in macOS. this is due to security and sandbox limitations (for a good reason)
- open ai is used to summarize. the api key will be stored in your local keychain
- when selecting text, right click and you'll find `Services` → `Summarize`

## installation

1. open the repository with finder and double click the "Summarize.workflow". this will prompt if you want to install the script. i've added the script as reference
2. select any text and click `Services` → `Summarize`. if it's the first time using it, you'll have to provide an api key. it will be stored in keychain

## debug

there's a log at `/tmp/right_click_summarize_script.log` you can access

## making changes

if you want to update the script, make sure to also update the `document.wflow` in `/Summarize.workflow/Contents/`.
could be neat to build a little script to inline the script there on build.
