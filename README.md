# WFC
Overlapping Wave Function Collapse algorithm implemented in Elixir.
One of the main goal is readability so codebase can be used for learning the algorithm.

[Paper to help understand the algorithm](https://adamsmith.as/papers/wfc_is_constraint_solving_in_the_wild.pdf)
[Wave Function Collapse repo](https://github.com/mxgmn/WaveFunctionCollapse)

## Try it out!

This will generate an example png for you in main dir.
```elixir
Wfc.example()
```

## How it works?

Let's say you have an input like the below one:
```elixir
  [
    [{255, 255, 255}, {255, 255, 255}, {255, 255, 255}, {255, 255, 255}],
    [{255, 255, 255}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}],
    [{255, 255, 255}, {0, 0, 0}, {255, 0, 0}, {0, 0, 0}],
    [{255, 255, 255}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}]
  ]
```

First you create NxN tiles from it. (optionally to make more tiles you rotate them around)
This happens in `Wfc.Input.tiles/2`.
```elixir
[
  [[{255, 255, 255}, {255, 255, 255}], [{255, 255, 255}, {0, 0, 0}]],
  [[{255, 255, 255}, {255, 255, 255}], [{0, 0, 0}, {0, 0, 0}]],
  [[{255, 255, 255}, {0, 0, 0}], [{255, 255, 255}, {0, 0, 0}]],
  [[{0, 0, 0}, {0, 0, 0}], [{0, 0, 0}, {255, 0, 0}]],
  ...
]
```

Now you need to determine which tiles can go next to each other in which directions.
This happens in `Wfc.Input.constraints/2`.
For example if you want to determine that `b_tile` can go above `a_tile`:
```elixir
  [a_tile_top_row | _] = a_tile = [[{255, 255, 255}, {255, 255, 255}], [{255, 255, 255}, {0, 0, 0}]],

  [_top_row | b_tile_bottom_row] = b_tile = [[{255, 255, 255}, {255, 255, 255}], [{255, 255, 255}, {0, 0, 0}]],

  can_b_tile_go_on_top_of_a_tile? = (a_tile_top_row == b_tile_bottom_row)
```

1. Now you create your output matrix and you set all elements to include all possible tiles. `Wfc.Output.new/2`
2. You set a random element to just 1 possible tile, and you propagate the changes to the neighbours. `Wfc.Output.collapse/1`
3. When the above propagation is ready, you select the element with lowest possibilities and you repeat step 2 until you have only elements with 1 possible tile. `Wfc.Output.lowest_possibilities_position/1`
4. You are done.
