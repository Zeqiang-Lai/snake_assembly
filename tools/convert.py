from PIL import Image
import numpy as np
import os
import sys

def load_image( infilename ) :
    img = Image.open( infilename ).convert('LA')
    img.load()
    data = np.asarray( img, dtype="int32" )
    return data

if __name__ == "__main__":
    if len(sys.argv) == 1:
        print("usage: python3 convert.py [file_path]")
    else:
        image_path = sys.argv[1]
        data = load_image(image_path)
        bit_map = data[0:29,0:120,0]
        print("The image height is {0}, width is {1}.".format(bit_map.shape[0], bit_map.shape[1]))
        print("Region that is out of (120,29) will be cropped.")
        bit_map = bit_map.flatten()
        bit_map = [1 if i > 0 else 0 for i in bit_map];

        print("Start converting...")
        file_name = os.path.basename(image_path)
        file_name = os.path.splitext(file_name)[0]

        num = 1
        while os.path.exists(file_name):
            file_name += str(num)
        f = open(file_name, "wb")
        f.write((''.join(chr(i) for i in bit_map)).encode('charmap'))
        print("Success!")
        print("The binary file is stored at: {0}".format(file_name))
        
