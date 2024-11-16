# Glk mouse event created with invalid coordinates

Glk mouse events must be created with valid coordinates. Note in particular that graphics windows are 0-based (meaning the top left is (0, 0)), while grid windows are 1-based (meaning the top left is (1, 1)).