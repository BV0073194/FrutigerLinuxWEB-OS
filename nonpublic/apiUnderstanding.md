// For App Development!!

Field	Values	Meaning
backend	web | exec | xpra | sunshine <- How the app runs
command	string	Command to run (Linux binary)
stream	object	Streaming options (ports, mode, etc)


Examples
Web-only app (current behavior)
{
  "backend": "web"
}

Native Linux app (Thunar)
{
  "backend": "xpra",
  "command": "thunar"
}

Terminal app
{
  "backend": "exec",
  "command": "bash"
}

Game
{
  "backend": "sunshine",
  "command": "retroarch"
}


✔ Nothing breaks
✔ Old apps still work
✔ New power unlocked