from PIL import Image

def encodePixel(pixel):
    return " "+"\00\00\00"+chr(pixel[0])+chr(pixel[1])+chr(pixel[2])

# Load the image
image_path = '../../misc/lenna.jpg'
image = Image.open(image_path)

# Convert the image to RGB (if not already in that mode)
image = image.convert('RGB')

# Get the dimensions of the image
width, height = image.size
print(width,height)

# Iterate through each line of pixels
with open("../../misc/lenna.img","w") as f:
    f.write(f"img;{width*2};{height};1\n")
    for y in range(height):
        for x in range(width):
            pixel = image.getpixel((x, y))
            # print(f'Pixel at ({x}, {y}): {pixel}')
            f.write(encodePixel(pixel))
            f.write(encodePixel(pixel))
    f.close()