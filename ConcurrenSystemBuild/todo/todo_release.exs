defmodule Todo.MixProject do
  
  def cli do
    [
      preferred_envs: [release: :prod]
    ]
  end
end
