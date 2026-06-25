# VHS tape for harness-kit's demo GIF. Render: bash docs/demo/build-demo.sh
Output demo.gif

Set Shell bash
Set FontSize 18
Set Width 1180
Set Height 640
Set Padding 20
Set Theme "Dracula"
Set TypingSpeed 35ms

Hide
Type "clear" Enter
Show

Sleep 400ms
Type "# harness-kit: point it at any repo, get a tailored harness"
Enter
Sleep 700ms

Type "ls acme-shop/" Enter
Sleep 900ms

Type "harness-kit introspect acme-shop/" Enter
Sleep 1800ms

Type "cat acme-shop/.claude/harness-kit.json" Enter
Sleep 1800ms

Type "cat acme-shop/CLAUDE.md" Enter
Sleep 3000ms
