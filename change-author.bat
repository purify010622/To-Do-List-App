@echo off
echo Changing all commit authors to Sarthak Yerpude...
echo.

git filter-branch -f --env-filter "
    export GIT_AUTHOR_NAME='Sarthak Yerpude'
    export GIT_AUTHOR_EMAIL='sarthakyerpude@example.com'
    export GIT_COMMITTER_NAME='Sarthak Yerpude'
    export GIT_COMMITTER_EMAIL='sarthakyerpude@example.com'
" --tag-name-filter cat -- --branches --tags

echo.
echo Done! Verifying changes...
git log --pretty=format:"%%an - %%ae" -5

echo.
echo.
echo Author changed successfully!
echo NOTE: This is LOCAL only. Nothing has been pushed to GitHub.
pause
