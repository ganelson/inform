# Grid window cursor row must be >= 1

While the Glk API specifies that coordinates in grid windows are 0-based (meaning the top left is (0, 0)), we use 1-based coordinates, so that the top left is (1, 1).