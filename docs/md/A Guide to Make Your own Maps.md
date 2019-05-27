# A Guide to Make Your own Maps [Draft]

To make a map for the game [Snake](https://zeqiang-lai.github.io/snake_assembly/), you have to follow the steps below in general.

1. **draw a black and white image(120*29) by any tool you like.**
   - Recommend PNG file (Other formats are not tested).
   - You can use this wonderful tool [Pixilart](https://www.pixilart.com).
2. **Use the provided tools to convert the image into a binary file that will read by the game at runtime.**
   - The python script for convertion can be download [here](). Require Numpy and Pillow.
   - Run the script with python3, e.g. `python3 convert.py map.png`
3. **[Optional] You can use our C++ tool to preview/test the map .**
   - [Tool Link]()
4. **Put the binary map file into map directory.**

> In progress