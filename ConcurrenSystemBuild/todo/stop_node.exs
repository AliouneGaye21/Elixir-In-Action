if Node.connect(:todo_system@localhost) == true do
  :rpc.call(:todo_system@localhost, System, :stop, [])
  IO.puts("Node terminated.")
else
  IO.puts("Can't connect to a remote node.")
end
