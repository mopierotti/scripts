@for %%a in (%*) do git grep -n "[^a-zA-Z0-9_]*%%a[^a-zA-Z0-9_]"